################################################################################
# Analysis #8: Pathway Overlap Heatmaps
#
# Creates heatmaps showing enriched pathway overlaps across:
# - majorSC (mouse major Schwann cells)
# - aggSC (mouse aggregated Schwann cells: mySC + nmSC + ImmSC)
# - JCI_SC (human Schwann cell spatial transcriptomics)
# - JCI_Bulk (human bulk RNA-seq)
#
# For each comparison group and enrichment type (GO/KEGG):
# - Identifies enriched pathways in each dataset
# - Creates binary matrix showing pathway presence/absence
# - Generates heatmaps to visualize pathway overlap patterns
# - Identifies conserved vs dataset-specific pathways
################################################################################

if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  script_path <- rstudioapi::getActiveDocumentContext()$path
  setwd(dirname(script_path))
}

options(repos = c(CRAN = "https://cloud.r-project.org"))

if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(
  dplyr, tidyr, ggplot2, tibble, purrr, stringr,
  pheatmap, RColorBrewer, openxlsx
)

################################################################################
# Settings
################################################################################
enrichment_root <- "Output_JCI/Enrichment_Analysis"
output_root <- "Output_JCI/Pathway_Overlap_Heatmaps"
dir.create(output_root, showWarnings = FALSE, recursive = TRUE)

# Datasets to compare
datasets <- c("majorSC", "aggSC", "JCI_SC", "JCI_Bulk")
dataset_labels <- c("Mouse_majorSC", "Mouse_aggSC", "Human_JCI_SC", "Human_JCI_Bulk")
names(dataset_labels) <- datasets

# Comparison groups
comparison_groups <- c("HFDvsSD", "DRvsHFD", "EXvsHFD", "DREXvsHFD")

# Enrichment types
enrichment_types <- c("richR_GO", "richR_KEGG")

# Gene sets to analyze (where overlaps were calculated)
gene_sets <- c("Overlap_MS", "Overlap_MJ", "Overlap_All3")

# Pathway significance threshold
pathway_padj_cutoff <- 0.05

# Minimum datasets for "conserved" pathway
min_datasets_conserved <- 3

################################################################################
# Helper functions
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
  if (inherits(p, "ggplot")) {
    ggplot2::ggsave(filename = path, plot = p, width = width, height = height, dpi = dpi, limitsize = FALSE)
  } else {
    # For pheatmap objects
    if (grepl("\\.pdf$", path)) {
      pdf(path, width = width, height = height)
      print(p)
      dev.off()
    } else {
      png(path, width = width * dpi, height = height * dpi, res = dpi)
      print(p)
      dev.off()
    }
  }
}

read_enrichment_file <- function(file_path) {
  if (!file.exists(file_path)) return(NULL)
  tryCatch({
    df <- read.csv(file_path, stringsAsFactors = FALSE, check.names = FALSE)
    if (nrow(df) == 0) return(NULL)

    cn <- tolower(colnames(df))
    colnames(df) <- cn

    # Identify term column
    if ("description" %in% cn) {
      term_col <- "description"
    } else if ("term" %in% cn) {
      term_col <- "term"
    } else if ("id" %in% cn) {
      term_col <- "id"
    } else {
      return(NULL)
    }

    # Identify p-value column
    padj_col <- if ("p.adjust" %in% cn) "p.adjust" else if ("padj" %in% cn) "padj" else if ("adjpval" %in% cn) "adjpval" else NULL
    pval_col <- if ("pvalue" %in% cn) "pvalue" else if ("pval" %in% cn) "pval" else NULL

    if (is.null(padj_col) && is.null(pval_col)) return(NULL)

    # Select and filter
    result <- df %>%
      dplyr::select(
        Term = all_of(term_col),
        padj = if (!is.null(padj_col)) all_of(padj_col) else all_of(pval_col)
      ) %>%
      dplyr::filter(!is.na(Term), !is.na(padj), padj < pathway_padj_cutoff) %>%
      dplyr::distinct(Term, .keep_all = TRUE)

    if (nrow(result) == 0) return(NULL)
    result
  }, error = function(e) NULL)
}

################################################################################
# Main Analysis
################################################################################
message("=== Pathway Overlap Heatmap Analysis ===")

for (comp_group in comparison_groups) {
  message("\n--- Comparison: ", comp_group, " ---")

  for (enrich_type in enrichment_types) {
    message("  Enrichment type: ", enrich_type)

    # Collect pathway data for each dataset
    pathway_data <- list()

    for (dataset in datasets) {
      # Determine cell type and gene set based on dataset
      if (dataset %in% c("majorSC", "aggSC")) {
        # Mouse datasets - read from comparison_celltype_enrichment folder
        cell_type <- dataset
        base_name <- paste0(comp_group, "_", cell_type)
        enrich_folder <- file.path(enrichment_root, paste0(base_name, "_enrichment"))

        # Try different gene sets (Overlap_MS is most relevant for mouse-human comparison)
        pathways <- NULL
        for (gene_set in gene_sets) {
          enrich_file <- file.path(enrich_folder, paste0(gene_set, "_", enrich_type, ".csv"))
          pathways <- read_enrichment_file(enrich_file)
          if (!is.null(pathways)) break
        }

      } else if (dataset == "JCI_SC") {
        # Human Schwann - mapped to mouse, stored as "Schwann"
        # Read from Overlap_MS or Overlap_All3 for consistency
        # We'll use a representative mouse cell type to access the human pathway data
        base_name <- paste0(comp_group, "_majorSC")  # Use majorSC as reference
        enrich_folder <- file.path(enrichment_root, paste0(base_name, "_enrichment"))
        enrich_file <- file.path(enrich_folder, paste0("Schwann_all_", enrich_type, ".csv"))
        pathways <- read_enrichment_file(enrich_file)

      } else if (dataset == "JCI_Bulk") {
        # Human bulk - mapped to mouse
        base_name <- paste0(comp_group, "_majorSC")  # Use majorSC as reference
        enrich_folder <- file.path(enrichment_root, paste0(base_name, "_enrichment"))
        enrich_file <- file.path(enrich_folder, paste0("JCI_all_", enrich_type, ".csv"))
        pathways <- read_enrichment_file(enrich_file)
      }

      if (!is.null(pathways)) {
        pathway_data[[dataset]] <- pathways$Term
        message("    ", dataset_labels[dataset], ": ", length(pathways$Term), " pathways")
      } else {
        pathway_data[[dataset]] <- character(0)
        message("    ", dataset_labels[dataset], ": 0 pathways")
      }
    }

    # Skip if no pathways found
    if (all(sapply(pathway_data, length) == 0)) {
      message("    No pathways found, skipping...")
      next
    }

    # Create binary matrix
    all_pathways <- unique(unlist(pathway_data))
    if (length(all_pathways) == 0) next

    pathway_matrix <- matrix(0, nrow = length(all_pathways), ncol = length(datasets))
    rownames(pathway_matrix) <- all_pathways
    colnames(pathway_matrix) <- dataset_labels[datasets]

    for (i in seq_along(datasets)) {
      dataset <- datasets[i]
      pathway_matrix[pathway_data[[dataset]], i] <- 1
    }

    # Filter to pathways present in at least one dataset
    pathway_matrix <- pathway_matrix[rowSums(pathway_matrix) > 0, , drop = FALSE]

    if (nrow(pathway_matrix) == 0) {
      message("    No pathways after filtering, skipping...")
      next
    }

    # Sort by number of datasets (most shared first)
    pathway_matrix <- pathway_matrix[order(-rowSums(pathway_matrix)), , drop = FALSE]

    message("    Total unique pathways: ", nrow(pathway_matrix))
    message("    Conserved pathways (≥", min_datasets_conserved, " datasets): ",
            sum(rowSums(pathway_matrix) >= min_datasets_conserved))

    # Create output directory
    out_dir <- file.path(output_root, paste0(comp_group, "_", enrich_type))
    dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

    # Save pathway matrix
    pathway_df <- as.data.frame(pathway_matrix) %>%
      tibble::rownames_to_column("Pathway") %>%
      dplyr::mutate(n_datasets = rowSums(pathway_matrix))
    save_df(pathway_df, file.path(out_dir, "Pathway_Matrix.csv"))

    # Identify conserved and specific pathways
    conserved_pathways <- pathway_df %>%
      dplyr::filter(n_datasets >= min_datasets_conserved) %>%
      dplyr::arrange(desc(n_datasets))

    if (nrow(conserved_pathways) > 0) {
      save_df(conserved_pathways, file.path(out_dir, "Conserved_Pathways.csv"))
    }

    # Dataset-specific pathways
    for (i in seq_along(datasets)) {
      dataset <- datasets[i]
      specific <- pathway_df %>%
        dplyr::filter(.data[[dataset_labels[dataset]]] == 1, n_datasets == 1)

      if (nrow(specific) > 0) {
        save_df(specific, file.path(out_dir, paste0(dataset, "_Specific_Pathways.csv")))
      }
    }

    # Generate heatmap
    message("    Generating heatmap...")

    # Limit to top pathways for visualization
    max_pathways <- 50
    if (nrow(pathway_matrix) > max_pathways) {
      pathway_matrix_plot <- pathway_matrix[1:max_pathways, , drop = FALSE]
      subtitle <- paste0("(Top ", max_pathways, " of ", nrow(pathway_matrix), " pathways)")
    } else {
      pathway_matrix_plot <- pathway_matrix
      subtitle <- paste0("(", nrow(pathway_matrix), " pathways)")
    }

    # Shorten pathway names for readability
    rownames(pathway_matrix_plot) <- substr(rownames(pathway_matrix_plot), 1, 80)

    # Create heatmap
    colors <- c("white", "#2166AC")

    tryCatch({
      p <- pheatmap::pheatmap(
        pathway_matrix_plot,
        color = colors,
        cluster_rows = FALSE,  # Already sorted by conservation
        cluster_cols = FALSE,
        show_rownames = TRUE,
        show_colnames = TRUE,
        main = paste0(comp_group, " - ", enrich_type, "\n", subtitle),
        fontsize_row = 8,
        fontsize_col = 10,
        border_color = "grey60",
        legend = FALSE,
        silent = TRUE
      )

      # Save plots
      save_plot(p, file.path(out_dir, "Pathway_Overlap_Heatmap.pdf"),
                width = 10, height = max(8, nrow(pathway_matrix_plot) * 0.2))
      save_plot(p, file.path(out_dir, "Pathway_Overlap_Heatmap.png"),
                width = 10, height = max(8, nrow(pathway_matrix_plot) * 0.2))

    }, error = function(e) {
      warning("    Heatmap generation failed: ", conditionMessage(e))
    })

    # Summary statistics
    summary_stats <- tibble(
      comparison = comp_group,
      enrichment_type = enrich_type,
      n_pathways_total = nrow(pathway_matrix),
      n_pathways_conserved = sum(rowSums(pathway_matrix) >= min_datasets_conserved),
      n_pathways_mouse_only = sum(rowSums(pathway_matrix[, 1:2, drop = FALSE]) > 0 & rowSums(pathway_matrix[, 3:4, drop = FALSE]) == 0),
      n_pathways_human_only = sum(rowSums(pathway_matrix[, 3:4, drop = FALSE]) > 0 & rowSums(pathway_matrix[, 1:2, drop = FALSE]) == 0),
      n_majorSC = sum(pathway_matrix[, 1]),
      n_aggSC = sum(pathway_matrix[, 2]),
      n_JCI_SC = sum(pathway_matrix[, 3]),
      n_JCI_Bulk = sum(pathway_matrix[, 4])
    )

    save_df(summary_stats, file.path(out_dir, "Summary_Statistics.csv"))
  }
}

################################################################################
# Create master summary across all comparisons
################################################################################
message("\n=== Creating Master Summary ===")

all_summaries <- list()

for (comp_group in comparison_groups) {
  for (enrich_type in enrichment_types) {
    out_dir <- file.path(output_root, paste0(comp_group, "_", enrich_type))
    summary_file <- file.path(out_dir, "Summary_Statistics.csv")

    if (file.exists(summary_file)) {
      summary <- read.csv(summary_file, stringsAsFactors = FALSE)
      all_summaries[[length(all_summaries) + 1]] <- summary
    }
  }
}

if (length(all_summaries) > 0) {
  master_summary <- dplyr::bind_rows(all_summaries)
  save_df(master_summary, file.path(output_root, "Master_Pathway_Summary.csv"))

  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "Summary")
  openxlsx::writeData(wb, "Summary", master_summary)
  openxlsx::saveWorkbook(wb, file.path(output_root, "Master_Pathway_Summary.xlsx"), overwrite = TRUE)

  message("Master summary saved to: ", file.path(output_root, "Master_Pathway_Summary.csv"))
}

message("\n=== Pathway Overlap Analysis Complete ===")
message("Output directory: ", output_root)
