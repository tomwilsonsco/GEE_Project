#Tom Wilson January 2019
## Sentinel 2 Cloud Analysis Using Google Earth Engine

#cloud score methods adpated for Python by me from Javascript by Ian Housman:
#https://groups.google.com/forum/#!msg/google-earth-engine-developers/i63DS-Dg8Sg/FGuT5OtSAQAJ;context-place=msg/google-earth-engine-developers/jYFuopAlIi0/tf2AKG4_BAAJ
 
import ee
ee.Initialize()

#Long / lat of point of interest
#geometry = ee.Geometry.Point([-3.1442192637382504, 55.661132026121])
geometry = ee.FeatureCollection('users/tomw_ee/glentress')

#Time frame over which to run analysis
start = '2016-11-01'
end = '2018-11-01'

#S2 cloud score parameters
cloudThresh =20 #lower value more cloud filtered
dilatePixels = 2 #Pixels to dilate around clouds
contractPixels = 1 #Pixels to reduce cloud mask and dark shadows by to reduce inclusion of single-pixel comission errors


#Bands are divided by 10000 and renamed for cloud score
def s2_bands(img):
    t = img.select([ 'B1','B2','B3','B4','B5','B6','B7','B8','B8A', 'B9','B10', 'B11','B12']).divide(10000)
    t = t.addBands(img.select(['QA60']))
    out = t.copyProperties(img).copyProperties(img,['system:time_start'])
    return out


#Rescale function for cloud score
def rescale(img, exp, thresholds):
    return img.expression(exp,{'img':img}).subtract(thresholds[0]).divide(thresholds[1] - thresholds[0])

#Masking function for S2 cloud using cloud score 
def sentinelCloudScore(img):
    # Compute several indicators of cloudyness and take the minimum of them.
    score = ee.Image(1)
    blueCirrusScore = ee.Image(0)
    #Clouds are reasonably bright in the blue or cirrus bands.
    #Use .max as a pseudo OR conditional
    blueCirrusScore = blueCirrusScore.max(rescale(img, 'img.blue', [0.1, 0.5]))
    blueCirrusScore = blueCirrusScore.max(rescale(img, 'img.cb', [0.1, 0.5]))
    blueCirrusScore = blueCirrusScore.max(rescale(img, 'img.cirrus', [0.1, 0.3]))
    score = score.min(blueCirrusScore);
    #Clouds are reasonably bright in all visible bands.
    score = score.min(rescale(img, 'img.red + img.green + img.blue', [0.2, 0.8]))
    # Clouds are reasonably bright in all infrared bands.
    score = score.min(rescale(img, 'img.nir + img.swir1 + img.swir2', [0.3, 0.8]))
    # However, clouds are not snow
    ndsi =  img.normalizedDifference(['green', 'swir1'])
    score=score.min(rescale(ndsi, 'img', [0.8, 0.6]))
    score = score.multiply(100).byte()
    score = score.focal_min(contractPixels).focal_max(dilatePixels)
    return img.addBands(score.rename('cloudScore'))

#Function to remove clouds from S2 image using cloud score
def scoreOutputClouds(img):
    scoreImg = sentinelCloudScore(img)
    imgQA = img.select('QA60').int16().remap([0,1024,2048],[0,100,100]).rename('QACloud')
    thresholds = ee.Image([cloudThresh])
    scoreImg = scoreImg.select('cloudScore').gt(thresholds).reduce('sum').rename('cloudScoreOut')
    scoreImg = scoreImg.multiply(100)
    return scoreImg.addBands(imgQA).copyProperties(img,['system:time_start', 'CLOUDY_PIXEL_PERCENTAGE'])
    

#Get S2 collection
s2c = ee.ImageCollection('COPERNICUS/S2').filterDate(start, end).filterBounds(geometry).map(s2_bands).select(['QA60', 'B1','B2','B3','B4','B5','B6','B7','B8','B8A', 'B9','B10', 'B11','B12'],['QA60','cb', 'blue', 'green', 'red', 're1','re2','re3','nir', 'nir2', 'waterVapor', 'cirrus','swir1', 'swir2']).map(scoreOutputClouds)

#s2c.first().date().getInfo()

#Reducer to get cloud values at point of interest
def getCloudFeatures(img):
    return img.reduceRegions(geometry,ee.Reducer.mean(), 10)    .map(lambda f: f.set('date',img.date().format('dd-MM-yyyy')))    .map(lambda f: f.set('cloudPercent',img.get('CLOUDY_PIXEL_PERCENTAGE')))
	
fc = s2c.map(getCloudFeatures).flatten()
#fc.first().getInfo()


def export_results(coll, output_file_name):
    task=ee.batch.Export.table.toDrive(
            collection=coll,
            folder = 'exportedEEResults',
            fileFormat='CSV',
            fileNamePrefix=output_file_name,
            selectors=outputCols)
    task.start()


#Export results
outputCols = ['date','QACloud','cloudScoreOut','cloudPercent']
export_results(fc, 's2CloudAnalysis')

