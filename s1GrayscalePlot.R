library(raster)
library(sf)
library(RStoolbox)
library(ggsn)
library(ggplot2)
library(gridExtra)
library(grid)

xmin = 575394
ymin = 280074
xmax = 580000
ymax = 285500

wd = 'C:/Users/tom/Documents/Data Science MSc/Project/SupportingData'

img= raster(file.path(wd,'s1VVNoFilter.tif'))
img1= raster(file.path(wd,'s1VVRF.tif'))
img2 =raster(file.path(wd,'s1VVMedian.tif'))

f = rbind(c(xmin,ymin), c(xmin,ymax), c(xmax,ymax), c(xmax,ymin), c(xmin,ymin))
p = st_polygon(list(f))
bb = st_sfc(p, crs =27700)
bbs = as_Spatial(bb)

img = crop(img, bbs)
img1 = crop(img1, bbs)
img2 = crop(img2, bbs)


p1<-ggplot()+
  ggR(img,ggLayer=TRUE, geom_raster=TRUE)+
  scale_fill_gradient(low='black',high='white')+
  labs(title='Single Image no de-speckling applied')+
  theme_bw()+
  coord_sf(datum=st_crs(27700), xlim=c(xmin,xmax), ylim=c(ymin,ymax))+
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0))+
  #ggsn::scalebar(st.bottom = FALSE, x.max=xmax, x.min=xmin, y.min=ymin, y.max=ymax,
                # location="bottomright", dd2km=FALSE, dist=1, st.size=3.0, st.color='black',anchor=c(x=xmax-500, y=ymin))+
  #north(x.max=xmax,x.min=xmin, y.min=ymin, y.max=ymax, symbol=10, location = "bottomright", anchor = c(x=xmax,y=ymin+600))+
  theme(plot.margin = unit(c(0.8,0.8,0.8,0.8), "lines"),plot.title = element_text(size=8), axis.title= element_blank(), axis.text = element_text(size=7), legend.position='none')

p2<- ggplot()+
  ggR(img1,ggLayer=TRUE, geom_raster=TRUE)+
  scale_fill_gradient(low='black',high='white')+
  labs(title = 'Single Image Refined Lee Filter')+
  theme_bw()+
  coord_sf(datum=st_crs(27700), xlim=c(xmin,xmax), ylim=c(ymin,ymax))+
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0))+
  #ggsn::scalebar(st.bottom = FALSE, x.max=xmax, x.min=xmin, y.min=ymin, y.max=ymax,
  #               location="bottomright", dd2km=FALSE, dist=1, st.size=3.0, st.color='black',anchor=c(x=xmax-500, y=ymin))+
  #north(x.max=xmax,x.min=xmin, y.min=ymin, y.max=ymax, symbol=10, location = "bottomright", anchor = c(x=xmax,y=ymin+600))+
  theme(plot.margin = unit(c(0.8,0.8,0.8,0.8), "lines"),plot.title = element_text(size=8),axis.title= element_blank(), axis.ticks.y=element_blank(),
        axis.text.x= element_text(size=7), axis.text.y = element_blank(), legend.position='none')

p3<- ggplot()+
  ggR(img2,ggLayer=TRUE, geom_raster=TRUE)+
  scale_fill_gradient(low='black',high='white')+
  labs(title = 'Monthly median composite')+
  theme_bw()+
  coord_sf(datum=st_crs(27700), xlim=c(xmin,xmax), ylim=c(ymin,ymax))+
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0))+
  #ggsn::scalebar(st.bottom = FALSE, x.max=xmax, x.min=xmin, y.min=ymin, y.max=ymax,
  #               location="bottomright", dd2km=FALSE, dist=1, st.size=3.0, st.color='black',anchor=c(x=xmax-500, y=ymin))+
  #north(x.max=xmax,x.min=xmin, y.min=ymin, y.max=ymax, symbol=10, location = "bottomright", anchor = c(x=xmax,y=ymin+600))+
  theme(plot.margin = unit(c(0.8,0.8,0.8,0.8), "lines"), plot.title = element_text(size=8),axis.title= element_blank(), axis.ticks.y=element_blank(),
        axis.text.x= element_text(size=7), axis.text.y = element_blank(), legend.position='none')

grid.newpage()
grid.draw(cbind(ggplotGrob(p1), ggplotGrob(p2),ggplotGrob(p3), size = "last"))

