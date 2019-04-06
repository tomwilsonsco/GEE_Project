#Tom Wilson January 2019

#Import modules required
import ee
ee.Initialize()
import random
import os

#Set test location
location = 'GB'#'Kielder' #'Dumfries', 'Thetford' 'SouthEng' 'GB'

# #### Create / replace folder as GEE Asset

#Clear any existing training testing points in that asset folder
os.system('earthengine rm -r users/tomw_ee/{0}/TrainingTesting'.format(location))
os.system('earthengine create folder users/tomw_ee/{0}/TrainingTesting'.format(location))

# ## Data preparation functions

#Set the rate of point sampling of training polygons
POINTS_PER_POLY_AREA_FELLED = 0.0001
POINTS_PER_POLY_AREA_MATURE = 0.0001

#Functions to prepare and export training and testing points
def createPointsFelled(f):
    return ee.FeatureCollection.randomPoints(f.geometry(),     f.area().multiply(POINTS_PER_POLY_AREA_FELLED).round(), ee.Number(f.get('random')).multiply(10000).int())    .map(lambda f : f.set('TYPE_CODE', 1))

def createPointsMature(f):
    return ee.FeatureCollection.randomPoints(f.geometry(),     f.area().multiply(POINTS_PER_POLY_AREA_MATURE).round(), ee.Number(f.get('random')).multiply(10000).int())    .map(lambda f : f.set('TYPE_CODE', 0))

def bufferPoly(f):
    return f.buffer(-10)

def export_shapes(fc, output_file_name):
    task=ee.batch.Export.table.toAsset(
            collection=fc,
            assetId = "users/tomw_ee/{0}/TrainingTesting/".format(location)+output_file_name,
            description = output_file_name)
    task.start()


#Ensure classes contain approximately balanced numbers of felled / mature trees 
def balanceSets(fc):
    tree = fc.filter(ee.Filter.eq('TYPE_CODE', 0))
    fell = fc.filter(ee.Filter.eq('TYPE_CODE', 1))
    p =(fell.size().divide(tree.size()))
    tree = tree.randomColumn('random')
    tree = tree.filter(ee.Filter.lt('random', p))
    p2 =(tree.size().divide(fell.size()))
    fell = fell.randomColumn('random')
    fell = fell.filter(ee.Filter.lt('random', p2))
    return tree.merge(fell)


#Function to create the samples
def generateSamples(v):
    felled = ee.FeatureCollection('users/tomw_ee/{0}/{0}_felled'.format(location))
    mature = ee.FeatureCollection('users/tomw_ee/{0}/{0}_mature'.format(location))

    felled = felled.randomColumn('random',random.randint(0, 9999))
    mature = mature.randomColumn('random',random.randint(0, 9999))

    felledTrain = felled.filter(ee.Filter.lessThan('random', 0.7))
    felledTest = felled.filter(ee.Filter.greaterThanOrEquals('random', 0.7))

    matureTrain = mature.filter(ee.Filter.lessThan('random', 0.7))
    matureTest = mature.filter(ee.Filter.greaterThanOrEquals('random', 0.7))

    felledTrain = felledTrain.map(bufferPoly)
    matureTrain = matureTrain.map(bufferPoly)

    felledTest = felledTest.map(bufferPoly)
    matureTest = matureTest.map(bufferPoly)
    
    trainingSet = felledTrain.map(createPointsFelled).flatten().merge(matureTrain.map(createPointsMature).flatten())
    testingSet = felledTest.map(createPointsFelled).flatten().merge(matureTest.map(createPointsMature).flatten())
    trainingSet = balanceSets(trainingSet)
    testingSet = balanceSets(testingSet)
    
    export_shapes(trainingSet, 'trainingSet{0}_{1}'.format(location,v))
    export_shapes(testingSet, 'testingSet{0}_{1}'.format(location,v))

#Number of sets of training / testing data to generate using different test/ train splits
NUMBER_OF_TESTS = 1

for i in range(1, NUMBER_OF_TESTS+1):
    generateSamples(i)

