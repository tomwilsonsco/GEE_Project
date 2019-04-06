library(raster)
library(sf)
library(RStoolbox)
library(ggsn)
library(ggplot2)
library(gridExtra)

xmin = 316132
ymin = 606183
xmax = 326359
ymax = 609600

wd = 'C:/Users/tom/Documents/Data Science MSc/Project/SupportingData'

img =brick(file.path(wd,'s1SlopeAsc.tif'))
img2 =brick(file.path(wd,'s1SlopeDesc.tif'))

f = rbind(c(xmin,ymin), c(xmin,ymax), c(xmax,ymax), c(xmax,ymin), c(xmin,ymin))
p = st_polygon(list(f))
bb = st_sfc(p, crs =27700)
bbs = as_Spatial(bb)

img = crop(img, bbs)
img2 = crop(img2, bbs)


p1<-ggplot()+
  ggRGB(img,r=1,g=2,b=3,ggLayer=TRUE)+
  labs(title='Ascending orbit')+
  theme_bw()+
  coord_sf(datum=st_crs(27700), xlim=c(xmin,xmax), ylim=c(ymin,ymax))+
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0))+
  ggsn::scalebar(st.bottom = FALSE, x.max=xmax, x.min=xmin, y.min=ymin, y.max=ymax,
                 location="bottomright", dd2km=FALSE, dist=1, st.size=3.0, st.color='white',anchor=c(x=xmax-500, y=ymin))+
  north(x.max=xmax,x.min=xmin, y.min=ymin, y.max=ymax, symbol=10, location = "bottomright", anchor = c(x=xmax,y=ymin+600))+
  theme(plot.title=element_text(size=8),axis.title= element_blank(), axis.text = element_text(size=7), legend.position='none')

p2<- ggplot()+
  ggRGB(img2,r=1,g=2,b=3,ggLayer=TRUE)+
  labs(title='Descending orbit')+
  theme_bw()+
  coord_sf(datum=st_crs(27700), xlim=c(xmin,xmax), ylim=c(ymin,ymax))+
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0))+
  ggsn::scalebar(st.bottom = FALSE, x.max=xmax, x.min=xmin, y.min=ymin, y.max=ymax,
                 location="bottomright", dd2km=FALSE, dist=1, st.size=3.0, st.color='white',anchor=c(x=xmax-500, y=ymin))+
  north(x.max=xmax,x.min=xmin, y.min=ymin, y.max=ymax, symbol=10, location = "bottomright", anchor = c(x=xmax,y=ymin+600))+
  theme(plot.title = element_text(size=8), axis.title= element_blank(), axis.text = element_text(size=7), legend.position='none')

grid.arrange(p1, p2, nrow=2)