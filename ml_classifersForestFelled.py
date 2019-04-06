#Tom Wilson January 2019
#Import modules required
import ee
import numpy as np
ee.Initialize()
import random
import math
from refinedLeeS1 import *
import os

# ## Prepare S1 image and supporting data into composite image

#Set location for testing
location = 'SouthEng'#'Dumfries', 'Thetford', 'Kielder' 'SouthEng', 'GB'

#Import extent
extent = ee.FeatureCollection('users/tomw_ee/{0}/{0}_extent'.format(location))

#Optional normalise function
def normalize(img):
    vh = img.select(1).divide(-30)
    return img.select(0).divide(-25).addBands(vh).rename(['VV','VH']).copyProperties(img)

#Import S1 image collection for month in question
s1c = ee.ImageCollection('COPERNICUS/S1_GRD').filterBounds(extent).filterDate('2018-07-01', '2018-07-31')#.map(normalize)


#make median composite of monthly values
img = s1c.median()


#Create Ascending / Descending Composites
imgasc = s1c.filter(ee.Filter.eq('orbitProperties_pass', 'ASCENDING')).median().select(['VV', 'VH'],['VVasc','VHasc'])
imgdesc = s1c.filter(ee.Filter.eq('orbitProperties_pass', 'DESCENDING')).median().select(['VV', 'VH'],['VVdesc','VHdesc'])


#Create ratio bands
imgasc = imgasc.addBands(imgasc.select('VVasc').subtract(imgasc.select('VHasc')).rename('Ratioasc'))
imgdesc = imgdesc.addBands(imgdesc.select('VVdesc').subtract(imgdesc.select('VHdesc')).rename('Ratiodesc'))


#Create slope and aspect layers
srtm = ee.Image('USGS/SRTMGL1_003')
slope = ee.Terrain.slope(srtm).select('slope')
aspect = ee.Terrain.aspect(srtm).select('aspect')


#Add Texture
def toNatural(img):
    return ee.Image(10.0).pow(img.divide(10.0))

def getTexture(img):
    square = ee.apply('Kernel.square',{'radius': 1.0,'normalize': True})
    return img.unitScale(0,1).multiply(255).toByte().glcmTexture(1, square, True).select(['VH_var','VH_ent','VH_contrast'])

def renameBand(img):
    return img.rename('VH')

#rfall = s1c.select('VH').map(toNatural).map(renameBand).map(getTexture)

tasc = s1c.filter(ee.Filter.eq('orbitProperties_pass', 'ASCENDING')).select('VH').map(toNatural).map(renameBand).map(getTexture)
tdesc = s1c.filter(ee.Filter.eq('orbitProperties_pass', 'DESCENDING')).select('VH').map(toNatural).map(renameBand).map(getTexture)

#textImgAll = rfall.median().rename(['Var','Ent','Cont'])
textImgAsc = tasc.median().select(['VH_var'],['Var_asc'])#,'Ent_asc','Cont_asc'])
textImgDesc = tdesc.median().select(['VH_var'],['Var_desc'])#,'Ent_desc','Cont_desc'])



#Add Percentiles
s10pasc = s1c.filter(ee.Filter.eq('orbitProperties_pass', 'ASCENDING')).reduce(ee.Reducer.percentile([10])).select(['VV_p10','VH_p10'],['VVasc_p10','VHasc_p10'])

s10pasc = s10pasc.addBands(s10pasc.select('VVasc_p10').subtract(s10pasc.select('VHasc_p10')).rename('Ratioasc_p10'))

s10pdesc = s1c.filter(ee.Filter.eq('orbitProperties_pass', 'DESCENDING')).reduce(ee.Reducer.percentile([10])).select(['VV_p10','VH_p10'],['VVdesc_p10','VHdesc_p10'])

s10pdesc = s10pdesc.addBands(s10pdesc.select('VVdesc_p10').subtract(s10pdesc.select('VHdesc_p10')).rename('Ratiodesc_p10'))

s90pasc = s1c.filter(ee.Filter.eq('orbitProperties_pass', 'ASCENDING')).reduce(ee.Reducer.percentile([90])).select(['VV_p90','VH_p90'],['VVasc_p90','VHasc_p90'])

s90pdesc = s1c.filter(ee.Filter.eq('orbitProperties_pass', 'DESCENDING')).reduce(ee.Reducer.percentile([90])).select(['VV_p90','VH_p90'],['VVdesc_p90','VHdesc_p90'])


#Local incidence angle uses aspect calculated from SRTM earlier
im1inc = s1c.filter(ee.Filter.eq('orbitProperties_pass', 'ASCENDING')).first().select('angle')
s1_azimuth = ee.Terrain.aspect(im1inc).reduceRegion(ee.Reducer.mean(), im1inc.get('system:footprint'), 1000).get('aspect')
slope_projected = slope.multiply(ee.Image.constant(s1_azimuth).subtract(aspect).multiply(math.pi/180).cos())
liaAsc = im1inc.subtract(ee.Image.constant(90).subtract(ee.Image.constant(90).subtract(slope_projected))).abs()
liaAsc = liaAsc.rename('liaAsc')

im2inc = s1c.filter(ee.Filter.eq('orbitProperties_pass', 'DESCENDING')).first().select('angle')
s1_azimuth2 = ee.Terrain.aspect(im2inc).reduceRegion(ee.Reducer.mean(), im2inc.get('system:footprint'), 1000).get('aspect')
slope_projected2 = slope.multiply(ee.Image.constant(s1_azimuth).subtract(aspect).multiply(math.pi/180).cos())
liaDesc = im2inc.subtract(ee.Image.constant(90).subtract(ee.Image.constant(90).subtract(slope_projected))).abs()
liaDesc = liaDesc.rename('liaDesc')


#Add all bands to composite image
#img = img.addBands(imgdesc).addBands(imgasc).addBands(liaDesc).addBands(liaAsc).addBands(slope).addBands(aspect)
#img = img.addBands(imgdesc).addBands(imgasc).addBands(textImgAsc).addBands(textImgDesc)
img = img.addBands(imgdesc).addBands(imgasc)#.addBands(s10pasc).addBands(s10pdesc)#.addBands(liaDesc).addBands(liaAsc)#.addBands(textImgAsc).addBands(textImgDesc)#.addBands(liaAsc).addBands(liaDesc)#.addBands(s10pasc).addBands(s10pdesc)
#img = img.addBands(imgdesc).addBands(imgasc).addBands(slope).addBands(aspect)


#Bands to be used for training
predictionBands = ['VVdesc','VHdesc','Ratioasc','Ratiodesc','VVasc','VHasc'] # Regular
#predictionBands = ['VVasc_p10','VHasc_p10','VVdesc_p10','VHdesc_p10'] #percentile test
#predictionBands = ['VVdesc','VHdesc','Ratioasc','Ratiodesc','VVasc','VHasc','liaAsc','liaDesc'] #Local incidence angle
#predictionBands = ['VVdesc','VHdesc','Ratioasc','Ratiodesc','VVasc','VHasc','liaAsc','liaDesc','slope','aspect'] #Slope aspect
#predictionBands = ['VVdesc','VHdesc','Ratioasc','Ratiodesc','VVasc','VHasc','Var_asc','Var_desc'] #Texture
#predictionBands = ['VHdesc','VHasc', 'VHasc_p10', 'VHdesc_p10'] #VH only

#predictionBands =['VV','VH','VVdesc','VHdesc','Ratioasc','Ratiodesc','VVasc','VHasc','liaDesc','liaAsc','Var_asc','Var_desc',\
#'VVasc_p10','VHasc_p10','VVdesc_p10','VHdesc_p10','VVasc_p90','VHasc_p90','VVdesc_p90','VHdesc_p90']


# ## Test 1. Cross validation, multiple test train splits, validate test set


#Function to build RF classifier and test for each numbered set of testing / training features
def generateResults(v):

    trainingSet = ee.FeatureCollection("users/tomw_ee/{0}/TrainingTesting/trainingSet{0}_{1}".format(location,v))
    testingSet = ee.FeatureCollection("users/tomw_ee/{0}/TrainingTesting/testingSet{0}_{1}".format(location,v))

    #Create sample points within training polygons for classifier
    classifierTraining = img.sampleRegions(trainingSet, ['TYPE_CODE'], 10)
    
    #Option to limit size of training set to improve performance (if want to use all comment out)
    trainingSet = trainingSet.randomColumn('random')
    trainingSet = trainingSet.limit(5000, 'random')
    
    #Sample the image pixel values with training points
    classifierTraining = img.sampleRegions(trainingSet, ['TYPE_CODE'], 10)
    
     #Create classifier comment out all but one:
    #RF
    trained = ee.Classifier.randomForest(10, seed=random.randint(0,9999)).train(classifierTraining,'TYPE_CODE', predictionBands)
    
    #SVM
    #trainingSet = trainingSet.randomColumn('random')
    #trainingSet = trainingSet.limit(5000, 'random')
    #classifierTraining = img.sampleRegions(trainingSet, ['TYPE_CODE'], 10)
    #trained = ee.Classifier.svm().train(classifierTraining,'TYPE_CODE', predictionBands)
    
    #CART
    #trained = ee.Classifier.CART()
    
    classifiedImg = img.select(predictionBands).classify(trained)
    #patchsize = classifiedImg.connectedPixelCount(20, False)
    classifiedImg = classifiedImg.focal_mode(radius= 1.5, kernelType= 'square', units= 'pixels', iterations= 2)
    #classifiedImg = classifiedImg.where(patchsize.lt(10),filtered)
    validate = classifiedImg.sampleRegions(testingSet, ['TYPE_CODE'], 10)
    #return validate.map(lambda f : f.set('RUN_NUMBER', v))
    confusionMatrix = ee.ConfusionMatrix(validate.errorMatrix('TYPE_CODE', 'classification'))

    overallAccuracy = confusionMatrix.accuracy()
    producersAccuracy=  confusionMatrix.producersAccuracy()
    consumersAccuracy= confusionMatrix.consumersAccuracy()

    results= ee.FeatureCollection([ee.Feature(None, {'metric': 'cf', 'result': confusionMatrix.array()}),    ee.Feature(None, {'metric': 'overall accuracy', 'result': confusionMatrix.accuracy()}),    ee.Feature(None, {'metric': 'producers accuracy', 'result': confusionMatrix.producersAccuracy()}),    ee.Feature(None, {'metric': 'consumers accuracy', 'result': confusionMatrix.consumersAccuracy()}),    ee.Feature(None, {'metric': 'kappa', 'result': confusionMatrix.kappa()})])

    return results.map(lambda f : f.set('RUN_NUMBER', v))


#Number of tests to run
NUMBER_OF_TESTS = 10

res = ee.FeatureCollection(ee.Feature(None,{}))
for i in range(NUMBER_OF_TESTS,0,-1):
    res = generateResults(i).merge(res)

res = res.sort('metric')


#Export results to Google Drive, setting name for output csv
def export_results(output_file_name):
    task=ee.batch.Export.table.toDrive(
            description = output_file_name,
            collection=res,
            folder = location,
            fileFormat='CSV',
            fileNamePrefix=output_file_name,
            selectors=['metric','result'])
    task.start()

export_results('rf_VH4')


#Optional check progress of test
os.system('earthengine task list > log.txt')
f = open('log.txt','r')
f.readline()


# ## Area Polygon Test and classified image export


#Test to check classification accuracy of whole polygons using modal reducer on classified pixels within polygon
#Specify which set of training features to use
trainingSetNo = 1
#Load training set (1)
trainingSet = ee.FeatureCollection("users/tomw_ee/{0}/TrainingTesting/trainingSet{0}_{1}".format(location, trainingSetNo))

#Number of training samples to use
samples = 10000
  
trainingSet = trainingSet.randomColumn('random')
trainingSet = trainingSet.limit(samples, 'random')

#Sample the S1 image
classifierTraining = img.sampleRegions(trainingSet, ['TYPE_CODE'], 10)
#Build the RF classifiers
trained = ee.Classifier.randomForest(10, seed=random.randint(0,9999)).train(classifierTraining,'TYPE_CODE', predictionBands)

#Classified the image
classifiedImg = img.select(predictionBands).classify(trained)
#Clean classified image with majority filter
classifiedImg = classifiedImg.focal_mode(radius= 1.5, kernelType= 'square', units= 'pixels', iterations= 2)

#Set the band name to classification
classifiedImg = classifiedImg.select('classification')

##Load the validation polygons
felled = ee.FeatureCollection('users/tomw_ee/{0}/{0}_felled'.format(location))

felled=felled.map(lambda f: f.set('area', f.area()))
felled = felled.map(lambda f: f.set('TYPE_CODE', 1))

#Use a mode reducer to determine polygons classified correctly based on majority of pixels
results = classifiedImg.reduceRegions(felled, ee.Reducer.mode(), 10)

#Export the polygon check result
def export_results(output_file_name):
    task=ee.batch.Export.table.toDrive(
            description = output_file_name,
            collection=results,
            folder = location,
            fileFormat='CSV',
            fileNamePrefix=output_file_name,
            selectors=['TYPE_CODE','mode', 'area'])
    task.start()

export_results('rfAreaResults')


def export_images(img, output_file_name):
    task=ee.batch.Export.image.toAsset(
            image=img,
            assetId = "users/tomw_ee/{0}/".format(location)+output_file_name,
            description = output_file_name,
            region = extent.geometry().bounds().getInfo()['coordinates'],
            scale= 10)
    task.start()

#Export the classified image
export_images(classifiedImg, 'rfKielder2')

#Create a probability output classifier
prob = trained.setOutputMode('PROBABILITY')
#Create a probability map (0 mature to 1 felled)
classifiedProb = img.select(predictionBands).classify(prob).rename('prob')
#Export probability image
export_images(classifiedProb, 'probFellGB')
                                 

