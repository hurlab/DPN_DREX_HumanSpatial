################################################################################
# Analysis #3: Human-Mouse Conservation Analysis
#
# Assesses cross-species conservation of DPN-related changes:
# - Conserved DEGs: Genes changed in both mouse scRNA-seq AND human spatial/bulk
# - Species-specific DEGs: Changes unique to mouse or human
# - Conservation by pathway: Which biological processes are conserved vs divergent
################################################################################

if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  script_path <- rstudioapi::getActiveDocumentContext()$path
  setwd(dirname(script_path))
}

options(repos = c(CRAN = "https://cloud.r-project.org"))

if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(
  dplyr, tidyr, ggplot2, tibble, purrr, stringr,
  openxlsx, ggVennDiagram
)

################################################################################
# Settings
################################################################################
enrichment_root <- "Output_JCI/00_DEGoverlap_Enrichment_Analysis"
output_dir <- "Output_JCI/03_Conservation_Analysis"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# Cell types to analyze
schwann_cell_types <- c("mySC", "nmSC", "ImmSC", "majorSC", "aggSC")

# Comparison groups to analyze
comparison_groups <- c("HFDvsSD", "DRvsHFD", "EXvsHFD", "DREXvsHFD")

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

read_gene_list <- function(file_path) {
  if (!file.exists(file_path)) return(character(0))
  tryCatch({
    df <- read.csv(file_path, stringsAsFactors = FALSE, check.names = FALSE)
    genes <- df[[1]]
    genes <- genes[!is.na(genes) & genes != ""]
    unique(genes)
  }, error = function(e) character(0))
}

################################################################################
# Main Analysis
################################################################################
message("=== Human-Mouse Conservation Analysis ===")

# Collect conservation statistics
conservation_stats <- list()

for (comp_group in comparison_groups) {
  message("\n--- Comparison: ", comp_group, " ---")

  for (cell_type in schwann_cell_types) {
    base_name <- paste0(comp_group, "_", cell_type)
    enrich_folder <- file.path(enrichment_root, paste0(base_name, "_enrichment"))

    # Read gene sets
    mouse_all <- read_gene_list(file.path(enrich_folder, "Mouse_all_Genes.csv"))
    schwann_all <- read_gene_list(file.path(enrich_folder, "Schwann_all_Genes.csv"))
    jci_all <- read_gene_list(file.path(enrich_folder, "JCI_all_Genes.csv"))
    overlap_ms <- read_gene_list(file.path(enrich_folder, "Overlap_MS_Genes.csv"))
    overlap_mj <- read_gene_list(file.path(enrich_folder, "Overlap_MJ_Genes.csv"))
    overlap_sj <- read_gene_list(file.path(enrich_folder, "Overlap_SJ_Genes.csv"))
    overlap_all3 <- read_gene_list(file.path(enrich_folder, "Overlap_All3_Genes.csv"))
    mouse_only <- read_gene_list(file.path(enrich_folder, "Mouse_only_Genes.csv"))
    schwann_only <- read_gene_list(file.path(enrich_folder, "Schwann_only_Genes.csv"))
    jci_only <- read_gene_list(file.path(enrich_folder, "JCI_only_Genes.csv"))

    if (length(mouse_all) == 0) next

    # Calculate conservation rates
    conservation_rate_schwann <- length(overlap_ms) / length(mouse_all)
    conservation_rate_jci <- length(overlap_mj) / length(mouse_all)
    conservation_rate_any_human <- length(union(overlap_ms, overlap_mj)) / length(mouse_all)
    conservation_rate_both_human <- length(overlap_all3) / length(mouse_all)

    # Record statistics
    conservation_stats[[length(conservation_stats) + 1]] <- tibble(
      comparison = comp_group,
      cell_type = cell_type,
      n_mouse_total = length(mouse_all),
      n_schwann_total = length(schwann_all),
      n_jci_total = length(jci_all),
      n_conserved_schwann = length(overlap_ms),
      n_conserved_jci = length(overlap_mj),
      n_conserved_both = length(overlap_all3),
      n_mouse_only = length(mouse_only),
      conservation_rate_schwann = conservation_rate_schwann,
      conservation_rate_jci = conservation_rate_jci,
      conservation_rate_any_human = conservation_rate_any_human,
      conservation_rate_both_human = conservation_rate_both_human
    )

    message("  ", cell_type, ": Mouse=", length(mouse_all),
            ", Conserved in Schwann=", length(overlap_ms),
            " (", round(conservation_rate_schwann * 100, 1), "%)",
            ", Conserved in JCI=", length(overlap_mj),
            " (", round(conservation_rate_jci * 100, 1), "%)")
  }
}

# Save conservation statistics
if (length(conservation_stats) > 0) {
  conservation_df <- dplyr::bind_rows(conservation_stats)
  save_df(conservation_df, file.path(output_dir, "Conservation_Statistics.csv"))

  # Create summary visualizations
  message("\n=== Creating Conservation Visualizations ===")

  # Plot 1: Conservation rates by cell type
  p1 <- ggplot2::ggplot(conservation_df, ggplot2::aes(x = cell_type, y = conservation_rate_schwann, fill = comparison)) +
    ggplot2::geom_col(position = "dodge") +
    ggplot2::theme_bw() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)) +
    ggplot2::labs(
      title = "Mouse-Schwann Conservation Rate by Cell Type",
      x = "Cell Type",
      y = "Conservation Rate (fraction)",
      fill = "Comparison"
    ) +
    ggplot2::scale_y_continuous(labels = scales::percent)

  save_plot(p1, file.path(output_dir, "Conservation_Rate_Schwann.png"), width = 12, height = 8)
  save_plot(p1, file.path(output_dir, "Conservation_Rate_Schwann.pdf"), width = 12, height = 8)

  # Plot 2: Conservation rates for JCI
  p2 <- ggplot2::ggplot(conservation_df, ggplot2::aes(x = cell_type, y = conservation_rate_jci, fill = comparison)) +
    ggplot2::geom_col(position = "dodge") +
    ggplot2::theme_bw() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)) +
    ggplot2::labs(
      title = "Mouse-JCI Conservation Rate by Cell Type",
      x = "Cell Type",
      y = "Conservation Rate (fraction)",
      fill = "Comparison"
    ) +
    ggplot2::scale_y_continuous(labels = scales::percent)

  save_plot(p2, file.path(output_dir, "Conservation_Rate_JCI.png"), width = 12, height = 8)
  save_plot(p2, file.path(output_dir, "Conservation_Rate_JCI.pdf"), width = 12, height = 8)

  # Plot 3: Comparison of conservation rates (Schwann vs JCI)
  plot_data <- conservation_df %>%
    tidyr::pivot_longer(
      cols = c(conservation_rate_schwann, conservation_rate_jci),
      names_to = "dataset",
      values_to = "conservation_rate"
    ) %>%
    dplyr::mutate(dataset = gsub("conservation_rate_", "", dataset))

  p3 <- ggplot2::ggplot(plot_data, ggplot2::aes(x = comparison, y = conservation_rate, fill = dataset)) +
    ggplot2::geom_boxplot() +
    ggplot2::facet_wrap(~ cell_type, ncol = 3) +
    ggplot2::theme_bw() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)) +
    ggplot2::labs(
      title = "Conservation Rates: Schwann vs JCI Across Cell Types",
      x = "Comparison Group",
      y = "Conservation Rate",
      fill = "Human Dataset"
    ) +
    ggplot2::scale_y_continuous(labels = scales::percent)

  save_plot(p3, file.path(output_dir, "Conservation_Comparison_Boxplot.png"), width = 14, height = 10)
  save_plot(p3, file.path(output_dir, "Conservation_Comparison_Boxplot.pdf"), width = 14, height = 10)

  # Plot 4: Number of genes (absolute counts)
  plot_data2 <- conservation_df %>%
    tidyr::pivot_longer(
      cols = c(n_mouse_total, n_conserved_schwann, n_conserved_jci, n_conserved_both, n_mouse_only),
      names_to = "category",
      values_to = "count"
    ) %>%
    dplyr::mutate(category = gsub("^n_", "", category))

  p4 <- ggplot2::ggplot(plot_data2, ggplot2::aes(x = cell_type, y = count, fill = category)) +
    ggplot2::geom_col(position = "dodge") +
    ggplot2::facet_wrap(~ comparison, ncol = 3) +
    ggplot2::theme_bw() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)) +
    ggplot2::labs(
      title = "Gene Counts: Total vs Conserved vs Mouse-Only",
      x = "Cell Type",
      y = "Number of Genes",
      fill = "Category"
    )

  save_plot(p4, file.path(output_dir, "Gene_Counts_Comparison.png"), width = 14, height = 10)
  save_plot(p4, file.path(output_dir, "Gene_Counts_Comparison.pdf"), width = 14, height = 10)
}

################################################################################
# Analysis 2: Identify Highly Conserved Genes
################################################################################
message("\n=== Identifying Highly Conserved Genes ===")

# Find genes conserved across multiple comparisons within same cell type
highly_conserved <- list()

for (cell_type in schwann_cell_types) {
  message("\n--- Cell Type: ", cell_type, " ---")

  # Collect all overlap_all3 sets for this cell type
  all3_sets <- list()

  for (comp_group in comparison_groups) {
    base_name <- paste0(comp_group, "_", cell_type)
    enrich_folder <- file.path(enrichment_root, paste0(base_name, "_enrichment"))
    overlap_all3 <- read_gene_list(file.path(enrich_folder, "Overlap_All3_Genes.csv"))

    if (length(overlap_all3) > 0) {
      all3_sets[[comp_group]] <- overlap_all3
    }
  }

  if (length(all3_sets) == 0) next

  # Find genes conserved in multiple comparisons
  all_genes <- unique(unlist(all3_sets))

  gene_conservation_counts <- sapply(all_genes, function(gene) {
    sum(sapply(all3_sets, function(set) gene %in% set))
  })

  gene_conservation_df <- tibble(
    Gene = all_genes,
    n_comparisons_conserved = gene_conservation_counts,
    comparisons = sapply(all_genes, function(gene) {
      comps <- names(all3_sets)[sapply(all3_sets, function(set) gene %in% set)]
      paste(comps, collapse = ", ")
    })
  ) %>%
    dplyr::arrange(desc(n_comparisons_conserved))

  # Save highly conserved genes (present in ≥2 comparisons)
  highly_conserved_genes <- gene_conservation_df %>%
    dplyr::filter(n_comparisons_conserved >= 2)

  if (nrow(highly_conserved_genes) > 0) {
    save_df(highly_conserved_genes, file.path(output_dir, paste0(cell_type, "_HighlyConserved_Genes.csv")))
    message("  Found ", nrow(highly_conserved_genes), " genes conserved in ≥2 comparisons")

    highly_conserved[[cell_type]] <- highly_conserved_genes
  }
}

################################################################################
# Analysis 3: Species-Specific Pathway Analysis
################################################################################
message("\n=== Species-Specific Pathway Summary ===")

# Compare enrichment in conserved vs mouse-only gene sets
species_specificity <- list()

for (comp_group in comparison_groups) {
  for (cell_type in schwann_cell_types) {
    base_name <- paste0(comp_group, "_", cell_type)
    enrich_folder <- file.path(enrichment_root, paste0(base_name, "_enrichment"))

    # Count enrichment files for each gene set
    overlap_all3_go <- file.path(enrich_folder, "Overlap_All3_clusterProfiler_GO.csv")
    mouse_only_go <- file.path(enrich_folder, "Mouse_only_clusterProfiler_GO.csv")

    n_conserved_pathways <- 0
    n_mouse_only_pathways <- 0

    if (file.exists(overlap_all3_go)) {
      conserved_enrich <- read.csv(overlap_all3_go, stringsAsFactors = FALSE)
      if ("p.adjust" %in% colnames(conserved_enrich)) {
        n_conserved_pathways <- sum(conserved_enrich$p.adjust < 0.05, na.rm = TRUE)
      }
    }

    if (file.exists(mouse_only_go)) {
      mouse_enrich <- read.csv(mouse_only_go, stringsAsFactors = FALSE)
      if ("p.adjust" %in% colnames(mouse_enrich)) {
        n_mouse_only_pathways <- sum(mouse_enrich$p.adjust < 0.05, na.rm = TRUE)
      }
    }

    if (n_conserved_pathways > 0 || n_mouse_only_pathways > 0) {
      species_specificity[[length(species_specificity) + 1]] <- tibble(
        comparison = comp_group,
        cell_type = cell_type,
        n_conserved_pathways = n_conserved_pathways,
        n_mouse_specific_pathways = n_mouse_only_pathways
      )
    }
  }
}

if (length(species_specificity) > 0) {
  species_df <- dplyr::bind_rows(species_specificity)
  save_df(species_df, file.path(output_dir, "Species_Specificity_Pathways.csv"))

  # Visualize
  plot_data <- species_df %>%
    tidyr::pivot_longer(
      cols = c(n_conserved_pathways, n_mouse_specific_pathways),
      names_to = "category",
      values_to = "count"
    ) %>%
    dplyr::mutate(category = gsub("^n_", "", category) %>% gsub("_", " ", .))

  p5 <- ggplot2::ggplot(plot_data, ggplot2::aes(x = cell_type, y = count, fill = category)) +
    ggplot2::geom_col(position = "dodge") +
    ggplot2::facet_wrap(~ comparison, ncol = 3) +
    ggplot2::theme_bw() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)) +
    ggplot2::labs(
      title = "Conserved vs Mouse-Specific Enriched Pathways",
      x = "Cell Type",
      y = "Number of Enriched Pathways (GO BP, padj < 0.05)",
      fill = "Category"
    )

  save_plot(p5, file.path(output_dir, "Species_Specificity_Pathways.png"), width = 14, height = 10)
  save_plot(p5, file.path(output_dir, "Species_Specificity_Pathways.pdf"), width = 14, height = 10)
}

################################################################################
# Summary Report
################################################################################
message("\n=== Creating Summary Report ===")

wb <- openxlsx::createWorkbook()

if (exists("conservation_df") && nrow(conservation_df) > 0) {
  openxlsx::addWorksheet(wb, "Conservation_Stats")
  openxlsx::writeData(wb, "Conservation_Stats", conservation_df)
}

if (exists("species_df") && nrow(species_df) > 0) {
  openxlsx::addWorksheet(wb, "Species_Specificity")
  openxlsx::writeData(wb, "Species_Specificity", species_df)
}

# Add highly conserved genes sheets
if (length(highly_conserved) > 0) {
  for (cell_type in names(highly_conserved)) {
    sheet_name <- substr(paste0("HighConserved_", cell_type), 1, 31)
    openxlsx::addWorksheet(wb, sheet_name)
    openxlsx::writeData(wb, sheet_name, highly_conserved[[cell_type]])
  }
}

openxlsx::saveWorkbook(wb, file.path(output_dir, "Conservation_Analysis.xlsx"), overwrite = TRUE)

message("\n=== Analysis Complete ===")
message("Output directory: ", output_dir)
message("Check for conservation statistics, highly conserved genes, and pathway comparisons")
