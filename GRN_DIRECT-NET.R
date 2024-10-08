#Reference: https://htmlpreview.github.io/?https://github.com/zhanglhbioinfor/DIRECT-NET/blob/main/tutorial/demo_DIRECTNET_PBMC.html

library(DIRECTNET)
library(Seurat)
library(Signac)
library(EnsDb.Hsapiens.v86)
library(patchwork)
library(dplyr)
library(ggplot2)
options(stringsAsFactors = FALSE)

library(hdf5r)
#> 
#> Attaching package: 'hdf5r'
#> The following object is masked from 'package:GenomicRanges':
#> 
#>     values
#> The following object is masked from 'package:S4Vectors':
#> 
#>     values
inputdata.10x <- Read10X_h5("./pbmc_granulocyte_sorted_10k_filtered_feature_bc_matrix.h5")# Your own data path
#> Genome matrix has multiple modalities, returning a list of matrices for this genome
# extract RNA and ATAC data
rna_counts <- inputdata.10x$`Gene Expression`
atac_counts <- inputdata.10x$Peaks

genome.info <- read.table(file = "./pbmc_granulocyte_sorted_10k_filtered_feature_bc_matrix.h5")#Your own data path
names(genome.info) <- c("Chrom","Starts","Ends","genes")
genes <- lapply(genome.info$genes, function(x) strsplit(x,"[|]")[[1]][1])
genes <- lapply(genes, function(x) strsplit(x,"[.]")[[1]][1])
genes <- unlist(genes)
genome.info$genes <- genes
unik <- !duplicated(genes)# filter out different transcript
genome.info <- genome.info[unik,]

# Create Seurat object
pbmc <- CreateSeuratObject(counts = rna_counts)
pbmc[["percent.mt"]] <- PercentageFeatureSet(pbmc, pattern = "^MT-")

# Now add in the ATAC-seq data
# we'll only use peaks in standard chromosomes
grange.counts <- StringToGRanges(rownames(atac_counts), sep = c(":", "-"))
grange.use <- seqnames(grange.counts) %in% standardChromosomes(grange.counts)
atac_counts <- atac_counts[as.vector(grange.use), ]
annotations <- GetGRangesFromEnsDb(ensdb = EnsDb.Hsapiens.v86)
seqlevelsStyle(annotations) <- 'UCSC'
genome(annotations) <- "hg38"

frag.file <- "./pbmc_granulocyte_sorted_10k_atac_fragments.tsv.gz" #Your own data path
chrom_assay <- CreateChromatinAssay(
  counts = atac_counts,
  sep = c(":", "-"),
  genome = 'hg38',
  fragments = frag.file,
  min.cells = 10,
  annotation = annotations
)
pbmc[["ATAC"]] <- chrom_assay

#VlnPlot(pbmc, features = c("nCount_ATAC", "nCount_RNA","percent.mt"), ncol = 3,
#        log = TRUE, pt.size = 0) + NoLegend()

pbmc <- subset(
  x = pbmc,
  subset = nCount_ATAC < 7e4 &
    nCount_ATAC > 5e3 &
    nCount_RNA < 25000 &
    nCount_RNA > 1000 &
    percent.mt < 20
)

DefaultAssay(pbmc) <- "RNA"
pbmc <- SCTransform(pbmc, verbose = FALSE) %>% RunPCA() %>% RunUMAP(dims = 1:50, reduction.name = 'umap.rna', reduction.key = 'rnaUMAP_')

# We exclude the first dimension as this is typically correlated with sequencing depth
DefaultAssay(pbmc) <- "ATAC"
pbmc <- RunTFIDF(pbmc)
#> Performing TF-IDF normalization
pbmc <- FindTopFeatures(pbmc, min.cutoff = 'q0')
pbmc <- RunSVD(pbmc)
#> Running SVD
#> Scaling cell embeddings
pbmc <- RunUMAP(pbmc, reduction = 'lsi', dims = 2:50, reduction.name = "umap.atac", reduction.key = "atacUMAP_")
pbmc <- FindMultiModalNeighbors(pbmc, reduction.list = list("pca", "lsi"), dims.list = list(1:50, 2:50))
#> Calculating cell-specific modality weights
#> Finding 20 nearest neighbors for each modality.
#> Calculating kernel bandwidths
#> Finding multimodal neighbors
#> Constructing multimodal KNN graph
#> Constructing multimodal SNN graph
pbmc <- RunUMAP(pbmc, nn.name = "weighted.nn", reduction.name = "wnn.umap", reduction.key = "wnnUMAP_")
pbmc <- FindClusters(pbmc, graph.name = "wsnn", algorithm = 3, verbose = FALSE)

# perform sub-clustering on cluster 6 to find additional structure
pbmc <- FindSubCluster(pbmc, cluster = 6, graph.name = "wsnn", algorithm = 3)

Idents(pbmc) <- "sub.cluster"
# add annotations
pbmc <- RenameIdents(pbmc, '19' = 'pDC','20' = 'HSPC','15' = 'cDC')
pbmc <- RenameIdents(pbmc, '0' = 'CD14 Mono', '9' ='CD14 Mono', '5' = 'CD16 Mono')
pbmc <- RenameIdents(pbmc, '17' = 'Naive B', '11' = 'Intermediate B', '10' = 'Memory B', '21' = 'Plasma')
pbmc <- RenameIdents(pbmc, '7' = 'NK')
pbmc <- RenameIdents(pbmc, '4' = 'CD4 TEM', '13'= "CD4 TCM", '3' = "CD4 TCM", '16' ="Treg", '1' ="CD4 Naive", '14' = "CD4 Naive")
pbmc <- RenameIdents(pbmc, '2' = 'CD8 Naive', '8'= "CD8 Naive", '12' = 'CD8 TEM_1', '6_0' = 'CD8 TEM_2', '6_1' ='CD8 TEM_2')
pbmc <- RenameIdents(pbmc, '18' = 'MAIT')
pbmc <- RenameIdents(pbmc, '6_2' ='gdT', '6_3' = 'gdT')

pbmc$celltype <- Idents(pbmc) 
p1 <- DimPlot(pbmc, reduction = "umap.rna", group.by = "celltype", label = TRUE, label.size = 2.5, repel = TRUE) + ggtitle("RNA")
p2 <- DimPlot(pbmc, reduction = "umap.atac", group.by = "celltype", label = TRUE, label.size = 2.5, repel = TRUE) + ggtitle("ATAC")
p3 <- DimPlot(pbmc, reduction = "wnn.umap", group.by = "celltype", label = TRUE, label.size = 2.5, repel = TRUE) + ggtitle("WNN")
p1 + p2 + p3 & NoLegend() & theme(plot.title = element_text(hjust = 0.5))

library(presto)

markers_all <- presto:::wilcoxauc.Seurat(X = pbmc, group_by = 'celltype', assay = 'data', seurat_assay = 'SCT')
markers_all <- markers_all[which(markers_all$auc > 0.5), , drop = FALSE]
markers <- data.frame(gene = markers_all$feature, group = markers_all$group)
c <- unique(markers$group)
marker_list <- list()
for (i in 1:length(c)) {
  marker1<- markers_all[markers$group == c[i],]
  marker_list[[i]] <- as.character(marker1$feature[marker1$auc > 0.5])
}
markers_groups <- unique(unlist(marker_list))
markers_groups <- lapply(markers_groups, function(x) strsplit(x,"[.]")[[1]][1])
markers_groups <- unique(unlist(markers_groups))
# Infer links for markers: GLB1, TAF1B
pbmc <- Run_DIRECT_NET(pbmc, peakcalling = FALSE, k_neigh = 50, atacbinary = TRUE, max_overlap=0.5, size_factor_normalize = FALSE, genome.info = genome.info, focus_markers = c("GLB1","TAF1B"))

direct.net_result <- Misc(pbmc, slot = 'direct.net')
direct.net_result <- as.data.frame(do.call(cbind,direct.net_result)) # links for markers

# We have run DIRECT-NET on all markers, load the results for downstream network analysis load("./PBMC_direct.net.RData")
# check the function type name
direct.net_result$function_type <- gsub("HF","HC",direct.net_result$function_type)
direct.net_result$function_type <- gsub("Rest","MC",direct.net_result$function_type)
direct.net_result$function_type <- gsub("LF","LC",direct.net_result$function_type)

temp <- tempfile()
download.file("./Homo_sapiens.GRCh37.65.gtf.gz", temp)
gene_anno <- rtracklayer::readGFF(temp)
unlink(temp)
# rename some columns to match requirements
gene_anno$chromosome <- paste0("chr", gene_anno$seqid)
gene_anno$gene <- gene_anno$gene_id
gene_anno$transcript <- gene_anno$transcript_id
gene_anno$symbol <- gene_anno$gene_name

marker <- "GLB1"
Plot_connections(direct.net_result, gene_anno, marker, cutoff = 0.5, upstream = 100000, downstream = 10000)

maker_loci <- direct.net_result[which(direct.net_result$gene == "GLB1"), , drop = FALSE]
peak <- paste0(maker_loci$Chr[1],"-",maker_loci$Starts[1],"-",maker_loci$Ends[1])
pbmc_sub <- subset(pbmc,idents = c('CD4 TEM','CD4 TCM'))
CoveragePlot(
  object = pbmc_sub,
  region = peak,
  extend.upstream = 100000,
  extend.downstream = 10000
)

# identify differential accessible peaks (DA)
DefaultAssay(pbmc) <- 'ATAC'
focused_markers <- markers[which(markers$group %in% c("CD4 TEM", "CD4 TCM")), , drop = FALSE]
groups <- unique(focused_markers$group)
da_peaks_list <- list()
for (i in 1:length(groups)) {
  print(i)
  da_peaks <- FindMarkers(
    object = pbmc,
    min.pct = 0.2,
    logfc.threshold = 0.6,
    ident.1 = groups[i],
    group.by = "celltype",
    test.use = 'LR',
    only.pos = TRUE
  )
  da_peaks_list[[i]] <- da_peaks
}
#> [1] 1
#> [1] 2

# CRE-gene connections
CREs_Gene <- generate_CRE_Gene_links(direct.net_result, markers = focused_markers)
# Find focused CREs which is overlapped with DA
Focused_CREs <- generate_CRE(L_G_record = CREs_Gene$distal, P_L_G_record = CREs_Gene$promoter, da_peaks_list)
# detect TFs for distal CREs
library(BSgenome.Hsapiens.UCSC.hg38)
L_TF_record <- generate_peak_TF_links(peaks_bed_list = Focused_CREs$distal, species="Homo sapiens", genome = BSgenome.Hsapiens.UCSC.hg38, markers = focused_markers)
# detect TFs for Promoters
P_L_TF_record <- generate_peak_TF_links(peaks_bed_list = Focused_CREs$promoter, species="Homo sapiens", genome = BSgenome.Hsapiens.UCSC.hg38, markers = focused_markers)

network_links <- generate_links_for_Cytoscape(L_G_record = Focused_CREs$L_G_record, L_TF_record, P_L_G_record = Focused_CREs$P_L_G_record, P_L_TF_record,groups)

Node_attribute <- generate_node_for_Cytoscape(network_links,markers = focused_markers)