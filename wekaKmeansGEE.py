#Tom Wilson January 2019

#Creates K-means classifier
import ee
ee.Initialize()

#Location to test
location = 'Kielder'

#Get extent polygon
extent= ee.FeatureCollection("users/tomw_ee/{0}/{0}_extent".format(location))
#Get S1 image collection
s1c = ee.ImageCollection('COPERNICUS/S1_GRD').filterBounds(extent).filterDate('2018-09-01', '2018-09-30')

#Make asc/ desc image bands
img = s1c.filter(ee.Filter.eq('orbitProperties_pass', 'DESCENDING')).median().select(['VV','VH'],['VVdesc','VHdesc'])
asc = s1c.filter(ee.Filter.eq('orbitProperties_pass', 'ASCENDING')).median().select(['VV','VH'],['VVasc','VHasc'])

img = img.addBands(img.select('VVdesc').subtract(img.select('VHdesc')).rename('Ratiodesc'))
asc = asc.addBands(asc.select('VVasc').subtract(asc.select('VHasc')).rename('Ratioasc'))

img = img.addBands(asc)
img= img.select(['Ratioasc','Ratiodesc','VHasc','VHdesc','VVasc','VVdesc'])

#Get FC to sample
fc= ee.FeatureCollection("users/tomw_ee/Kielder/TrainingTesting/trainingSetKielder_1")
fc = fc.randomColumn('random')
fc =fc.limit(5000,'random')

#Use a fc reducer to sample image bands, remove geometry to make faster
training = img.reduceRegions(fc, ee.Reducer.first(), 10)
training = training.select(['Ratioasc','Ratiodesc','VHasc','VHdesc','VVasc','VVdesc'])
training = training.map(lambda f: f.setGeometry(None))
training.first().getInfo()

#Create the k-means model
model = ee.Clusterer.wekaKMeans(2).train(training,['Ratioasc','Ratiodesc','VHasc','VHdesc','VVasc','VVdesc'])
# Create an image classified by the model
cImg = img.cluster(model)

def export_images(img, output_file_name):
    task=ee.batch.Export.image.toAsset(
            image=img,
            assetId = "users/tomw_ee/Kielder/"+output_file_name,
            description = output_file_name,
            region = extent.geometry().bounds().getInfo()['coordinates'],
            scale= 10)
    task.start()


#Export the classified image as an Asset to GEE
export_images(cImg, 'KielderKMeans')


####################################################
#Part two testing the classified image
####################################################

#Read the image from GEE Asset folder
kImg= ee.Image("users/tomw_ee/Kielder/KielderKMeans")


#Optional apply majority filter
kImg= kImg.focal_mode(radius= 2.0, kernelType= 'square', units= 'pixels', iterations= 2)

#Rename cluster band to classification
kImg= kImg.rename('classification')

def generateResults(v):
    global resultImg
    testingSet = ee.FeatureCollection("users/tomw_ee/{0}/TrainingTesting/testingSet{0}_{1}".format(location,v))
    validate = kImg.sampleRegions(testingSet, ['TYPE_CODE'], 10)
    confusionMatrix = ee.ConfusionMatrix(validate.errorMatrix('TYPE_CODE', 'classification'))

    overallAccuracy = confusionMatrix.accuracy()
    producersAccuracy=  confusionMatrix.producersAccuracy()
    consumersAccuracy= confusionMatrix.consumersAccuracy()

    results= ee.FeatureCollection([ee.Feature(None, {'metric': 'cf', 'result': confusionMatrix.array()}),    ee.Feature(None, {'metric': 'overall accuracy', 'result': confusionMatrix.accuracy()}),    ee.Feature(None, {'metric': 'producers accuracy', 'result': confusionMatrix.producersAccuracy()}),    ee.Feature(None, {'metric': 'consumers accuracy', 'result': confusionMatrix.consumersAccuracy()}),    ee.Feature(None, {'metric': 'kappa', 'result': confusionMatrix.kappa()})])

    return results.map(lambda f : f.set('RUN_NUMBER', v))

#Test against 10 testing set features
NUMBER_OF_TESTS = 10

res = ee.FeatureCollection(ee.Feature(None,{}))
for i in range(NUMBER_OF_TESTS,0,-1):
    res = generateResults(i).merge(res)

res = res.sort('metric')

#Export results of classification accuracy test
def export_results(output_file_name):
    task=ee.batch.Export.table.toDrive(
            collection=res,
            folder = location,
            fileFormat='CSV',
            fileNamePrefix=output_file_name,
            selectors=['RUN_NUMBER','metric','result'])
    task.start()

export_results('kmeansTest')

felled = ee.FeatureCollection('users/tomw_ee/{0}/{0}_felled'.format(location))

felled=felled.map(lambda f: f.set('area', f.area()))
felled = felled.map(lambda f: f.set('TYPE_CODE', 1))

results = kImg.reduceRegions(felled, ee.Reducer.mode(), 10)
                                 
def export_results(output_file_name):
    task=ee.batch.Export.table.toDrive(
            description = output_file_name,
            collection=results,
            folder = location,
            fileFormat='CSV',
            fileNamePrefix=output_file_name,
            selectors=['TYPE_CODE','mode', 'area'])
    task.start()

export_results('kmeansAreaResults') 

