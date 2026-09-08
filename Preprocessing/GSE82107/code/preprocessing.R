if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}

BiocManager::install("affy")
BiocManager::install("limma")


project_dir <- "C:/Users/bilal/OneDrive/FYP/FYP-preprocessing"
setwd(project_dir)
getwd()

list.files(project_dir)
cel_dir <- file.path(project_dir, "GSE82107", "raw", "GSE82107_RAW")
list.files(cel_dir)

library(affy)
install.packages("BiocManager")
BiocManager::install("affy")

library(affy)
#1 — Read the CEL files
raw_data <- ReadAffy(celfile.path = cel_dir)
raw_data
length(sampleNames(raw_data))
sampleNames(raw_data)


#2.Raw QC (Quality Control)

boxplot(raw_data,
        main = "GSE82107 Raw Expression",
        las = 2)

hist(raw_data,
     main = "GSE82107 Raw Expression Distribution",
     col = "lightblue")


#Step 3 — RLE and NUSE QC

BiocManager::install("affyPLM")
library(affyPLM)
Pset <- fitPLM(raw_data)

library(affy)
library(affyPLM)
project_dir <- "C:/Users/bilal/OneDrive/FYP/FYP-preprocessing"
dir.exists(project_dir)
cel_dir <- file.path(
  project_dir,
  "GSE82107",
  "raw",
  "GSE82107_RAW"
)
length(list.files(cel_dir, pattern = "\\.CEL\\.gz$", ignore.case = TRUE))
raw_data <- ReadAffy(celfile.path = cel_dir)
Pset <- fitPLM(raw_data)
RLE(Pset)
NUSE(Pset)

RLE(Pset,
    main = "GSE82107 - RLE Plot")
NUSE(Pset,
     main = "GSE82107 - NUSE Plot")


#Step 4 — Sample correlation

#4.1 Extract the raw expression values
expr_raw <- exprs(raw_data)
dim(expr_raw)
#Calculate correlation
cor_matrix <- cor(expr_raw, method = "pearson")
#4.3 View the correlation matrix
round(cor_matrix, 2)
#4.4 Make a heatmap
heatmap(cor_matrix,
        main = "GSE82107 Sample Correlation",
        symm = TRUE)


#Step 5: PCA
pca <- prcomp(t(expr_raw), scale. = TRUE)



metadata <- read.csv(
  file.path(project_dir, "GSE82107", "metadata", "GSE82107_metadata.csv"),
  stringsAsFactors = FALSE
)
metadata$Group
group <- metadata$Group[
  match(sampleNames(raw_data), metadata$Sample_ID)
]
group


gsm_ids <- sub("_.*", "", sampleNames(raw_data))
gsm_ids
group <- ifelse(
  gsm_ids %in% paste0("GSM", 2183532:2183538),
  "Control",
  "OA"
)
table(group)
data.frame(GSM = gsm_ids, Group = group)

plot(pca$x[,1],
     pca$x[,2],
     xlab = "PC1",
     ylab = "PC2",
     main = "GSE82107 Raw PCA",
     pch = 19,
     col = ifelse(group == "OA", "red", "black"))

text(pca$x[,1],
     pca$x[,2],
     labels = gsm_ids,
     pos = 3,
     cex = 0.6)

legend("topright",
       legend = c("Control", "OA"),
       col = c("black", "red"),
       pch = 19)

#Step 6 — RMA normalization
norm_data <- rma(raw_data)
expr_norm <- exprs(norm_data)
dim(expr_norm)
boxplot(expr_norm,
        main = "GSE82107 RMA Normalized Expression",
        las = 2)
plotDensity(norm_data,main = "GSE82107 RMA Normalized Expression")
dir.create(
  file.path(project_dir, "GSE82107", "results"),
  showWarnings = FALSE
)
saveRDS(
  norm_data,
  file.path(
    project_dir,
    "GSE82107",
    "results",
    "GSE82107_RMA_normalized.rds"
  )
)
write.csv(
  expr_norm,
  file.path(
    project_dir,
    "GSE82107",
    "results",
    "GSE82107_RMA_expression.csv"
  )
)
norm_data <- rma(raw_data)
dim(exprs(norm_data))

#Step7: post normalziation
boxplot(expr_norm,
        main = "GSE82107 RMA Normalized Expression",
        las = 2)
plotDensity(norm_data,
            main = "GSE82107 RMA Normalized Expression")

library(affy)
project_dir <- "C:/Users/bilal/OneDrive/FYP/FYP-preprocessing"

cel_dir <- file.path(
  project_dir,
  "GSE82107",
  "raw",
  "GSE82107_RAW"
)
pca_norm <- prcomp(t(expr_norm), scale. = TRUE)
norm_data
raw_data <- ReadAffy(celfile.path = cel_dir)
length(sampleNames(raw_data))
project_dir <- "C:/Users/bilal/OneDrive/FYP/FYP-preprocessing"

cel_dir <- file.path(
  project_dir,
  "GSE82107",
  "raw",
  "GSE82107_RAW"
)

library(affy)

raw_data <- ReadAffy(celfile.path = cel_dir)

norm_data <- rma(raw_data)

expr_norm <- exprs(norm_data)
pca_norm <- prcomp(t(expr_norm), scale. = TRUE)
# Post-RMA PCA plot

plot(
  pca_norm$x[,1],
  pca_norm$x[,2],
  xlab = "PC1",
  ylab = "PC2",
  main = "GSE82107 Post-RMA PCA",
  pch = 19,
  col = ifelse(group == "OA", "red", "black")
)

text(
  pca_norm$x[,1],
  pca_norm$x[,2],
  labels = gsm_ids,
  pos = 3,
  cex = 0.6
)

legend(
  "topright",
  legend = c("Control", "OA"),
  col = c("black", "red"),
  pch = 19
)

#Step Differential Expression Analysis (DEA)
library(limma)
# Check the column names first
colnames(design)
colnames(design) <- c("groupControl","groupOA")
design <- model.matrix(~0 + group)
colnames(design) <- c("Control", "OA")

design
contrast_matrix <- makeContrasts(
  OA - Control,
  levels = design
)

contrast_matrix

fit <- lmFit(expr_norm, design)

fit2 <- contrasts.fit(fit, contrast_matrix)

fit2 <- eBayes(fit2)


#Step9: Extract Differentially Expressed Genes (DEGs)
deg_results <- topTable(
  fit2,
  coef = 1,
  number = Inf,
  adjust.method = "BH"
)

head(deg_results)
sum(deg_results$adj.P.Val < 0.05)
deg_sig <- deg_results[
  deg_results$adj.P.Val < 0.05 &
    abs(deg_results$logFC) >= 1,
]

nrow(deg_sig)
# Top 20 genes
deg_results[1:20, c("logFC", "P.Value", "adj.P.Val", "B")]
# Genes with raw p-value < 0.05
deg_p05 <- deg_results[deg_results$P.Value < 0.05, ]

nrow(deg_p05)
results_dir <- file.path(project_dir, "GSE82107", "results")

dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)
write.csv(
  deg_results,
  file.path(results_dir, "GSE82107_all_DEGs.csv"),
  row.names = TRUE
)
write.csv(
  deg_sig,
  file.path(results_dir, "GSE82107_significant_DEGs.csv"),
  row.names = TRUE
)
