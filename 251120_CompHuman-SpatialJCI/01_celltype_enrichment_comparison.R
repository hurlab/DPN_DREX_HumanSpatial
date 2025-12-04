################################################################################
# Analysis #1: Cell Type-Specific Enrichment Comparison
#
# Compares enrichment results across Schwann cell subtypes to identify:
# - Shared pathways: Biological processes common across all Schwann subtypes
# - Subtype-specific pathways: Unique functions in mySC vs nmSC vs ImmSC
################################################################################

if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  script_path <- rstudioapi::getActiveDocumentContext()$path
  setwd(dirname(script_path))
}

options(repos = c(CRAN = "https://cloud.r-project.org"))

if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(
  dplyr, tidyr, ggplot2, pheatmap, tibble, purrr, stringr,
  openxlsx, RColorBrewer
)

################################################################################
# Settings
################################################################################
enrichment_root <- "Output_JCI/00_DEGoverlap_Enrichment_Analysis"
output_dir <- "Output_JCI/01_CellType_Comparison"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# Cell types to compare
schwann_cell_types <- c("mySC", "nmSC", "ImmSC", "majorSC", "aggSC")

# Which comparison groups to analyze (set to NULL for all)
comparison_groups <- c("HFDvsSD", "DRvsHFD", "EXvsHFD", "DREXvsHFD")

# Which gene sets to focus on
focus_sets <- c("Overlap_MS", "Overlap_All3")  # Most relevant overlaps

# Enrichment file patterns (richR only)
enrichment_types <- c("richR_GO", "richR_KEGG")

# Minimum number of cell types for "shared" pathway
min_celltypes_shared <- 3

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
  ggplot2::ggsave(filename = path, plot = p, width = width, height = height, dpi = dpi, limitsize = FALSE)
}

read_enrichment_file <- function(file_path) {
  if (!file.exists(file_path)) return(NULL)
  tryCatch({
    df <- read.csv(file_path, stringsAsFactors = FALSE, check.names = FALSE)
    if (nrow(df) == 0) return(NULL)

    # Standardize column names
    cn <- tolower(colnames(df))
    colnames(df) <- cn

    # Identify key columns (different between richR and clusterProfiler)
    if ("description" %in% cn) {
      term_col <- "description"
    } else if ("term" %in% cn) {
      term_col <- "term"
    } else if ("id" %in% cn) {
      term_col <- "id"
    } else {
      return(NULL)
    }

    padj_col <- if ("p.adjust" %in% cn) "p.adjust" else if ("padj" %in% cn) "padj" else if ("adjpval" %in% cn) "adjpval" else NULL
    pval_col <- if ("pvalue" %in% cn) "pvalue" else if ("pval" %in% cn) "pval" else NULL

    if (is.null(padj_col) && is.null(pval_col)) return(NULL)

    # Select and rename columns
    result <- df %>%
      dplyr::select(
        Term = all_of(term_col),
        padj = if (!is.null(padj_col)) all_of(padj_col) else all_of(pval_col)
      ) %>%
      dplyr::filter(!is.na(Term), !is.na(padj), padj < 0.05) %>%
      dplyr::distinct(Term, .keep_all = TRUE)

    if (nrow(result) == 0) return(NULL)
    result
  }, error = function(e) NULL)
}

################################################################################
# Main Analysis
################################################################################
message("=== Cell Type-Specific Enrichment Comparison ===")

# Collect all enrichment results
all_results <- list()

for (enrich_type in enrichment_types) {
  message("\n--- Processing ", enrich_type, " ---")

  for (comp_group in comparison_groups) {
    for (cell_type in schwann_cell_types) {
      for (gene_set in focus_sets) {

        # Construct file path
        base_name <- paste0(comp_group, "_", cell_type)
        enrich_folder <- file.path(enrichment_root, paste0(base_name, "_enrichment"))
        enrich_file <- file.path(enrich_folder, paste0(gene_set, "_", enrich_type, ".csv"))

        # Read enrichment results
        enrich_data <- read_enrichment_file(enrich_file)

        if (!is.null(enrich_data)) {
          enrich_data <- enrich_data %>%
            dplyr::mutate(
              comparison = comp_group,
              cell_type = cell_type,
              gene_set = gene_set,
              enrich_type = enrich_type,
              neg_log10_padj = -log10(padj)
            )

          all_results[[length(all_results) + 1]] <- enrich_data
          message("  Found ", nrow(enrich_data), " terms for ", comp_group, " ", cell_type, " ", gene_set)
        }
      }
    }
  }
}

if (length(all_results) == 0) {
  stop("No enrichment results found. Make sure enrichment analysis has completed.")
}

# Combine all results
combined_results <- dplyr::bind_rows(all_results)
message("\nTotal enrichment terms collected: ", nrow(combined_results))

# Save combined results
save_df(combined_results, file.path(output_dir, "Combined_Enrichment_Results.csv"))

################################################################################
# Analysis 1: Shared vs Cell-Type-Specific Pathways
################################################################################
message("\n=== Identifying Shared and Cell-Type-Specific Pathways ===")

for (comp_group in comparison_groups) {
  for (gene_set in focus_sets) {
    for (enrich_type in enrichment_types) {

      subset_data <- combined_results %>%
        dplyr::filter(comparison == comp_group, gene_set == !!gene_set, enrich_type == !!enrich_type)

      if (nrow(subset_data) == 0) next

      # Count how many cell types each term appears in
      term_counts <- subset_data %>%
        dplyr::group_by(Term) %>%
        dplyr::summarise(
          n_celltypes = n_distinct(cell_type),
          celltypes = paste(sort(unique(cell_type)), collapse = ", "),
          mean_neg_log10_padj = mean(neg_log10_padj),
          max_neg_log10_padj = max(neg_log10_padj),
          .groups = "drop"
        ) %>%
        dplyr::arrange(desc(n_celltypes), desc(mean_neg_log10_padj))

      # Classify pathways
      term_counts <- term_counts %>%
        dplyr::mutate(
          category = dplyr::case_when(
            n_celltypes >= min_celltypes_shared ~ "Shared",
            n_celltypes == 1 ~ "Cell-type-specific",
            TRUE ~ "Partially shared"
          )
        )

      # Save summary
      out_name <- paste0(comp_group, "_", gene_set, "_", enrich_type, "_SharedVsSpecific.csv")
      save_df(term_counts, file.path(output_dir, out_name))

      message("  ", comp_group, " ", gene_set, " ", enrich_type, ": ",
              sum(term_counts$category == "Shared"), " shared, ",
              sum(term_counts$category == "Cell-type-specific"), " cell-type-specific")
    }
  }
}

################################################################################
# Analysis 2: Heatmap of Top Pathways Across Cell Types
################################################################################
message("\n=== Creating Heatmaps ===")

for (comp_group in comparison_groups) {
  for (gene_set in focus_sets) {
    for (enrich_type in enrichment_types) {

      subset_data <- combined_results %>%
        dplyr::filter(comparison == comp_group, gene_set == !!gene_set, enrich_type == !!enrich_type)

      if (nrow(subset_data) == 0) next

      # Select top terms (by max -log10 padj across cell types)
      top_terms <- subset_data %>%
        dplyr::group_by(Term) %>%
        dplyr::summarise(max_sig = max(neg_log10_padj), .groups = "drop") %>%
        dplyr::arrange(desc(max_sig)) %>%
        dplyr::slice_head(n = 30) %>%
        dplyr::pull(Term)

      if (length(top_terms) == 0) next

      # Create matrix for heatmap
      heatmap_data <- subset_data %>%
        dplyr::filter(Term %in% top_terms) %>%
        dplyr::select(Term, cell_type, neg_log10_padj) %>%
        tidyr::pivot_wider(names_from = cell_type, values_from = neg_log10_padj, values_fill = 0)

      if (nrow(heatmap_data) < 2) next

      # Convert to matrix
      heatmap_matrix <- as.matrix(heatmap_data[, -1])
      rownames(heatmap_matrix) <- heatmap_data$Term

      # Truncate long term names
      rownames(heatmap_matrix) <- substr(rownames(heatmap_matrix), 1, 60)

      # Create heatmap
      png_path <- file.path(output_dir, paste0(comp_group, "_", gene_set, "_", enrich_type, "_Heatmap.png"))
      pdf_path <- file.path(output_dir, paste0(comp_group, "_", gene_set, "_", enrich_type, "_Heatmap.pdf"))

      tryCatch({
        png(png_path, width = 10, height = 12, units = "in", res = 300)
        pheatmap::pheatmap(
          heatmap_matrix,
          cluster_rows = TRUE,
          cluster_cols = TRUE,
          scale = "none",
          color = colorRampPalette(c("white", "yellow", "orange", "red", "darkred"))(100),
          main = paste0(comp_group, " ", gene_set, "\n", enrich_type, " Enrichment"),
          fontsize_row = 8,
          fontsize_col = 10,
          angle_col = 45
        )
        dev.off()

        pdf(pdf_path, width = 10, height = 12)
        pheatmap::pheatmap(
          heatmap_matrix,
          cluster_rows = TRUE,
          cluster_cols = TRUE,
          scale = "none",
          color = colorRampPalette(c("white", "yellow", "orange", "red", "darkred"))(100),
          main = paste0(comp_group, " ", gene_set, "\n", enrich_type, " Enrichment"),
          fontsize_row = 8,
          fontsize_col = 10,
          angle_col = 45
        )
        dev.off()

        message("  Created heatmap: ", basename(png_path))
      }, error = function(e) {
        message("  Error creating heatmap: ", e$message)
      })
    }
  }
}

################################################################################
# Analysis 3: Dot Plot of Selected Pathways
################################################################################
message("\n=== Creating Dot Plots ===")

for (comp_group in comparison_groups) {
  for (gene_set in focus_sets) {
    for (enrich_type in enrichment_types) {

      subset_data <- combined_results %>%
        dplyr::filter(comparison == comp_group, gene_set == !!gene_set, enrich_type == !!enrich_type)

      if (nrow(subset_data) == 0) next

      # Select top 20 terms
      top_terms <- subset_data %>%
        dplyr::group_by(Term) %>%
        dplyr::summarise(max_sig = max(neg_log10_padj), .groups = "drop") %>%
        dplyr::arrange(desc(max_sig)) %>%
        dplyr::slice_head(n = 20) %>%
        dplyr::pull(Term)

      plot_data <- subset_data %>%
        dplyr::filter(Term %in% top_terms) %>%
        dplyr::mutate(Term = substr(Term, 1, 60))

      if (nrow(plot_data) == 0) next

      p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = cell_type, y = Term, size = neg_log10_padj, color = neg_log10_padj)) +
        ggplot2::geom_point() +
        ggplot2::scale_color_gradient(low = "blue", high = "red", name = "-log10(padj)") +
        ggplot2::scale_size_continuous(range = c(2, 10), name = "-log10(padj)") +
        ggplot2::theme_bw() +
        ggplot2::theme(
          axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
          axis.text.y = ggplot2::element_text(size = 8)
        ) +
        ggplot2::labs(
          title = paste0(comp_group, " ", gene_set, " - ", enrich_type),
          x = "Cell Type",
          y = "Pathway"
        )

      out_name <- paste0(comp_group, "_", gene_set, "_", enrich_type, "_DotPlot")
      save_plot(p, file.path(output_dir, paste0(out_name, ".png")), width = 10, height = 12)
      save_plot(p, file.path(output_dir, paste0(out_name, ".pdf")), width = 10, height = 12)

      message("  Created dot plot: ", out_name)
    }
  }
}

################################################################################
# Summary Report
################################################################################
message("\n=== Creating Summary Report ===")

summary_stats <- combined_results %>%
  dplyr::group_by(comparison, gene_set, enrich_type, cell_type) %>%
  dplyr::summarise(
    n_pathways = n_distinct(Term),
    mean_neg_log10_padj = mean(neg_log10_padj),
    .groups = "drop"
  ) %>%
  dplyr::arrange(comparison, gene_set, enrich_type, cell_type)

save_df(summary_stats, file.path(output_dir, "Summary_Statistics.csv"))

# Create Excel workbook with multiple sheets
wb <- openxlsx::createWorkbook()

openxlsx::addWorksheet(wb, "Summary_Stats")
openxlsx::writeData(wb, "Summary_Stats", summary_stats)

openxlsx::addWorksheet(wb, "All_Results")
openxlsx::writeData(wb, "All_Results", combined_results)

openxlsx::saveWorkbook(wb, file.path(output_dir, "CellType_Enrichment_Comparison.xlsx"), overwrite = TRUE)

message("\n=== Analysis Complete ===")
message("Output directory: ", output_dir)
message("Total comparisons analyzed: ", n_distinct(combined_results$comparison))
message("Total cell types: ", n_distinct(combined_results$cell_type))
message("Total unique pathways: ", n_distinct(combined_results$Term))
