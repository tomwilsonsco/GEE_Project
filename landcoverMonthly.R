wd = 'C:/Users/tom/Documents/Data Science MSc/Project/Results/exportedEEResults'

#monthly = read.csv(file.path(wd, 's1MonthlyAllSamples.csv'))
monthly = read.csv(file.path(wd, 's1Monthly1stQuartileAllSamples.csv'))

monthly = monthly %>% mutate(date = paste0('01-', date))

monthly$date <- as.Date(monthly$date, '%d-%m-%Y')

monthly$TYPE <- factor(monthly$TYPE, levels=c('broadleaved', 'conifer', 'mixed_trees', 'young','felled','open'))

monthly_sum = monthly %>% group_by(TYPE, date) %>% summarise_all(median)

plotTheme = 
       theme_bw() + 
       theme(legend.position = "none", legend.title=element_blank(),axis.text.x = element_text(angle = 90, hjust = 1, size =8),
       axis.text.y = element_text(size=8), axis.title=element_text(size=8), legend.text=element_text(size=8))


p1<-ggplot()+
  geom_line(data=monthly_sum, aes(x=date, y=VV, colour=TYPE), size=1.05)+
  labs(y='VV (dB)')+
  scale_color_manual(values=c("#66ff33", "#006600", "#cc9900","#ffff00","#0066cc","#ff0000"))+
  scale_x_date(expand=c(0,0), limits= as.Date(c('2016-10-01','2018-09-01')), date_breaks = "2 months", date_labels ="%m-%Y")+
  scale_y_continuous(limits=c(-14.5, -11.5))+
  plotTheme+
  theme(legend.position ="top",legend.margin=margin(c(0,0,-10,0)), axis.text.x = element_blank(), axis.ticks.x.bottom =element_blank(), axis.title.x=element_blank())+
  guides(colour=guide_legend(nrow=1,byrow=TRUE))
  
p2<-ggplot()+
  geom_line(data=monthly_sum, aes(x=date, y=VH, colour=TYPE), size=1.05)+
  labs(y='VH (dB)')+
  scale_color_manual(values=c("#66ff33", "#006600", "#cc9900","#ffff00","#0066cc","#ff0000"))+
  scale_x_date(expand=c(0,0), limits= as.Date(c('2016-10-01','2018-09-01')), date_breaks = "2 months", date_labels ="%m-%Y")+
  plotTheme+
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank(), axis.title.x=element_blank())


p3<-ggplot()+
  geom_line(data=monthly_sum, aes(x=date, y=Ratio, colour=TYPE), size=1.05)+
  labs(x='Month / year', y='Ratio VV/VH')+
  scale_color_manual(values=c("#66ff33", "#006600", "#cc9900","#ffff00","#0066cc","#ff0000"))+
  scale_x_date(expand=c(0,0), limits= as.Date(c('2016-10-01','2018-09-01')), date_breaks = "2 months", date_labels ="%m-%Y")+
  plotTheme

grid.newpage()
grid.draw(rbind(ggplotGrob(p1), ggplotGrob(p2),ggplotGrob(p3), size = "last"))

#grid.arrange(p1,p2,p3)

####Summarise with 'dry' 1st Quartile and normal median
#switch above to read regular as monthly
monthly2 = read.csv(file.path(wd, 's1Monthly1stQuartileAllSamples.csv'))

monthly2 = monthly2 %>% mutate(date = paste0('01-', date))
monthly2$date <- as.Date(monthly2$date, '%d-%m-%Y')
monthly2$TYPE <- factor(monthly2$TYPE, levels=c('broadleaved', 'conifer', 'mixed_trees', 'young','felled','open'))
monthly_sum2 = monthly2 %>% group_by(TYPE, date) %>% summarise_all(median)


felled1 = monthly_sum %>% filter(TYPE =='felled')
felled1= felled1 %>% setNames(paste0('felled_', names(.)))
conifer1 = monthly_sum %>% filter(TYPE =='conifer')
conifer1= conifer1 %>% setNames(paste0('conifer_', names(.)))

felledCon = felled1 %>% inner_join(conifer1, by= c('felled_date'='conifer_date')) %>%
  mutate(vvDiff1 = felled_VV- conifer_VV, vhDiff1 = felled_VH - conifer_VH, ratioDiff1 = felled_Ratio - conifer_Ratio)%>%
  ungroup()%>%
  select(felled_date, vvDiff1, vhDiff1, ratioDiff1)  
  

felled2 = monthly_sum2 %>% filter(TYPE =='felled')
felled2= felled2 %>% setNames(paste0('felled2_', names(.)))
conifer2 = monthly_sum2 %>% filter(TYPE =='conifer')
conifer2= conifer2 %>% setNames(paste0('conifer2_', names(.)))

felledCon2 = felled2 %>% inner_join(conifer2, by= c('felled2_date'='conifer2_date')) %>%
  mutate(vvDiff2 = felled2_VV- conifer2_VV, vhDiff2 = felled2_VH - conifer2_VH, ratioDiff2 = felled2_Ratio - conifer2_Ratio)%>%
  ungroup()%>%
  select(felled2_date, vvDiff2, vhDiff2, ratioDiff2)  

felledCon = felledCon %>% inner_join(felledCon2, by=c('felled_date' ='felled2_date'))%>%
  mutate(vvImpact = vvDiff2 - vvDiff1, vhImpact = vhDiff2 -vhDiff1, ratioImpact = ratioDiff2 - ratioDiff1)

write.csv(felledCon, file.path(wd, 'felledConSeparation.csv'))

