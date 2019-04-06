wd = 'C:/Users/tom/Documents/Data Science MSc/Project/SupportingData'

scdb <- st_read(file.path(wd,'GB_SCDB_Oct_2018_flyr_BNG_FIXED_REGIONS_SP.shp'), stringsAsFactors = FALSE)

felled = scdb %>%
  filter(PRI_LUCODE == 'PFE' & PRI_FLYR >= 2014 &
    (is.na(SEC_SPCODE) | SEC_FLYR >= 2014) &
    (is.na(TER_SPCODE) | TER_FLYR >= 2014)
  )

felled$TYPE = 'felled'

felled = felled %>% group_by(TYPE) %>% summarise(done='dissolved')

felled = st_cast(felled, "POLYGON")

felled$area <- as.numeric(st_area(felled))

#Filter out sample polygons < 1000m2
felled = felled %>% filter(area >= 1000)

st_write(felled,file.path(wd,'scdbFelled1418.shp'))
