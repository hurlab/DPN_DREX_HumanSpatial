################################################################################
# Analysis #1: GO and KEGG Enrichment of Cibersort DEGs
#
# This script performs GO and KEGG enrichment analysis on the Cibersort-derived
# Schwann cell DEGs (C vs DPN) from the DEGs_SchwannCells_C_vs_DPN.xlsx file.
#
# Outputs:
# - CSV files with GO and KEGG enrichment results
# - Dot plots visualizing top enriched pathways
################################################################################

# Set working directory to script location
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  script_path <- rstudioapi::getActiveDocumentContext()$path
  setwd(dirname(script_path))
}

options(repos = c(CRAN = "https://cloud.r-project.org"))

# Install and load required packages
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(
  dplyr, tidyr, ggplot2, openxlsx, tibble, stringr,
  AnnotationDbi, org.Mm.eg.db, homologene
)

# Check for richR - install from GitHub if not available
if (!requireNamespace("richR", quietly = TRUE)) {
  message("richR not found. Installing from GitHub...")
  if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes")
  remotes::install_github("guokai8/richR", quiet = TRUE)
}
library(richR)

################################################################################
# Settings
################################################################################
# Input file
cibersort_file <- "DEGs_SchwannCells_C_vs_DPN.xlsx"
padj_cutoff <- 0.05

# Minimum genes for enrichment
min_genes_for_enrichment <- 5

# Output directory
output_dir <- "Output_260107/01_Enrichment_Cibersort"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

################################################################################
# Helper Functions
################################################################################
safe_base <- function(x, limit = 150) {
  x <- gsub("[^A-Za-z0-9._-]+", "_", x)
  if (nchar(x) > limit) substr(x, 1, limit) else x
}

save_df <- function(df, path) {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  utils::write.csv(df, path, row.names = FALSE)
}

save_plot <- function(p, path, width = 10, height = 8, dpi = 300) {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  ggplot2::ggsave(filename = path, plot = p, width = width, height = height, dpi = dpi, limitsize = FALSE)
}

read_cibersort_deg <- function(file_path, padj_cutoff = 0.05) {
  df <- openxlsx::read.xlsx(file_path, detectDates = FALSE)

  # Normalize column names
  cn <- tolower(gsub("\\s+", "_", colnames(df)))
  colnames(df) <- cn

  # Filter for DEGs using adj.P.Val < 0.05
  df_filtered <- df %>%
    dplyr::filter(!is.na(gene), gene != "") %>%
    dplyr::filter(adj.p.val < padj_cutoff)

  return(df_filtered)
}

build_human_to_mouse_map <- function() {
  hom <- homologene::homologeneData
  human <- hom %>%
    dplyr::filter(Taxonomy == 9606) %>%
    dplyr::select(HID, Human_Symbol = Gene.Symbol)
  mouse <- hom %>%
    dplyr::filter(Taxonomy == 10090) %>%
    dplyr::select(HID, Mouse_Symbol = Gene.Symbol)
  dplyr::left_join(human, mouse, by = "HID") %>%
    dplyr::filter(!is.na(Mouse_Symbol)) %>%
    dplyr::arrange(Human_Symbol) %>%
    dplyr::group_by(Human_Symbol) %>%
    dplyr::slice(1) %>%
    dplyr::ungroup() %>%
    dplyr::select(Human_Symbol, Mouse_Symbol)
}

map_genes_to_mouse <- function(genes, mapping_tbl) {
  tibble(Human_Symbol = genes) %>%
    dplyr::filter(!is.na(Human_Symbol), Human_Symbol != "") %>%
    dplyr::mutate(Mouse_Symbol = mapping_tbl$Mouse_Symbol[match(Human_Symbol, mapping_tbl$Human_Symbol)]) %>%
    dplyr::filter(!is.na(Mouse_Symbol)) %>%
    dplyr::distinct(Mouse_Symbol) %>%
    dplyr::pull(Mouse_Symbol)
}

################################################################################
# Main Analysis
################################################################################
message("=== GO and KEGG Enrichment Analysis of Cibersort DEGs ===")

# Read Cibersort DEGs
message("\nReading Cibersort DEGs from: ", cibersort_file)
cibersort_deg <- read_cibersort_deg(cibersort_file, padj_cutoff = padj_cutoff)

# Count upregulated and downregulated genes
up_genes <- cibersort_deg %>% dplyr::filter(logfc > 0) %>% nrow()
down_genes <- cibersort_deg %>% dplyr::filter(logfc < 0) %>% nrow()

message("  Total DEGs (adj.P.Val < ", padj_cutoff, "): ", nrow(cibersort_deg))
message("    Upregulated: ", up_genes)
message("    Downregulated: ", down_genes)

# Extract gene lists
human_up_genes <- cibersort_deg %>% dplyr::filter(logfc > 0) %>% dplyr::pull(gene)
human_down_genes <- cibersort_deg %>% dplyr::filter(logfc < 0) %>% dplyr::pull(gene)
human_all_genes <- cibersort_deg %>% dplyr::pull(gene)

# Map human genes to mouse orthologs for enrichment
message("\nMapping human genes to mouse orthologs...")
human2mouse <- build_human_to_mouse_map()

mouse_up_genes <- map_genes_to_mouse(human_up_genes, human2mouse)
mouse_down_genes <- map_genes_to_mouse(human_down_genes, human2mouse)
mouse_all_genes <- map_genes_to_mouse(human_all_genes, human2mouse)

message("  Upregulated: ", length(human_up_genes), " human -> ", length(mouse_up_genes), " mouse orthologs")
message("  Downregulated: ", length(human_down_genes), " human -> ", length(mouse_down_genes), " mouse orthologs")
message("  All: ", length(human_all_genes), " human -> ", length(mouse_all_genes), " mouse orthologs")

# Save gene lists
save_df(tibble(Gene = sort(unique(human_up_genes))), file.path(output_dir, "Human_Up_Genes.csv"))
save_df(tibble(Gene = sort(unique(human_down_genes))), file.path(output_dir, "Human_Down_Genes.csv"))
save_df(tibble(Gene = sort(unique(human_all_genes))), file.path(output_dir, "Human_All_Genes.csv"))
save_df(tibble(Gene = sort(unique(mouse_up_genes))), file.path(output_dir, "Mouse_Up_Genes.csv"))
save_df(tibble(Gene = sort(unique(mouse_down_genes))), file.path(output_dir, "Mouse_Down_Genes.csv"))
save_df(tibble(Gene = sort(unique(mouse_all_genes))), file.path(output_dir, "Mouse_All_Genes.csv"))

################################################################################
# GO Enrichment Analysis
################################################################################
message("\n=== Running GO Enrichment ===")

# Check if richR is available
if (requireNamespace("richR", quietly = TRUE)) {
  message("Using richR for GO enrichment...")

  # Build GO annotation
  go_annot <- NULL
  tryCatch({
    go_annot <- richR::buildAnnot(species = "mouse", keytype = "SYMBOL", anntype = "GO")
    message("  GO annotations built successfully")
  }, error = function(e) {
    message("  Failed to build GO annotations: ", e$message)
  })

  # Run GO enrichment for each gene set
  gene_sets <- list(
    All = mouse_all_genes,
    Up = mouse_up_genes,
    Down = mouse_down_genes
  )

  for (set_name in names(gene_sets)) {
    genes <- gene_sets[[set_name]]
    if (length(genes) < min_genes_for_enrichment) {
      message("  Skipping ", set_name, " (only ", length(genes), " genes)")
      next
    }

    tryCatch({
      go_res <- richR::richGO(genes, godata = go_annot, organism = "mouse", keytype = "SYMBOL")
      go_df <- as.data.frame(go_res)
      go_df$neg_log10_padj <- -log10(go_df$Padj)
      save_df(go_df, file.path(output_dir, paste0("GO_", set_name, "_richR.csv")))
      message("  GO enrichment completed for ", set_name, " (", nrow(go_df), " terms)")
    }, error = function(e) {
      message("  GO enrichment failed for ", set_name, ": ", e$message)
    })
  }
} else {
  message("richR not available - skipping GO enrichment")
}

################################################################################
# KEGG Enrichment Analysis
################################################################################
message("\n=== Running KEGG Enrichment ===")

if (requireNamespace("richR", quietly = TRUE)) {
  message("Using richR for KEGG enrichment...")

  # Build KEGG annotation
  kegg_annot <- NULL
  tryCatch({
    kegg_annot <- richR::buildAnnot(species = "mouse", keytype = "SYMBOL", anntype = "KEGG", builtin = FALSE)
    message("  KEGG annotations built successfully")
  }, error = function(e) {
    message("  Failed to build KEGG annotations: ", e$message)
  })

  # Run KEGG enrichment for each gene set
  for (set_name in names(gene_sets)) {
    genes <- gene_sets[[set_name]]
    if (length(genes) < min_genes_for_enrichment) {
      message("  Skipping ", set_name, " (only ", length(genes), " genes)")
      next
    }

    tryCatch({
      kegg_res <- richR::richKEGG(genes, kodata = kegg_annot, organism = "mouse", keytype = "SYMBOL", builtin = FALSE)
      kegg_df <- as.data.frame(kegg_res)
      kegg_df$neg_log10_padj <- -log10(kegg_df$Padj)
      save_df(kegg_df, file.path(output_dir, paste0("KEGG_", set_name, "_richR.csv")))
      message("  KEGG enrichment completed for ", set_name, " (", nrow(kegg_df), " pathways)")
    }, error = function(e) {
      message("  KEGG enrichment failed for ", set_name, ": ", e$message)
    })
  }
} else {
  message("richR not available - skipping KEGG enrichment")
}

################################################################################
# Create Dot Plots
################################################################################
message("\n=== Creating Dot Plots ===")

# Function to create dot plot
create_dot_plot <- function(enrich_df, title, y_label = "Pathway") {
  if (is.null(enrich_df) || nrow(enrich_df) == 0) return(NULL)

  # Select top 20 terms (richR uses Term and Significant columns)
  top_terms <- enrich_df %>%
    dplyr::arrange(Padj) %>%
    dplyr::slice_head(n = 20) %>%
    dplyr::pull(Term)

  plot_data <- enrich_df %>%
    dplyr::filter(Term %in% top_terms) %>%
    dplyr::mutate(Term = factor(Term, levels = rev(unique(Term))))

  p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = neg_log10_padj, y = Term)) +
    ggplot2::geom_point(ggplot2::aes(size = Significant, color = neg_log10_padj)) +
    ggplot2::scale_color_gradient(low = "blue", high = "red", name = "-log10(padj)") +
    ggplot2::scale_size_continuous(range = c(2, 10), name = "Gene Count") +
    ggplot2::theme_bw() +
    ggplot2::theme(
      axis.text.y = ggplot2::element_text(size = 9),
      axis.text.x = ggplot2::element_text(size = 10)
    ) +
    ggplot2::labs(
      title = title,
      x = "-log10(adjusted p-value)",
      y = y_label
    )

  return(p)
}

# Create GO dot plots
go_files <- list.files(output_dir, pattern = "^GO_.*_richR\\.csv$", full.names = TRUE)
for (go_file in go_files) {
  go_df <- read.csv(go_file, stringsAsFactors = FALSE)
  set_name <- gsub("^GO_(.+)_richR\\.csv$", "\\1", basename(go_file))

  p <- create_dot_plot(go_df, paste("GO Enrichment -", set_name))
  if (!is.null(p)) {
    save_plot(p, file.path(output_dir, paste0("GO_", set_name, "_DotPlot.png")), width = 10, height = 10)
    save_plot(p, file.path(output_dir, paste0("GO_", set_name, "_DotPlot.pdf")), width = 10, height = 10)
    message("  Created GO dot plot: ", set_name)
  }
}

# Create KEGG dot plots
kegg_files <- list.files(output_dir, pattern = "^KEGG_.*_richR\\.csv$", full.names = TRUE)
for (kegg_file in kegg_files) {
  kegg_df <- read.csv(kegg_file, stringsAsFactors = FALSE)
  set_name <- gsub("^KEGG_(.+)_richR\\.csv$", "\\1", basename(kegg_file))

  p <- create_dot_plot(kegg_df, paste("KEGG Enrichment -", set_name))
  if (!is.null(p)) {
    save_plot(p, file.path(output_dir, paste0("KEGG_", set_name, "_DotPlot.png")), width = 10, height = 8)
    save_plot(p, file.path(output_dir, paste0("KEGG_", set_name, "_DotPlot.pdf")), width = 10, height = 8)
    message("  Created KEGG dot plot: ", set_name)
  }
}

################################################################################
# Summary Report
################################################################################
message("\n=== Creating Summary Report ===")

summary_list <- list(
  c("Parameter", "Value"),
  c("Input file", cibersort_file),
  c("Adj.P.Val cutoff", as.character(padj_cutoff)),
  c("Total DEGs", nrow(cibersort_deg)),
  c("Upregulated genes", up_genes),
  c("Downregulated genes", down_genes),
  c("Human genes mapped to mouse", paste(length(mouse_all_genes), "of", length(human_all_genes)))
)

summary_df <- do.call(rbind, summary_list)
colnames(summary_df) <- c("Parameter", "Value")
save_df(as.data.frame(summary_df), file.path(output_dir, "Summary.csv"))

# Create Excel summary
wb <- openxlsx::createWorkbook()
openxlsx::addWorksheet(wb, "Summary")
openxlsx::writeData(wb, "Summary", as.data.frame(summary_df))

# Add GO results if available
go_files <- list.files(output_dir, pattern = "^GO_.*_richR\\.csv$", full.names = TRUE)
if (length(go_files) > 0) {
  for (go_file in go_files) {
    sheet_name <- safe_base(gsub("^GO_(.+)_richR\\.csv$", "GO_\\1", basename(go_file)), limit = 31)
    go_df <- read.csv(go_file, stringsAsFactors = FALSE)
    openxlsx::addWorksheet(wb, sheet_name)
    openxlsx::writeData(wb, sheet_name, go_df)
  }
}

# Add KEGG results if available
kegg_files <- list.files(output_dir, pattern = "^KEGG_.*_richR\\.csv$", full.names = TRUE)
if (length(kegg_files) > 0) {
  for (kegg_file in kegg_files) {
    sheet_name <- safe_base(gsub("^KEGG_(.+)_richR\\.csv$", "KEGG_\\1", basename(kegg_file)), limit = 31)
    kegg_df <- read.csv(kegg_file, stringsAsFactors = FALSE)
    openxlsx::addWorksheet(wb, sheet_name)
    openxlsx::writeData(wb, sheet_name, kegg_df)
  }
}

openxlsx::saveWorkbook(wb, file.path(output_dir, "Enrichment_Summary.xlsx"), overwrite = TRUE)

message("\n=== Analysis Complete ===")
message("Output directory: ", output_dir)
message("Results:")
message("  - Gene lists saved")
message("  - GO and KEGG enrichment tables saved")
message("  - Dot plots saved")
message("  - Summary Excel workbook created")
