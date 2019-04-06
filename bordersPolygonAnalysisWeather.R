#Create 1 ha square to sample
library(ggplot2)
library(gridExtra)

resultsDir = "C:/Users/tom/Documents/Data Science MSc/Project/Results/exportedEEResults"

xmin = 351200
ymin = 587400
xmax = 351300
ymax = 587500

f = rbind(c(xmin,ymin), c(xmin,ymax), c(xmax,ymax), c(xmax,ymin), c(xmin,ymin))
p = st_polygon(list(f))
extent = st_sfc(p, crs =27700)

#st_write(extent,file.path(wd,'testSQ.shp'))

descending = read.csv(file.path(resultsDir, 'sampleSqMeanDesc.csv'), stringsAsFactors = FALSE)
ascending =  read.csv(file.path(resultsDir, 'sampleSqMeanAsc.csv'), stringsAsFactors = FALSE)
descending$date <- as.Date(descending$date, format = "%Y-%m-%d")
descending$orbit <-"Descending orbit"

ascending$date <- as.Date(ascending$date, format = "%Y-%m-%d")
ascending$orbit <- "Ascending orbit"

allrows = rbind(descending, ascending)

vv = allrows %>% select(-VH)
vv= vv %>% rename(backscatter = VV)
vv$polarization <- 'VV'
vh = allrows %>% select(-VV)
vh = vh %>% rename(backscatter = VH)
vh$polarization <- 'VH'

allrows = rbind(vv, vh)

######GRAPH OF BACKSCATTER OVER TIME###########

dat_text <- data.frame(
  label = c("VV", "VH", "VV", "VH"),
  orbit   = c("Ascending orbit", "Ascending orbit", "Descending orbit", "Descending orbit"),
  x = c(max(allrows$date), max(allrows$date)),
  y = c(-8.5, -15.0, -8.5, -15.0)
)

ggplot()+
  geom_line(data = allrows, aes(x=date, y=backscatter, colour = polarization))+
  labs(y = "backscatter (dB)", x = "Date")+
  theme_bw()+
  theme(axis.text.x = element_text(angle = 90, hjust = 1, size =8), axis.title = element_text(size = 8), legend.position = "none")+
  scale_x_date(date_breaks = "1 months", date_labels ="%m-%Y")+
  facet_wrap(vars(orbit), ncol=1)+
  geom_text(data = dat_text, aes(x=x, y=y, label=label), size=3)+
  theme(strip.background = element_blank(), strip.text = element_text(size = 8))

vh%>%
ggplot(aes(x=angle, y=backscatter, colour = orbit, shape = platform)) +
  geom_point(size=2, shape=23)+
  labs(x="Incidence Angle", y= "Backscatter dB", colour = "Orbit")+
  theme_bw()+
  theme(axis.title = element_text(size = 8), axis.text = element_text(size = 8), 
        legend.text = element_text(size = 8), legend.title = element_blank(), legend.position = c(0.5,0.8))

###############DATE WEATHER ANALYSIS########################

#devtools::install_github("hrbrmstr/darksky")
library(darksky)

daterange <- seq(min(allrows$date), max(allrows$date), "1 day")

#weather_date = daterange %>% map(~get_forecast_for(55.0844,-4.6424, .x, units = 'si')) %>% map_df('daily')

#write.csv(weather_date, 'C:/Users/tom/Documents/Data Science MSc/Project/SupportingData/darkskyConiferSample.csv')

weather_date<- read.csv('C:/Users/tom/Documents/Data Science MSc/Project/SupportingData/darkskyConiferSample.csv', stringsAsFactors = FALSE)

weather_date$date <- as.Date(weather_date$time, format= '%Y-%m-%d')

#allrows$date2 <- allrows$date+1

#allrows2 = allrows %>% inner_join(weather_date, by=c('date2'= 'date'))
allrows =  allrows %>% inner_join(weather_date, by='date')

test = lm(backscatter ~ temperatureHigh, data = allrows %>% filter(polarization =='VV' & orbit == 'Ascending orbit'))

summary(test)$r.squared

p1<- allrows %>% filter(polarization =='VV' & orbit =='Descending orbit') %>%
  ggplot(aes(x=date, y=backscatter))+
  geom_line(colour = 'green')+
  labs(y='VV backscatter(dB)', title = 'VV backscatter')+
  scale_x_date(date_breaks = "1 months", date_labels ="%m-%Y")+
  theme_bw()+
  theme(plot.title = element_text(margin = margin(t = 10, b = -20),size=8), axis.title.x = element_blank(), axis.text.x=element_text(angle = 90, hjust = 1, size =8), axis.text.y= element_text(size=8),axis.title.y= element_text(size=8))


p2<-ggplot(weather_date)+
  geom_line(aes(x=date, y=temperatureLow), colour = 'blue')+
  geom_line(aes(x=date, y=temperatureHigh), colour = 'red')+
  labs(title= "Temp daily high /low", y="Temp (C)", x="Month - year")+
  scale_x_date(date_breaks = "1 months", date_labels ="%m-%Y")+
  theme_bw()+
  theme(plot.title = element_text(margin = margin(t = 10, b = -20),size=8), axis.text.x = element_text(angle = 90, hjust = 1, size =8), axis.title = element_text(size = 8), axis.text.y=element_text(size=8))

grid.arrange(p1,p2, nrow =2)

##############ADD RAINFALL#######################

rainfall = read.csv('C:/Users/tom/Documents/Data Science MSc/Midas/midas_raindrnl_201801-201812.csv', stringsAsFactors = FALSE)
rainfall2017 = read.csv('C:/Users/tom/Documents/Data Science MSc/Midas/midas_raindrnl_201701-201712.csv', stringsAsFactors = FALSE)

rainfall = rbind(rainfall, rainfall2017)

rainfall = rainfall %>% filter(SRC_ID == 56077)

rainfallUse = rainfall %>% group_by(OB_DATE)%>%
  summarise(precip = mean(PRCP_AMT))


rainfallUse$date <- as.Date(rainfallUse$OB_DATE, format= '%Y-%m-%d')

rainfallUse = rainfallUse %>%select(-OB_DATE)

allrows = allrows %>% left_join(rainfallUse, by='date')


p1<- allrows %>% filter(polarization =='VV' & orbit =='Descending orbit') %>%
  ggplot(aes(x=date, y=backscatter))+
  geom_line(colour = 'green')+
  labs(y='VV backscatter(dB)', title = 'VV backscatter')+
  scale_x_date(date_breaks = "1 months", date_labels ="%m-%Y")+
  theme_bw()+
  theme(plot.title = element_text(margin = margin(t = 10, b = -20),size=8), axis.title.x = element_blank(), axis.text.x=element_text(angle = 90, hjust = 1, size =8), axis.text.y= element_text(size=8),axis.title.y= element_text(size=8))


p2<-ggplot(allrows)+
  geom_line(aes(x=date, y=precip), colour = 'blue')+
  labs(title= "Precipitation", y="Precipiation (mm)", x="Month - year")+
  scale_x_date(date_breaks = "1 months", date_labels ="%m-%Y")+
  theme_bw()+
  theme(plot.title = element_text(margin = margin(t = 10, b = -20),size=8), axis.text.x = element_text(angle = 90, hjust = 1, size =8), axis.title = element_text(size = 8), axis.text.y=element_text(size=8))

grid.arrange(p1,p2, nrow =2)


weatherAnalysis = allrows %>%select (backscatter, orbit,polarization,
temperatureHigh, temperatureLow, dewPoint, humidity, pressure, windSpeed, 
cloudCover,precip)

  weatherAnalysis %>%
  filter(orbit == 'Ascending orbit' & polarization == 'VH' & precip < 50)%>%
  select(-orbit, -polarization)%>%
  gather(-backscatter, key = "key", value = "value")%>%
  ggplot(aes(x = value, y = backscatter)) +
  geom_point() +
  labs(y="Backscatter dB")+
  facet_wrap(~ key, scales = "free", nrow =2) +
  theme_bw()+
  theme(strip.background = element_blank(), axis.text = element_text(size =8),
          axis.title.y = element_text(size = 8),axis.title.x=element_blank())
  
#Date + 1 analysis reload fresh allrows table without weather joins

allrows$date2 = allrows$date - 1
  
allrows2 = allrows %>% inner_join(weather_date, by = c('date2' = 'date'))

allrows2 = allrows2 %>% left_join(rainfallUse, by=c('date2'='date'))

weatherAnalysis2 = allrows2 %>%select (backscatter, orbit,polarization,
                                     temperatureHigh, temperatureLow, dewPoint, humidity, pressure, windSpeed, 
                                     cloudCover,precip)

weatherAnalysis2 %>%
  filter(orbit == 'Descending orbit' & polarization == 'VV' & precip < 50)%>%
  select(-orbit, -polarization)%>%
  gather(-backscatter, key = "key", value = "value")%>%
  ggplot(aes(x = value, y = backscatter)) +
  geom_point() +
  labs(y="Backscatter DB")+
  facet_wrap(~ key, scales = "free", nrow =2) +
  theme_bw()+
  theme(strip.background = element_blank(), axis.text = element_text(size =8),
        axis.title.y = element_text(size = 8),axis.title.x=element_blank())

weatherAnalysis = weatherAnalysis[complete.cases(weatherAnalysis),]

testinit = weatherAnalysis2 %>% 
  filter(orbit == 'Ascending orbit' & polarization == 'VH') %>%select(-orbit, -polarization)
  
test= testinit%>%  map(~lm(testinit$backscatter ~ .x, data=testinit))%>%
  map(summary) %>% 
  map_dbl("r.squared")

test = data.frame(as.list(test))
test$orbit = 'Ascending orbit'
test$polarisation = 'VH'
test$relate = 'Previous day'

out = rbind(test, if(exists("out")) out)

write.csv(out, 'C:/Users/tom/Documents/Data Science MSc/Project/Results/exportedEEResults/weatherRSquared.csv')



