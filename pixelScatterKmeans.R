wd = 'C:/Users/tom/Documents/Data Science MSc/Project/Results/exportedEEResults'

pixels <- read.csv(file.path(wd,'s1DistributionAllSamplesJan2018.csv'), stringsAsFactors = FALSE)

pixels = pixels %>% mutate(Ratio = VV - VH)

pixels = pixels %>% mutate(TYPE= ifelse(TYPE=='mixed_trees','mixed trees', TYPE))

pixels_plot = pixels %>% group_by(TYPE) %>% sample_n(1000)

pixels = pixels %>% mutate(Ratio = VV - VH)

testTable = pixels %>% filter(TYPE %in% c('broadleaved', 'open')) %>%
          group_by(TYPE) %>% sample_n(1000) %>% ungroup()

inputTable =testTable %>%select(-REGION_COD,-TYPE)

k=kmeans(inputTable,2)

testTable$cluster <- factor(k$cluster)

testTable = testTable%>%mutate(actual = if_else(TYPE=='broadleaved',1,2))

testTable$actual <- factor(testTable$actual)

testTable %>% group_by(TYPE, cluster) %>% summarise(count=n())

caret::confusionMatrix(testTable$actual, testTable$cluster)

centres = data.frame(k$centers)

testTable %>%
  ggplot()+
  geom_jitter(aes(x=VV, y=VH, colour=TYPE), size=0.7)+
  geom_point(data=centres, aes(x=VV, y=VH), size=2, colour='black', shape=17)+
  labs(x='VV (dB)', y='VH (dB)')+
  coord_cartesian(xlim = c(-15, -6), ylim=c(-21,-12))+
  theme_bw()+
  theme(legend.title=element_blank(), axis.text=element_text(size=8),
        axis.title=element_text(size=8), legend.text=element_text(size=8))+
  guides(colour = guide_legend(override.aes = list(size=2)))