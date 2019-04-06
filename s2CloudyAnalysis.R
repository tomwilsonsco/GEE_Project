library(tidyverse)
library(reshape2)
library(grid)
library(ggsn)

wd = 'C:/Users/tom/Documents/Data Science MSc/Project/Results/exportedEEResults'

cloudy = read.csv(file.path(wd, 's2CloudAnalysis.csv'), stringsAsFactors = FALSE)

cloudy = cloudy%>%distinct()

cloudy$date <- as.Date(cloudy$date, '%d/%m/%Y')

cloudy = cloudy %>% mutate(monthYr = format(date, '%Y-%m') )

cloudy$monthYr = paste0(cloudy$monthYr,'-01')

cloudy$monthYr = as.Date(cloudy$monthYr, '%Y-%m-%d')


cloudySum = cloudy %>% select(-date) %>% group_by(monthYr) %>%
  summarise_all(funs(min,max,mean,n()))%>%
  select(monthYr, cloudPercent_n, cloudPercent_min, cloudPercent_max, cloudPercent_mean, 
         QACloud_min, QACloud_max, QACloud_mean, cloudScoreOut_min, cloudScoreOut_max, cloudScoreOut_mean)

cloudLong = melt(cloudySum, id="monthYr")
cloudLong = cloudLong %>% filter(variable %in% c('cloudPercent_mean','QACloud_mean','cloudScoreOut_mean'))

analysisNames = c('cloudPercent_mean'='Mean of overall image % cloud cover value from ESA metadata',
                  'QACloud_mean'= 'Mean % of sample forest under cloud - using ESA cloud mask',
                  'cloudScoreOut_mean'='Mean % of sample forest under cloud - using pixel value analysis')

ggplot(data=cloudLong, aes(x=monthYr, y=value))+
  geom_bar(aes(fill=variable),stat="identity", width=15)+
  labs(x='Month / Year')+
  theme_bw()+
  theme(legend.position = "none", strip.background = element_blank(), axis.title.y = element_blank(),
        axis.text.x =element_text(size=8, angle=90), axis.text.y =element_text(size=8),
        axis.title.x= element_text(size=8), strip.text= element_text(size=8))+
  scale_x_date(expand=c(0,0), date_breaks = "1 months", date_labels ="%m-%Y")+
  facet_wrap(~variable, nrow=3, labeller=as_labeller(analysisNames))+
  scale_fill_manual(values= c('#A11E22','#E8A631','#878D92'))


p1<-ggplot(data=cloudySum, aes(x=monthYr, y=cloudPercent_mean))+
  geom_pointrange(aes(ymin=cloudPercent_min, ymax=cloudPercent_max))+
  labs(title='Overall image % cloud cover value from ESA metadata')+
  theme_bw()+
  theme(plot.margin = unit(c(0.1,0.1,0.1,0.1), "cm"),axis.ticks.x = element_blank(), plot.title=element_text(size=10),legend.position = "none", strip.background = element_blank(), axis.title.y = element_blank(),
        axis.text.x =element_blank(), axis.text.y =element_text(size=8),
        axis.title.x= element_blank())+
  scale_x_date(expand=c(0.02,0.02),date_breaks = "1 months", date_labels ="%m-%Y")

p2<-ggplot(data=cloudySum, aes(x=monthYr, y=QACloud_mean))+
  geom_pointrange(aes(ymin=QACloud_min, ymax=QACloud_max))+
  labs(title='% of sample forest under cloud - using ESA cloud mask')+
  theme_bw()+
  theme(plot.margin = unit(c(0.1,0.1,0.1,0.1), "cm"),axis.ticks.x=element_blank(), plot.title=element_text(size=10),legend.position = "none", strip.background = element_blank(), axis.title.y = element_blank(),
        axis.text.x =element_blank(), axis.text.y =element_text(size=8),
        axis.title.x= element_blank())+
  scale_x_date(expand=c(0.02,0.02),date_breaks = "1 months", date_labels ="%m-%Y")


p3<-ggplot(data=cloudySum, aes(x=monthYr, y=cloudScoreOut_mean))+
  geom_pointrange(aes(ymin=cloudScoreOut_min, ymax=cloudScoreOut_max))+
  labs(title='% of sample forest under cloud - using GEE user community method', x='Month / Year')+
  theme_bw()+
  theme(plot.margin = unit(c(0.1,0.1,0.1,0.1), "cm"),plot.title=element_text(size=10),legend.position = "none", strip.background = element_blank(), axis.title.y = element_blank(),
        axis.text.x =element_text(size=8, angle=90), axis.text.y =element_text(size=8),
        axis.title.x= element_text(size=8))+
  scale_x_date(expand=c(0.02,0.02),date_breaks = "1 months", date_labels ="%m-%Y")

grid.newpage()
grid.draw(rbind(ggplotGrob(p1), ggplotGrob(p2),ggplotGrob(p3), size = "last"))



dl = as.vector(cloudySum$monthYr)

cloudySum = cloudySum %>% mutate(monthYr = format(monthYr, '%m-%Y'))
dl = as.vector(cloudySum$monthYr)
cloudySum$monthYr = factor(cloudySum$monthYr, levels=dl)
#cloudAnalysis = melt(cloudySum, id="monthYr")
#cloudAnalysis = cloudAnalysis %>% spread(monthYr, value)

write.csv(cloudySum, file.path(wd,'cloudAnalysisResult.csv'))
