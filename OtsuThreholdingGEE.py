#Tom Wilson January 2019
import ee
ee.Initialize()

#Location to test
location = 'Kielder'

#Import extent and woodland extent assets
extent= ee.FeatureCollection("users/tomw_ee/Kielder/Kielder_extent")
woodland = ee.FeatureCollection("users/tomw_ee/Kielder/Woodland_AreaClipKielder")

#Get S1 image collection
s1c = ee.ImageCollection('COPERNICUS/S1_GRD').filterBounds(extent).filterDate('2018-09-01', '2018-09-30')

#Optional: Filter descending / ascending orbit
s1c= s1c.filter(ee.Filter.eq('orbitProperties_pass', 'DESCENDING'))

#Make median composite image of VH or VV polarisation
img = s1c.median().select('VH')

#Convert woodland area to raster and then mask S1 image outside woodland
woodland = woodland.map(lambda f : f.set('all', 1))
rasterWoodland = woodland.reduceToImage(properties=['all'], reducer=ee.Reducer.first())
img = img.updateMask(rasterWoodland)

#Export masked S1 image for much faster processing of subsequent steps

def export_images(img, output_file_name):
    task=ee.batch.Export.image.toAsset(
            image=img,
            assetId = "users/tomw_ee/{0}/".format(location)+output_file_name,
            description = output_file_name,
            region = extent.geometry().bounds().getInfo()['coordinates'],
            scale= 10)
    task.start()

export_images(img, 'vhKielderDesc')


#Import exported image

s1img= ee.Image("users/tomw_ee/Kielder/vhKielderDesc")

#All steps converted to Python from JS example at https://medium.com/google-earth/otsus-method-for-image-segmentation-f5c48f405e

# Compute the histogram of the VH band.
histogram = s1img.select('VH').reduceRegion(reducer= ee.Reducer.histogram(255, 2),geometry=extent, scale=10, bestEffort =True)
print(histogram.getInfo())

def otsu(histogram):
    counts =ee.Array(ee.Dictionary(histogram).get('histogram'))
    means = ee.Array(ee.Dictionary(histogram).get('bucketMeans'))
    size= means.length().get([0])
    total = counts.reduce(ee.Reducer.sum(), [0]).get([0])
    sum = means.multiply(counts).reduce(ee.Reducer.sum(), [0]).get([0])
    mean = sum.divide(total)
    indices = ee.List.sequence(1, size)
    def indicesFun(i):
        aCounts = counts.slice(0, 0, i)
        aCount = aCounts.reduce(ee.Reducer.sum(), [0]).get([0])
        aMeans = means.slice(0, 0, i)
        aMean = aMeans.multiply(aCounts).reduce(ee.Reducer.sum(), [0]).get([0]).divide(aCount)
        bCount = total.subtract(aCount)
        bMean = sum.subtract(aCount.multiply(aMean)).divide(bCount)
        return aCount.multiply(aMean.subtract(mean).pow(2)).add(bCount.multiply(bMean.subtract(mean).pow(2)))
    bss = indices.map(indicesFun)
    return means.sort(bss).get([-1])


threshold = otsu(histogram.get('VH'))
print(threshold.getInfo())


#Create 0/1 classified image based on below threshold being 1
resultImg = s1img.select('VH').lt(threshold).reduce('sum').rename('classification')
#Optional majority filter
resultImg = resultImg.focal_mode(radius= 1.5, kernelType= 'square', units= 'pixels', iterations= 4)

#Optional - export the thresholded image as an asset
export_images(resultImg, 'otsuVH')


def generateResults(v):
    global resultImg
    testingSet = ee.FeatureCollection("users/tomw_ee/{0}/TrainingTesting/testingSet{0}_{1}".format(location,v))
    validate = resultImg.sampleRegions(testingSet, ['TYPE_CODE'], 10)
    confusionMatrix = ee.ConfusionMatrix(validate.errorMatrix('TYPE_CODE', 'classification'))

    overallAccuracy = confusionMatrix.accuracy()
    producersAccuracy=  confusionMatrix.producersAccuracy()
    consumersAccuracy= confusionMatrix.consumersAccuracy()

    results= ee.FeatureCollection([ee.Feature(None, {'metric': 'cf', 'result': confusionMatrix.array()}),    ee.Feature(None, {'metric': 'overall accuracy', 'result': confusionMatrix.accuracy()}),    ee.Feature(None, {'metric': 'producers accuracy', 'result': confusionMatrix.producersAccuracy()}),    ee.Feature(None, {'metric': 'consumers accuracy', 'result': confusionMatrix.consumersAccuracy()}),    ee.Feature(None, {'metric': 'kappa', 'result': confusionMatrix.kappa()})])

    return results.map(lambda f : f.set('RUN_NUMBER', v))

NUMBER_OF_TESTS = 10

res = ee.FeatureCollection(ee.Feature(None,{}))
for i in range(NUMBER_OF_TESTS,0,-1):
    res = generateResults(i).merge(res)

res = res.sort('metric')


def export_results(output_file_name):
    task=ee.batch.Export.table.toDrive(
            collection=res,
            folder = location,
            fileFormat='CSV',
            fileNamePrefix=output_file_name,
            selectors=['RUN_NUMBER','metric','result'])
    task.start()

export_results('otsuTestVH2')

