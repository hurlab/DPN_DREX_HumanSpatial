#!/usr/bin/env Rscript
################################################################################
# Script 09: Statistical Significance Analysis of Mouse-Human Schwann Overlaps
#
# Purpose: Calculate statistical significance of Mouse∩Schwann overlaps using
#          permutation testing
#
# Input: - Mouse DEG files (from DEG/ and DEG_Major/)
#        - Human Schwann DEG file
#        - Mouse background gene universe
#
# Output: - Overlap significance statistics (z-scores, p-values)
#         - Summary tables and visualizations
#         - Output directory: Output_JCI/09_Overlap_Significance/
################################################################################

# Load required packages
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(dplyr, tidyr, ggplot2, readr, homologene)

# Set working directory
# The DEG files are in the parent directory
deg_dir <- "../DEG_Major"
if (!dir.exists(deg_dir)) {
  stop(paste("Cannot find DEG_Major directory at:", deg_dir))
}

# Create output directory
output_dir <- "Output_JCI/09_Overlap_Significance"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

################################################################################
# Function: Calculate overlap significance using permutation test
################################################################################

calculate_overlap_significance <- function(gene_set1, gene_set2, background,
                                           background_size = NULL,
                                           n_perm = 10000, seed = 123) {
  set.seed(seed)

  # Extract gene names from background if it's a data frame
  if (is.data.frame(background)) {
    all_genes <- unique(background$Gene)
  } else {
    all_genes <- unique(background)
  }
  all_genes <- all_genes[all_genes != "" & !is.na(all_genes)]

  # Use specified background_size or default to detected genes
  if (is.null(background_size)) {
    background_size <- length(all_genes)
  }

  # Filter gene sets to background
  gene_set1_bg <- intersect(gene_set1, all_genes)
  gene_set2_bg <- intersect(gene_set2, all_genes)

  n1 <- length(gene_set1_bg)
  n2 <- length(gene_set2_bg)
  n_bg <- background_size  # Use the specified background size, not detected gene count

  if (n1 == 0 || n2 == 0) {
    warning("One or both gene sets have no overlap with the background.")
    return(list(
      observed_overlap = 0,
      expected_mean = NA,
      expected_sd = NA,
      z_score = NA,
      p_value = NA,
      enrichment_fold = NA,
      set1_size = n1,
      set2_size = n2,
      background_size = n_bg,
      null_distribution = NULL
    ))
  }

  # Calculate observed overlap
  observed <- length(intersect(gene_set1_bg, gene_set2_bg))

  # If background_size differs from detected genes, use analytical formula
  # (hypergeometric distribution) for more accurate expected values
  if (background_size != length(all_genes)) {
    cat("  Using analytical hypergeometric formula (background:", background_size, "genes)\n")

    # Expected overlap under hypergeometric distribution
    mean_null <- (n1 * n2) / background_size

    # Variance under hypergeometric: (n1*n2*(N-n1)*(N-n2)) / (N^2 * (N-1))
    N <- background_size
    variance_null <- (n1 * n2 * (N - n1) * (N - n2)) / (N^2 * (N - 1))
    sd_null <- sqrt(variance_null)

    # For p-value, use normal approximation
    nulls <- NULL  # No permutation distribution

  } else {
    # Standard permutation test when background matches detected genes
    cat("  Running", n_perm, "permutations...\n")
    nulls <- replicate(n_perm, {
      r1 <- sample(all_genes, n1, replace = FALSE)
      r2 <- sample(all_genes, n2, replace = FALSE)
      length(intersect(r1, r2))
    })

    # Calculate statistics
    mean_null <- mean(nulls)
    sd_null <- sd(nulls)
  }

  # Z-score (handle sd = 0 case)
  if (sd_null > 0) {
    z <- (observed - mean_null) / sd_null
  } else {
    z <- ifelse(observed > mean_null, Inf, 0)
  }

  # P-value calculation
  if (is.null(nulls)) {
    # Use normal approximation when using analytical formula
    p <- pnorm(z, lower.tail = FALSE)  # One-tailed test for enrichment
  } else {
    # Use permutation distribution
    p <- sum(nulls >= observed) / n_perm
    p <- max(p, 1/n_perm)  # Avoid p=0
  }

  # Enrichment fold change
  enrichment_fold <- observed / mean_null

  list(
    observed_overlap = observed,
    expected_mean = mean_null,
    expected_sd = sd_null,
    z_score = z,
    p_value = p,
    enrichment_fold = enrichment_fold,
    set1_size = n1,
    set2_size = n2,
    background_size = n_bg,
    null_distribution = nulls
  )
}

################################################################################
# Load Data
################################################################################

cat("Loading data...\n")

# Function to build human-to-mouse mapping
build_human_to_mouse_map <- function() {
  hom <- homologene::homologeneData
  human <- hom %>%
    dplyr::filter(Taxonomy == 9606) %>%
    dplyr::select(HID, Human_Symbol = Gene.Symbol)
  mouse <- hom %>%
    dplyr::filter(Taxonomy == 10090) %>%
    dplyr::select(HID, Mouse_Symbol = Gene.Symbol)
  dplyr::left_join(human, mouse, by = "HID", relationship = "many-to-many") %>%
    dplyr::filter(!is.na(Mouse_Symbol)) %>%
    dplyr::arrange(Human_Symbol) %>%
    dplyr::group_by(Human_Symbol) %>%
    dplyr::slice(1) %>%
    dplyr::ungroup() %>%
    dplyr::select(Human_Symbol, Mouse_Symbol)
}

mapping <- build_human_to_mouse_map()
cat("  Ortholog mapping:", nrow(mapping), "human-mouse gene pairs\n")

# Function to read human Schwann DEGs and map to mouse
read_schwann_deg <- function(file_path, mapping_tbl, padj_cutoff = 0.001, lfc_cutoff = 1) {
  df <- suppressWarnings(read.csv(file_path, stringsAsFactors = FALSE, check.names = FALSE))

  # Rename first column to "Gene" if it doesn't have a proper name
  if (!"Gene" %in% colnames(df)) colnames(df)[1] <- "Gene"

  # Normalize column names to lowercase with underscores
  cn <- tolower(gsub("\\s+", "_", colnames(df)))
  colnames(df) <- cn

  # Define column names
  gene_col <- "gene"
  padj_col <- if ("p_val_adj" %in% cn) "p_val_adj" else if ("padj" %in% cn) "padj" else stop("Cannot find padj in Schwann DEG file.")
  lfc_col <- if ("avg_log2fc" %in% cn) "avg_log2fc" else if ("log2foldchange" %in% cn) "log2foldchange" else stop("Cannot find log2FC in Schwann DEG file.")

  if (!gene_col %in% cn) stop("Cannot find gene name column")

  # Filter DEGs
  deg_df <- df
  if (!is.na(padj_col)) {
    deg_df <- deg_df %>% filter(.data[[padj_col]] < padj_cutoff)
  }
  if (!is.na(lfc_col)) {
    deg_df <- deg_df %>% filter(abs(.data[[lfc_col]]) > lfc_cutoff)
  }

  human_genes <- unique(deg_df[[gene_col]])
  human_genes <- human_genes[human_genes != "" & !is.na(human_genes)]

  # Map to mouse orthologs
  mouse_genes <- mapping_tbl %>%
    filter(Human_Symbol %in% human_genes) %>%
    pull(Mouse_Symbol) %>%
    unique()

  cat("    Human Schwann DEGs:", length(human_genes), "-> Mouse orthologs:", length(mouse_genes), "\n")
  return(mouse_genes)
}

# Read human Schwann DEGs
schwann_file <- "DEGs_JCI_DPN/SchwannDEG_Severe-Moderate_noMito.csv"
schwann_mouse <- read_schwann_deg(schwann_file, mapping)

# Function to read mouse DEG files
read_mouse_deg_file <- function(file_path, padj_cutoff = 0.01) {
  df <- suppressWarnings(read.csv(file_path, stringsAsFactors = FALSE, check.names = FALSE))

  # Rename first column to "gene" if it doesn't have a proper name
  if (!"gene" %in% tolower(colnames(df)) && (colnames(df)[1] == "" || is.na(colnames(df)[1]))) {
    colnames(df)[1] <- "gene"
  }

  # Normalize column names
  colnames(df) <- tolower(gsub("\\s+", "_", colnames(df)))

  # Find p-value column
  pval_col <- grep("^p_val$|^pval$", colnames(df), ignore.case = TRUE, value = TRUE)[1]
  padj_col <- grep("^p_val_adj$|^padj$|^adj_p", colnames(df), ignore.case = TRUE, value = TRUE)[1]
  gene_col <- "gene"

  if (!gene_col %in% colnames(df)) {
    gene_col <- colnames(df)[1]
  }

  # Use raw p-value (p_val) with cutoff 0.01
  if (!is.na(pval_col)) {
    deg_df <- df %>% filter(.data[[pval_col]] < padj_cutoff)
  } else if (!is.na(padj_col)) {
    deg_df <- df %>% filter(.data[[padj_col]] < padj_cutoff)
  } else {
    deg_df <- df
  }

  genes <- unique(deg_df[[gene_col]])
  genes <- genes[genes != "" & !is.na(genes)]
  return(genes)
}

# Get list of all mouse DEG files
deg_files <- list.files(deg_dir, pattern = "*.csv", full.names = TRUE)

# Extract comparison and cell type from filenames
file_info <- data.frame(
  file = deg_files,
  basename = basename(deg_files),
  stringsAsFactors = FALSE
) %>%
  mutate(
    comp_group = sub("_[^_]+\\.csv$", "", basename),
    cell_type = sub(".*_([^_]+)\\.csv$", "\\1", basename)
  )

cat("\nFound", nrow(file_info), "mouse DEG files\n")

# Load all mouse DEGs
mouse_degs <- lapply(seq_len(nrow(file_info)), function(i) {
  cat("  Loading:", file_info$basename[i], "\n")
  genes <- read_mouse_deg_file(file_info$file[i])
  cat("    Genes:", length(genes), "\n")
  return(genes)
})
names(mouse_degs) <- paste(file_info$comp_group, file_info$cell_type, sep = "_")

################################################################################
# Define Mouse Background Gene Universe
################################################################################

cat("\nDefining mouse background gene universe...\n")

# Approach: Use all protein-coding genes in the mouse genome (~20,000 genes)
# This is more conservative and represents the full genome-wide background

# Create a gene universe of 20,000 genes by combining:
# 1. All detected genes in our data
# 2. Additional genes from the detected set to reach 20,000 (or use exactly 20,000)

# First, get all unique detected genes
all_detected_genes <- unique(unlist(lapply(mouse_degs, function(x) x)))
all_detected_genes <- all_detected_genes[all_detected_genes != "" & !is.na(all_detected_genes)]

cat("  Detected genes in data:", length(all_detected_genes), "\n")

# Use 20,000 as the background size (full mouse genome)
# For sampling, we'll use the detected genes and resample to simulate 20k background
background_size <- 20000
all_mouse_genes <- all_detected_genes  # For actual gene names in sampling

cat("  Background size (genome):", background_size, "\n")
cat("  Human Schwann genes (mapped to mouse):", length(schwann_mouse), "\n")

# Verify overlap of Schwann genes with background
schwann_in_bg <- intersect(schwann_mouse, all_mouse_genes)
cat("  Schwann genes in mouse background:", length(schwann_in_bg),
    sprintf("(%.1f%%)\n", 100 * length(schwann_in_bg) / length(schwann_mouse)))

################################################################################
# Calculate Overlap Significance for All Comparisons
################################################################################

cat("\nCalculating overlap significance...\n")

results_list <- list()

for (i in seq_len(nrow(file_info))) {
  comp <- file_info$comp_group[i]
  cell <- file_info$cell_type[i]
  name <- paste(comp, cell, sep = "_")

  cat("\n", i, "/", nrow(file_info), ":", name, "\n")

  mouse_genes <- mouse_degs[[name]]

  # Calculate overlap
  overlap_genes <- intersect(mouse_genes, schwann_mouse)

  cat("  Mouse DEGs:", length(mouse_genes), "\n")
  cat("  Overlap with Schwann:", length(overlap_genes), "\n")

  # Skip if no overlap
  if (length(overlap_genes) == 0) {
    cat("  Skipping (no overlap)\n")
    next
  }

  # Calculate significance
  sig_result <- calculate_overlap_significance(
    gene_set1 = mouse_genes,
    gene_set2 = schwann_mouse,
    background = all_mouse_genes,
    background_size = background_size,  # Use 20,000 as genome-wide background
    n_perm = 10000,
    seed = 123
  )

  # Store results
  results_list[[name]] <- c(
    comparison = comp,
    cell_type = cell,
    sig_result[c("observed_overlap", "expected_mean", "expected_sd",
                 "z_score", "p_value", "enrichment_fold",
                 "set1_size", "set2_size", "background_size")]
  )

  cat("  Observed:", sig_result$observed_overlap, "\n")
  cat("  Expected:", round(sig_result$expected_mean, 2), "±", round(sig_result$expected_sd, 2), "\n")
  cat("  Z-score:", round(sig_result$z_score, 2), "\n")
  cat("  P-value:", signif(sig_result$p_value, 3), "\n")
  cat("  Enrichment:", round(sig_result$enrichment_fold, 2), "x\n")
}

################################################################################
# Create Summary Table
################################################################################

cat("\nCreating summary table...\n")

overlap_summary <- do.call(rbind, lapply(results_list, function(x) {
  data.frame(
    Comparison = x$comparison,
    Cell_Type = x$cell_type,
    Mouse_DEGs = as.numeric(x$set1_size),
    Schwann_Genes = as.numeric(x$set2_size),
    Background_Size = as.numeric(x$background_size),
    Observed_Overlap = as.numeric(x$observed_overlap),
    Expected_Mean = round(as.numeric(x$expected_mean), 2),
    Expected_SD = round(as.numeric(x$expected_sd), 2),
    Z_score = round(as.numeric(x$z_score), 2),
    P_value = signif(as.numeric(x$p_value), 3),
    Enrichment_Fold = round(as.numeric(x$enrichment_fold), 2),
    Percent_of_Mouse = round(100 * as.numeric(x$observed_overlap) / as.numeric(x$set1_size), 2),
    Percent_of_Schwann = round(100 * as.numeric(x$observed_overlap) / as.numeric(x$set2_size), 2),
    stringsAsFactors = FALSE
  )
}))

# Add significance stars
overlap_summary$Significance <- sapply(overlap_summary$P_value, function(p) {
  if (is.na(p)) return("")
  if (p < 0.001) return("***")
  if (p < 0.01) return("**")
  if (p < 0.05) return("*")
  return("ns")
})

# Sort by comparison and cell type
overlap_summary <- overlap_summary %>%
  arrange(Comparison, Cell_Type)

# Print summary
cat("\nOverlap Significance Summary:\n")
print(overlap_summary, row.names = FALSE)

# Save summary table
write.csv(overlap_summary,
          file = file.path(output_dir, "Overlap_Significance_Summary.csv"),
          row.names = FALSE)

cat("\nSaved summary to:", file.path(output_dir, "Overlap_Significance_Summary.csv"), "\n")

################################################################################
# Create Visualizations
################################################################################

cat("\nCreating visualizations...\n")

# 1. Z-score plot
p1 <- ggplot(overlap_summary, aes(x = reorder(paste(Comparison, Cell_Type, sep = "_"), Z_score),
                                   y = Z_score, fill = Comparison)) +
  geom_col() +
  geom_hline(yintercept = 1.96, linetype = "dashed", color = "red") +
  geom_hline(yintercept = 2.58, linetype = "dashed", color = "darkred") +
  coord_flip() +
  labs(title = "Z-scores of Mouse-Schwann Overlaps",
       subtitle = "Red dashed lines: p<0.05 (1.96) and p<0.01 (2.58)",
       x = "Comparison_CellType",
       y = "Z-score") +
  theme_bw() +
  theme(axis.text.y = element_text(size = 8),
        legend.position = "bottom")

ggsave(file.path(output_dir, "Zscore_Plot.png"), p1, width = 10, height = 8, dpi = 300)
ggsave(file.path(output_dir, "Zscore_Plot.pdf"), p1, width = 10, height = 8)

# 2. Enrichment fold change plot
p2 <- ggplot(overlap_summary, aes(x = reorder(paste(Comparison, Cell_Type, sep = "_"), Enrichment_Fold),
                                   y = Enrichment_Fold, fill = Comparison)) +
  geom_col() +
  geom_hline(yintercept = 1, linetype = "dashed", color = "gray50") +
  coord_flip() +
  labs(title = "Enrichment Fold Change of Mouse-Schwann Overlaps",
       subtitle = "Values > 1 indicate enrichment over random expectation",
       x = "Comparison_CellType",
       y = "Enrichment Fold Change") +
  theme_bw() +
  theme(axis.text.y = element_text(size = 8),
        legend.position = "bottom")

ggsave(file.path(output_dir, "Enrichment_Plot.png"), p2, width = 10, height = 8, dpi = 300)
ggsave(file.path(output_dir, "Enrichment_Plot.pdf"), p2, width = 10, height = 8)

# 3. P-value plot (-log10 transformed)
overlap_summary$log10P <- -log10(overlap_summary$P_value)

p3 <- ggplot(overlap_summary, aes(x = reorder(paste(Comparison, Cell_Type, sep = "_"), log10P),
                                   y = log10P, fill = Comparison)) +
  geom_col() +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed", color = "red") +
  geom_hline(yintercept = -log10(0.01), linetype = "dashed", color = "darkred") +
  coord_flip() +
  labs(title = "-log10(P-value) of Mouse-Schwann Overlaps",
       subtitle = "Red dashed lines: p=0.05 and p=0.01",
       x = "Comparison_CellType",
       y = "-log10(P-value)") +
  theme_bw() +
  theme(axis.text.y = element_text(size = 8),
        legend.position = "bottom")

ggsave(file.path(output_dir, "Pvalue_Plot.png"), p3, width = 10, height = 8, dpi = 300)
ggsave(file.path(output_dir, "Pvalue_Plot.pdf"), p3, width = 10, height = 8)

# 4. Comparison-wise summary plot
comp_summary <- overlap_summary %>%
  group_by(Comparison) %>%
  summarise(
    Mean_Zscore = mean(Z_score, na.rm = TRUE),
    Mean_Enrichment = mean(Enrichment_Fold, na.rm = TRUE),
    N_Significant = sum(P_value < 0.05, na.rm = TRUE),
    N_Total = n()
  )

p4 <- ggplot(comp_summary, aes(x = Comparison, y = Mean_Zscore, fill = Comparison)) +
  geom_col() +
  geom_text(aes(label = paste0(N_Significant, "/", N_Total, " sig")),
            vjust = -0.5, size = 3) +
  labs(title = "Mean Z-score by Comparison",
       subtitle = "Text shows number of significant overlaps (p<0.05)",
       x = "Comparison",
       y = "Mean Z-score") +
  theme_bw() +
  theme(legend.position = "none")

ggsave(file.path(output_dir, "Comparison_Summary.png"), p4, width = 8, height = 6, dpi = 300)
ggsave(file.path(output_dir, "Comparison_Summary.pdf"), p4, width = 8, height = 6)

# 5. Scatter plot: Observed vs Expected overlap
p5 <- ggplot(overlap_summary, aes(x = Expected_Mean, y = Observed_Overlap,
                                   color = Comparison, size = Z_score)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray50") +
  geom_point(alpha = 0.7) +
  geom_text(aes(label = Cell_Type), size = 2.5, hjust = -0.1, vjust = -0.1, show.legend = FALSE) +
  labs(title = "Observed vs Expected Overlap",
       subtitle = "Diagonal line represents random expectation",
       x = "Expected Overlap (mean of null distribution)",
       y = "Observed Overlap",
       size = "Z-score") +
  theme_bw() +
  theme(legend.position = "right")

ggsave(file.path(output_dir, "Observed_vs_Expected.png"), p5, width = 10, height = 8, dpi = 300)
ggsave(file.path(output_dir, "Observed_vs_Expected.pdf"), p5, width = 10, height = 8)

cat("\nVisualizations saved to:", output_dir, "\n")

################################################################################
# Statistical Summary Report
################################################################################

cat("\n" , rep("=", 80), "\n", sep = "")
cat("STATISTICAL SIGNIFICANCE SUMMARY\n")
cat(rep("=", 80), "\n", sep = "")

cat("\nBackground Gene Universe:", background_size, "mouse genes\n")
cat("Human Schwann Genes (mouse orthologs):", length(schwann_mouse), "\n")

cat("\nOverall Statistics:\n")
cat("  Total comparisons:", nrow(overlap_summary), "\n")
cat("  Significant (p<0.05):", sum(overlap_summary$P_value < 0.05, na.rm = TRUE), "\n")
cat("  Highly significant (p<0.01):", sum(overlap_summary$P_value < 0.01, na.rm = TRUE), "\n")
cat("  Very highly significant (p<0.001):", sum(overlap_summary$P_value < 0.001, na.rm = TRUE), "\n")

cat("\nTop 5 Most Significant Overlaps (by Z-score):\n")
top5 <- overlap_summary %>%
  arrange(desc(Z_score)) %>%
  head(5) %>%
  select(Comparison, Cell_Type, Observed_Overlap, Z_score, P_value, Enrichment_Fold)
print(top5, row.names = FALSE)

cat("\nTop 5 Highest Enrichment:\n")
top5_enrich <- overlap_summary %>%
  arrange(desc(Enrichment_Fold)) %>%
  head(5) %>%
  select(Comparison, Cell_Type, Observed_Overlap, Z_score, Enrichment_Fold)
print(top5_enrich, row.names = FALSE)

# Comparison-wise statistics
cat("\nBy Comparison Group:\n")
print(comp_summary, row.names = FALSE)

cat("\n", rep("=", 80), "\n", sep = "")
cat("Analysis complete!\n")
cat("Output directory:", output_dir, "\n")
cat(rep("=", 80), "\n", sep = "")
