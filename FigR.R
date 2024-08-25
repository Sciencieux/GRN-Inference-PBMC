devtools::install_github("buenrostrolab/FigR")
library(Seurat)
library(Signac)
library(GenomeInfoDb)
library(Pando)
library(EnsDb.Hsapiens.v86)
#You need a SummarizedExperiment object of the scATAC-seq reads in peaks counts (peaks x cells)
#And a sparseMatrix object of the scRNA-seq gene counts (genes x cells) that are paired
# Run using multiple cores if parallel support
cisCor <- runGenePeakcorr(ATAC.se = ATAC.SE,
                          RNAmat = rnaMat,
                          genome = "hg19", # Also supports mm10 and hg38
                          nCores = 4, 
                          p.cut=NULL)

# Filter peak-gene correlations by p-value                    
cisCor.filt <- cisCor %>% filter(pvalZ <= 0.05)

# Determine DORC genes
dorcGenes <- cisCor.filt %>% dorcJPlot(cutoff=7, # Default
                                       returnGeneList = TRUE)

# Get DORC scores
dorcMat <- getDORCScores(ATAC.SE,dorcTab=cisCor.filt,geneList=dorcGenes,nCores=4)

# Smooth DORC scores (using cell KNNs)
dorcMat.smooth <- smoothScoresNN(NNmat=cellKNN.mat,mat=dorcMat,nCores=4)

# Run FigR
fig.d <- runFigRGRN(ATAC.se=,ATAC.SE,
                    rnaMat=rnaMat.smooth, # Smoothed RNA matrix using paired cell kNNs
                    dorcMat=dorcMat.smooth,
                    dorcTab=cisCor.filt,
                    genome="hg19",
                    dorcGenes=dorcGenes,
                    nCores=4)

# Visualize all TF-DORC regulation scores (Scatter plot)
require(ggplot2)
require(ggrastr)
require(BuenColors) # https://github.com/caleblareau/BuenColors

fig.d %>% ggplot(aes(Corr.log10P,Enrichment.log10P,color=Score)) +
  geom_point_rast(size=0.01,shape=16) + 
  theme_classic() +
  scale_color_gradientn(colours = jdb_palette("solar_extra"),limits=c(-4,4),oob = scales::squish)


