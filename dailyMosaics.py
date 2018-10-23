# -*- coding: utf-8 -*-
"""
GEE Python functions for daily mosaics
ideas from script by Ian Housman:
https://groups.google.com/forum/#!msg/google-earth-engine-developers/i63DS-Dg8Sg/FGuT5OtSAQAJ;context-place=msg/google-earth-engine-developers/jYFuopAlIi0/tf2AKG4_BAAJ
    
"""
#Function to find unique values in a collection
def uniqueValues(collection,field):
    values  =ee.Dictionary(collection.reduceColumns(ee.Reducer.frequencyHistogram(),[field]).get('histogram')).keys()
    return values

#Simplify date to exclude time of day
def simplifyDate(img):
    d = ee.Date(img.get('system:time_start'))
    day = d.get('day')
    m = d.get('month')
    y = d.get('year')
    simpleDate = ee.Date.fromYMD(y,m,day)
    return img.set('simpleTime',simpleDate.millis())

#For each day mosaic the images in the collection
def collectionDaily(d):
    d = ee.Number.parse(d)
    d = ee.Date(d)
    t = imgs.filterDate(d,d.advance(1,'day'))
    f = ee.Image(t.first())
    t = t.mosaic()
    t = t.set('system:time_start',d.millis())
    t = t.copyProperties(f)
    return t

#Build daily mosaics
def dailyMosaics(imgs):
    imgs = imgs.map(simplifyDate)
    #Find the unique days
    days = uniqueValues(imgs,'simpleTime')
    imgs = days.map(collectionDaily)
    imgs = ee.ImageCollection.fromImages(imgs)
    return imgs

