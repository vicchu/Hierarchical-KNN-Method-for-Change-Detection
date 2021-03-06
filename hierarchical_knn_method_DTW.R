###################################################################################
# The hierarchical k-nearest neighbour method for Change Detection on MODIS Data  #
# Author: Zexi Chen                                                               #
# Date: 01/17/2016                                                                #
# #################################################################################

library(lattice)
library(utils)  # read csv file
library(MASS)
library(car)
library(data.table)
library(class)
library(dtw)

setwd("C:\\Users\\czx\\Google Drive\\Research\\From professor\\Not_published_yet\\")

mydtw <- function(x,y,w=1){
  mymat = matrix(Inf,length(x)+1,length(y)+1)
  
  mymat[1,1]=0
  
  for(i in seq(2,length(x)+1)){
    low = max(2,i-w)
    upper = min(length(y)+1,i+w)
    for(j in seq(low,upper)){
      cost = abs((x[i-1]-y[j-1]))
      minvalue = min(mymat[i-1,j],mymat[i,j-1],mymat[i-1,j-1])
      mymat[i,j]=cost[1]+ minvalue
    }
  }
  return(mymat[length(x)+1,length(y)+1])
}

trainData1 = read.table("gt06d.txt", header=T, sep=",")
trainData2 = read.table("gt11d.txt", header=T, sep=",")

trainData = rbind(trainData1,trainData2)
#trainData = read.table("data\\sampling_1000_col_s.txt", header=T, sep=" ")

#remove the column of the label
trainData = trainData[,-24]

#minClusters = 2
#maxClusters = 8

#calculate the proximity matrix
#proxMatrix = dist(trainData, method = "euclidean") 

proxMatrix <- dist(trainData, method="euclidean")

index = 1
for(i in seq(1,dim(trainData)[1])){
  j = i+1
  while(j<=dim(trainData)[1]){
    a = as.vector(unlist(trainData[i,]))
    b = as.vector(unlist(trainData[j,]))
    proxMatrix[index] = mydtw(a,b)
    index = index+1
    j = j+1
  }
}

# buid the hierarchical clustering model
hc = hclust(proxMatrix, method = "ward.D2")
plot(hc)

# choose the number of clusters we wan, so we can cut the tree at the desired level.
#numClusters = 8

minClusters = 2
maxClusters = 8

# cut the tree 

labels= cutree(hc,k=minClusters:maxClusters)
labels_new = unique(labels)


clusteringResult = cbind(trainData,labels[,maxClusters-minClusters+1])

#testData = c(226,217,90,226,243,237,242,202,229,224,242,238,239,233,232,236,242,220,228,101,240,207,173)
#testData1 = c(251,232,219,238,223,218,233,204,228,227,223,232,235,234,237,234,235,229,200,157,235,206,253)
#result = knn(trainData,testData1,label,k=3)

write.table(clusteringResult,file = "data\\DTW\\hierarchical_clustering_result_DTW_172.txt",row.names = FALSE, col.names=FALSE)
write.table(labels_new,file="data\\DTW\\hierarchical_clustering_labels_2_8_DTW_172.txt",row.names = FALSE, col.names=FALSE)





#write.table(clusteringResult,file = "hierarchical_clustering_result_DTW.txt",row.names = FALSE, col.names=FALSE)

dirpath = "C:\\Users\\czx\\Google Drive\\MODIS data\\"
datapath = paste(dirpath, "s_2001.raw", sep="")

#trainData1 = read.table(datapath, header=T, sep=",")
DT = data.table(read.table(datapath,nrows = 1),fileEncoding = "UTF-8")
DT = readBin(datapath,size=1,signed=FALSE,what="character")
x<- as.u_char(utf8ToInt(DT))


/'
for(i in 1:10){
  sampling = trainData[sample(1:nrow(trainData),i*100),]
  proxMatrix = dist(sampling, method = "euclidean") 
  hc = hclust(proxMatrix, method = "ward.D2")
  
  labels= cutree(hc,k=minClusters:maxClusters)
  labels_new = unique(labels)
  
  clusteringResult = cbind(sampling,labels[,maxClusters-minClusters+1])
  
  filename1 = paste("data\\hierarchical_clustering_result_Euclidean_sample_",i*100,".txt",sep="")
  filename2 = paste("data\\hierarchical_clustering_labels_2_8_sample_",i*100,".txt",sep="")
  
  write.table(clusteringResult,file = filename1,row.names = FALSE, col.names=FALSE)
  write.table(labels_new,file=filename2,row.names = FALSE, col.names=FALSE)
  
}
'/

