library(ggplot2)
library(dplyr)
library(e1071)

wd = 'C:/Users/tom/Documents/Data Science MSc/Project/Results/exportedEEResults'

pixels <- read.csv(file.path(wd,'KielderPixelSample.csv'), stringsAsFactors = FALSE)

pixels = pixels %>% mutate(TYPE = if_else(TYPE_CODE==0,'Mature trees','Felled'))
pixels = pixels %>% sample_n(500)

svmTrain = pixels %>% select(VVasc,VHasc,TYPE)

svmTrain = svmTrain %>% rename(VV_dB=VVasc, VH_dB=VHasc)

svmTrain$TYPE <- as.factor(svmTrain$TYPE)

svmfit = svm(TYPE ~ ., data = svmTrain, kernel = "linear", cost = 10, scale = FALSE)
print(svmfit)


plot(svmfit, svmTrain, svSymbol = 1, dataSymbol = 1, symbolPalette = rainbow(8),
     color.palette = topo.colors, main="")



