# import pakages
library(Seurat)
library(Signac)
library(GenomeInfoDb)

devtools::install_github("hmatsu1226/SCODE")



# read 10X data
inputdata.10x <- Read10X_h5("") #Your data path

# extract RNA and ATAC data
rna_counts <- inputdata.10x$`Gene Expression`
atac_counts <- inputdata.10x$Peaks

# Filter ATAC data
atac_counts <- atac_counts[grep("chr", rownames(atac_counts)), ]

# Create seurat objects
obj.rna <- CreateSeuratObject(counts = rna_counts)
obj.rna[["percent.mt"]] <- PercentageFeatureSet(obj.rna, pattern = "^MT-")

# Create ChromatinAssay 
chrom_assay <- CreateChromatinAssay(
  counts = atac_counts,
  sep = c(":", "-"),
  min.cells = 1,
  genome = 'hg38',
  fragments = ' '#Your own path
)

# Create Seurat object
obj.atac <- CreateSeuratObject(
  counts = chrom_assay,
  assay = "ATAC"
)

Rscript SCODE.R data out 100 4 356 100