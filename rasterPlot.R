library(raster)
library(ggsn)
library(RStoolbox)
library(sf)
library(gridExtra)

wd = 'C:/Users/tom/Documents/Data Science MSc/Project/SupportingData'
wd2 = 'C:/Users/tom/Documents/Data Science MSc/Project/Results/exportedEEResults'

img = brick(file.path(wd,'s1KielderJune.tif'))
img2 = brick(file.path(wd,'s1KielderJan.tif'))

xmin = 356911
ymin = 582467
xmax = 373527
ymax = 594523

f = rbind(c(xmin,ymin), c(xmin,ymax), c(xmax,ymax), c(xmax,ymin), c(xmin,ymin))
p = st_polygon(list(f))
bb = st_sfc(p, crs =27700)
bbs = as_Spatial(bb)

img = crop(img, bbs)
img2 = crop(img2, bbs)



p1 =ggplot() +
  ggRGB(img, r = 1, g = 2, b = 3, ggLayer= TRUE, stretch = 'lin')+
  coord_sf(datum=st_crs(27700), xlim=c(xmin,xmax), ylim=c(ymin,ymax))+
  labs(title='June 2018')+
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0))+
  ggsn::scalebar(dd2km= FALSE,st.bottom = FALSE, x.max=xmax, x.min=xmin, y.min=ymin, y.max=ymax,
                 location="bottomright", dist=1, st.size=2.5, anchor=c(x=xmax-200, y=ymin))+
  north(x.max=xmax,x.min=xmin, y.min=ymin, y.max=ymax, symbol=10, location = "bottomright", anchor = c(x=xmax,y=ymin+700))+
  theme_bw()+
  theme(axis.title= element_blank(), axis.text = element_text(size=6),
        panel.border = element_blank(),plot.title = element_text(size=8))

p2 =ggplot() +
  ggRGB(img2, r = 1, g = 2, b = 3, ggLayer= TRUE, stretch = 'lin')+
  coord_sf(datum=st_crs(27700), xlim=c(xmin,xmax), ylim=c(ymin,ymax))+
  labs(title='January 2018')+
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0))+
  ggsn::scalebar(dd2km= FALSE,st.bottom = FALSE, x.max=xmax, x.min=xmin, y.min=ymin, y.max=ymax,
                 location="bottomright", dist=1, st.size=2.5, anchor=c(x=xmax-200, y=ymin))+
  north(x.max=xmax,x.min=xmin, y.min=ymin, y.max=ymax, symbol=10, location = "bottomright", anchor = c(x=xmax,y=ymin+700))+
  theme_bw()+
  theme(axis.title= element_blank(), axis.text = element_text(size=6),
        panel.border = element_blank(), plot.title = element_text(size=8))



grid.arrange(p1, p2, nrow=1)
  
  #theme_bw()+
  #scale_x_continuous(expand = c(0, 0)) +
  #scale_y_continuous(expand = c(0, 0))+
  #theme(axis.title = element_blank())+
  #north(r)