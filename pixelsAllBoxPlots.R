library(dplyr)
library(ggplot2)
library(gridExtra)

wd = 'C:/Users/tom/Documents/Data Science MSc/Project/Results/exportedEEResults'

pixels <- read.csv(file.path(wd,'s1DistributionAllSamplesJan2018.csv'), stringsAsFactors = FALSE)

pixels = pixels %>% mutate(Ratio = VV - VH)

pixels = pixels %>% mutate(TYPE= ifelse(TYPE=='mixed_trees','mixed trees', TYPE))

pixels$TYPE <- factor(pixels$TYPE, levels=c('broadleaved', 'conifer','mixed trees','young','felled','open'))

#Create 3 boxplots for VV, VH, Ratio:

p1<- ggplot(data=pixels)+
  geom_boxplot(aes(x=TYPE, y=VV), outlier.shape = NA) +
  labs(y = 'VV (dB)', title='January 2018')+
  coord_cartesian(ylim = c(-15, -5))+
  #scale_y_continuous(labels = scales::number_format(accuracy = 0.1))+
  scale_x_discrete(position = "top")+
  theme_classic()+
  theme(plot.title=element_text(size=10) ,axis.title.x = element_blank(), axis.text.x=element_text(size=8), 
        axis.text.y = element_text(size=8),
        axis.title.y = element_text(size=8))#, plot.margin=unit(c(0.1,0.1,0.1,0.1), "cm"))
   

p2<- ggplot(data=pixels)+
  geom_boxplot(aes(x=TYPE, y=VH), outlier.shape = NA)+
  labs(y = 'VH (dB)')+
  coord_cartesian(ylim = c(-20, -10))+
  #scale_y_continuous(labels = scales::number_format(accuracy = 0.1))+
  theme_classic()+
  theme(axis.title.x = element_blank(), axis.text.x =element_blank(), 
        axis.ticks.x = element_blank(), axis.text.y = element_text(size=8),
        axis.title.y = element_text(size=8), axis.line.x=element_blank())

p3<- ggplot(data=pixels)+
  geom_boxplot(aes(x=TYPE, y=Ratio), outlier.shape = NA) +
  coord_cartesian(ylim = c(0, 10))+
  scale_y_continuous(labels = scales::number_format(accuracy = 0.1))+
  labs(y = 'VV / VH Ratio')+
  theme_classic()+
  theme(axis.title.x = element_blank(),axis.text = element_text(size=8),
        axis.title.y = element_text(size=8))

#Use these 3 for August
g1 <- ggplotGrob(p1)
g2 <- ggplotGrob(p2)
g3 <- ggplotGrob(p3)

#Repeat for January table after importing separately
g4 <- ggplotGrob(p1)
g5 <- ggplotGrob(p2)
g6 <- ggplotGrob(p3)

#Then draw the whole lot
grid::grid.newpage()
grid::grid.draw(gtable_cbind(gtable_rbind(g1, g2, g3), gtable_rbind(g4, g5, g6)))

pixelsSummary = pixels %>% select(-REGION_COD)%>%
  group_by(TYPE)%>%
  summarise_all(funs(mean,sd))

write.csv(pixelsSummary,file.path(wd,'summaryPixelsJan.csv'))



