library(raster)
library(sf)
library(RStoolbox)
library(ggsn)
library(ggplot2)
library(gridExtra)
library(grid)


xmin = 344392
ymin = 566407
xmax = 384165
ymax = 613268

wd = 'C:/Users/tom/Documents/Data Science MSc/Project/SupportingData'

img= raster(file.path(wd,'s1imgVHKielder.tif'))
img1= raster(file.path(wd,'s1VVRF.tif'))
img2 =raster(file.path(wd,'s1VVMedian.tif'))

f = rbind(c(xmin,ymin), c(xmin,ymax), c(xmax,ymax), c(xmax,ymin), c(xmin,ymin))
p = st_polygon(list(f))
bb = st_sfc(p, crs =27700)
bbs = as_Spatial(bb)

img = crop(img, bbs)
img1 = crop(img1, bbs)
img2 = crop(img2, bbs)

poly = st_read(file.path(wd,'Kielder/Woodland_AreaClipKielder.shp'), stringsAsFactors = FALSE)
poly$use =1
poly = poly %>% group_by(use) %>%summarise(done = 'diss')
poly = st_cast(poly, 'POLYGON')
poly$area <- as.numeric(st_area(poly))
poly = poly %>% filter(area > 1000000)

ggplot()+
  ggR(img,ggLayer=TRUE, geom_raster=TRUE)+
  geom_sf(data = poly, fill = NA, colour = 'red', size = 0.5)+
  scale_fill_gradient(low='black',high='white')+
  theme_bw()+
  coord_sf(datum=st_crs(27700), xlim=c(xmin,xmax), ylim=c(ymin,ymax))+
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0))+
  #ggsn::scalebar(st.bottom = FALSE, x.max=xmax, x.min=xmin, y.min=ymin, y.max=ymax,
  #location="bottomright", dd2km=FALSE, dist=1, st.size=3.0, st.color='black',anchor=c(x=xmax-5000, y=ymin))+
  #north(x.max=xmax,x.min=xmin, y.min=ymin, y.max=ymax, symbol=10, location = "bottomright", anchor = c(x=xmax,y=ymin+600))+
  theme(plot.margin = unit(c(0.8,0.8,0.8,0.8), "lines"),plot.title = element_text(size=8), axis.title= element_blank(), axis.text = element_text(size=7), legend.position='none')

