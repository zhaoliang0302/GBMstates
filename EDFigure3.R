### ED Figure 3a

### All Datasets 192 pathways
source("functions.R")

library(openxlsx)
ppathSurv <- read.xlsx("tables/Supplementary Table 6.xlsx", startRow = 3, sheet = 2)
ppathSurv <- ppathSurv$Pathway

#Dataset 1
load("RData/Dataset1_geData.RData", verbose = T)
load("RData/Dataset1_pData.RData", verbose = T)
load("RData/Dataset1_NESActivity_HallmarksGOKegg.RData", verbose = T)
NES <- NES[rownames(NES) %in% ppathSurv, ]
Dataset1 <- list(geData = geData, pData = pData, NES = NES)

#Dataset 2
load("RData/Dataset2_geData.RData", verbose = T)
load("RData/Dataset2_pData.RData", verbose = T)
load("RData/Dataset2_NESActivity_HallmarksGOKegg.RData", verbose = T)
NES <- NES[rownames(NES) %in% ppathSurv, ]
Dataset2 <- list(geData = geData, pData = pData, NES = NES)

#Dataset 3
load("RData/Dataset3_geData.RData", verbose = T)
load("RData/Dataset3_pData.RData", verbose = T)
load("RData/Dataset3_NESActivity_HallmarksGOKegg.RData", verbose = T)
NES <- NES[rownames(NES) %in% ppathSurv, ]
Dataset3 <- list(geData = geData, pData = pData, NES = NES)

dataList <- list(Dataset1 = Dataset1, Dataset2 = Dataset2, Dataset3 = Dataset3)

library(yaGST)
GO <- gmt2GO("RData/HallmarksGoKegg.gmt")

ppath <- "integrated192"

library(doParallel)
scBiPaD(dataList, GO, nCores = 32, ppath = ppath)


load("integrated192/aConsensus_allClusters.RData", verbose = T)

consMatrix <- as.matrix(1 - aConsensus$consensus.diss)
diag(consMatrix) <- 1
consMatrix <- consMatrix[consHc$labels, consHc$labels[consHc$order]]

levels(consClust) <- c("red", "blue", "green3", "cyan")
RowSideColors <- as.character(consClust[colnames(consMatrix)])

library(heatmap3)
heatmap3(t(consMatrix),
         col = colorRampPalette(c("lemonchiffon2", "#053061"))(51),
         scale = "none",
         Colv = rev(as.dendrogram(consHc)),
         Rowv = NA,
         labCol = NA,
         labRow = NA,
         cexRow = 0.5,
         RowSideColors = RowSideColors,
         RowSideLabs = NA)


###ED Figure 3b
source("functions.R")

load("integrated192/aMwwGSTs_allClusters.RData", verbose = T)
load("integrated192/aConsensus_allClusters.RData", verbose = T)
levels(consClust) <- c("red", "blue", "green3", "cyan")

levels(consClust)
levels(consClust) <- c("Glycolytic", "Neuronal", "Mitochondrial", "Proliferative")

tmp <- as.character(consClust)
names(tmp) <- names(consClust)
consClust <- tmp

consClust <- consClust[consHc$labels[consHc$order]][length(consClust):1]
consClust <- c(consClust[consClust == "Glycolytic"], consClust[consClust == "Mitochondrial"], consClust[consClust == "Neuronal"], consClust[consClust == "Proliferative"])

NES_allClusters <- NES_allClusters[, names(consClust)]

aDEA <- DEAgroups(ddata = NES_allClusters, groups = consClust, method = "MWW")
aDEA <- lapply(aDEA, function(x){
  x <- x[x$logFC > 0.3 & x$qValue < 0.0001, ]
  x <- x[order(x$pValue), ]
  x <- x[order(x$logFC, decreasing = T), ]
  return(x)
})
aDEA <- lapply(aDEA, rownames)

allPath <- as.character(unlist(aDEA))
dup <- sort(unique(allPath[duplicated(allPath)]))
allPath <- allPath[!allPath %in% dup]
aDEA <- lapply(aDEA, function(x) x[x %in% allPath])

toPlot <- NES_allClusters[allPath, ]

classCol <- c("green3", "red", "blue", "cyan")
names(classCol) <- c("Mitochondrial", "Glycolytic", "Neuronal", "Proliferative")

ColSideColors <- classCol[consClust]

RowSideColors <- rep("red", length(allPath))
RowSideColors[allPath %in% aDEA$Mitochondrial] <- "green3"
RowSideColors[allPath %in% aDEA$Neuronal] <- "blue"
RowSideColors[allPath %in% aDEA$Proliferative] <- "cyan"

toPlot <- (toPlot - rowMeans(toPlot))/apply(toPlot, 1, sd)

toPlot[toPlot <= quantile(toPlot, 0.15)] <- quantile(toPlot, 0.15)
toPlot[toPlot >= quantile(toPlot, 0.85)] <- quantile(toPlot, 0.85)

library(heatmap3)
library(gplots)
heatmap3(toPlot[nrow(toPlot):1, ], showRowDendro = F, showColDendro = F,
         Rowv = NA,
         Colv = NA,
         ColSideColors = ColSideColors, ColSideLabs = NA,
         RowSideColors = RowSideColors[nrow(toPlot):1], RowSideLabs = NA,
         col = colorRampPalette(c("#053061", "#4393C3", "cornsilk", "#D6604D", "#67001F"))(75),
         labCol = NA,
         labRow = NA,
         cexCol = 0.5,
         cexRow = 0.6,
         scale = 'none', useRaster = F)
