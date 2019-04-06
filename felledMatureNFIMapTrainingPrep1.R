#Training Data Prep
#Use the NFI Map felled polygons and mature trees of conifer and blv from SCDB
#1) select an extent
#2) clip polygons by this extent
#3) dissolve polygons by type (blv, conifer, felled)
#4) select X felled and x blv, felled or combinted
#5) for binary classifiers either output 0 blv/con and 1 felled or just 0 con, 1 felled

library(sf)
library(dplyr)
library(ggplot2)

#######CREATE REGION OF INTEREST POLYGON FROM BNG BOUNDING COORDINATES#####
testName = 'SOUTHENG'

#Comment out coords apart from for AOI
#THETFORD
#coords= c(xmin =569788,ymin = 268579,xmax = 608535,ymax = 310029)


#DUMFRIES
#coords= c(xmin = 215150,ymin = 549347,xmax = 289721,ymax = 602831)

#KIELDER
#coords=c(xmin=344392, ymin=566407,xmax=384165, ymax=613268)

#SOUTHENG
coords = c(xmin=468154,ymin=114988,xmax=506900,ymax=156438)

#GB
coords = c(xmin=61259,ymin=-27986,xmax=688468,ymax=999379)

f = rbind(c(coords['xmin'],coords['ymin']), c(coords['xmin'],coords['ymax']), 
          c(coords['xmax'],coords['ymax']), c(coords['xmax'],coords['ymin']), 
          c(coords['xmin'],coords['ymin']))

p = st_polygon(list(f))
extent = st_sfc(p, crs =27700)

########IMPORT DATA#####################################

wd = 'C:/Users/tom/Documents/Data Science MSc/Project/SupportingData'
  
scdb <- st_read(file.path(wd,'GB_SCDB_Oct_2018_flyr_BNG_FIXED.shp'), stringsAsFactors= FALSE)

felled <- st_read(file.path(wd, 'NFIMapFelled1517.shp'))

felledSCDB <- st_read(file.path(wd, 'scdbFelled1418.shp'))

########CLIP BY ROI#####################################
scdb <- st_set_crs(scdb, value=27700)
scdb <- st_intersection(scdb, extent)

felled <- st_set_crs(felled, value=27700)
felled <- st_intersection(felled, extent)
felled$type = 'felled'

felledSCDB <- st_set_crs(felledSCDB, value=27700)
felledSCDB <- st_intersection(felledSCDB, extent)
felledSCDB$type = 'felled'
felledSCDB$Origin = 'SCDB1418'

########MERGE FELLED FROM NFI AND SCDB WITHOUT OVERLAPS######
#Felled SCDB not NFIMap
felledSCDB = st_difference(felledSCDB, st_union(felled))
felled = felled %>% select(Origin, type)
felledSCDB = felledSCDB %>% select(Origin, type)


felled = rbind(felled, felledSCDB)

########CONIFER BLV ONLY################################

mature = scdb %>% 
filter(PRI_PLYEAR <= 2000 & !is.na(PRI_SPCODE) & 
      ((SEC_PLYEAR <= 2000 & !is.na(SEC_SPCODE)) | SECPCTAREA==0) & 
      ((TER_PLYEAR <= 2000 & ! is.na(TER_SPCODE)) | TERPCTAREA ==0))

mature$type = 'mature'

########DISSOLVE, EXPLODE, REMOVE SMALL
mature = mature %>% group_by(type) %>% summarise(done='dissolved')
mature = st_cast(mature, "POLYGON")
mature$area <- as.numeric(st_area(mature))


felled = felled %>% group_by(type) %>% summarise(done= 'dissolved')
felled = st_cast(felled, 'POLYGON')
felled$area <- as.numeric(st_area(felled))

mature = mature %>% filter(area >= 1000)
felled = felled %>% filter(area >= 1000)

########NUMBER OF FELLED SAMPLES########################
n = nrow(felled*2)
matureSample = sample_n(mature, n)


#########WRITE OUTPUTS#################################
outputDir = file.path('C:/Users/tom/Documents/Data Science MSc/Project/SupportingData/',
                      testName)

st_write(felled,file.path(outputDir,paste0(testName,'_felled.shp')))
st_write(mature,file.path(outputDir,paste0(testName,'_mature.shp')))

st_write(extent,file.path(outputDir,paste0(testName,'_extent.shp')))
















