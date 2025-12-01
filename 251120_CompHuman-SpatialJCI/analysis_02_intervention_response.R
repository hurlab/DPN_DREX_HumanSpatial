################################################################################
# Analysis #2: Intervention Response Analysis
#
# Compares DREX vs DR, DREX vs HFD, and EX vs HFD to assess:
# - Exercise-specific effects: Genes rescued by exercise intervention
# - Diet restriction effects: Genes modulated by DR alone
# - Synergistic effects: Genes only changed with combined DREX
################################################################################

if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  script_path <- rstudioapi::getActiveDocumentContext()$path
  setwd(dirname(script_path))
}

options(repos = c(CRAN = "https://cloud.r-project.org"))

if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(
  dplyr, tidyr, ggplot2, ggVennDiagram, tibble, purrr, stringr,
  openxlsx, pheatmap
)

################################################################################
# Settings
################################################################################
enrichment_root <- "Output_JCI_Schwann_enrichment"
output_dir <- "Output_JCI_Schwann_enrichment/Intervention_Response"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# Cell types to analyze
schwann_cell_types <- c("mySC", "nmSC", "ImmSC", "SC3", "majorSC")

# Intervention comparisons
intervention_comparisons <- list(
  DREX_effect = c("DREXvsDR", "DREXvsHFD"),
  DR_effect = c("DRvsHFD", "DRvsSD"),
  EX_effect = c("EXvsHFD", "EXvsDREX")
)

# Focus on these gene sets
focus_sets <- c("Mouse_all", "Overlap_MS", "Overlap_All3")

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
    genes <- df[[1]]  # First column should be genes
    genes <- genes[!is.na(genes) & genes != ""]
    unique(genes)
  }, error = function(e) character(0))
}

################################################################################
# Main Analysis
################################################################################
message("=== Intervention Response Analysis ===")

# Collect gene lists for all intervention comparisons
all_gene_lists <- list()

for (cell_type in schwann_cell_types) {
  message("\n--- Cell Type: ", cell_type, " ---")

  for (intervention in names(intervention_comparisons)) {
    comparisons <- intervention_comparisons[[intervention]]

    for (gene_set in focus_sets) {
      gene_lists <- list()

      for (comp in comparisons) {
        base_name <- paste0(comp, "_", cell_type)
        enrich_folder <- file.path(enrichment_root, paste0(base_name, "_enrichment"))
        gene_file <- file.path(enrich_folder, paste0(gene_set, "_Genes.csv"))

        genes <- read_gene_list(gene_file)

        if (length(genes) > 0) {
          gene_lists[[comp]] <- genes
          message("  ", comp, " ", gene_set, ": ", length(genes), " genes")
        }
      }

      if (length(gene_lists) > 0) {
        all_gene_lists[[paste0(cell_type, "_", intervention, "_", gene_set)]] <- gene_lists
      }
    }
  }
}

################################################################################
# Analysis 1: Venn Diagrams for Each Intervention
################################################################################
message("\n=== Creating Intervention-Specific Venn Diagrams ===")

for (cell_type in schwann_cell_types) {
  for (gene_set in focus_sets) {

    # DREX vs DR vs HFD comparison
    drex_dr_key <- paste0(cell_type, "_DREX_effect_", gene_set)
    if (drex_dr_key %in% names(all_gene_lists)) {
      gene_lists <- all_gene_lists[[drex_dr_key]]

      if (length(gene_lists) >= 2) {
        venn_title <- paste0(cell_type, " ", gene_set, "\nDREX Intervention Effect")
        venn_path <- file.path(output_dir, paste0(cell_type, "_", gene_set, "_DREX_Venn"))

        tryCatch({
          p <- ggVennDiagram::ggVennDiagram(gene_lists, label_alpha = 0) +
            ggplot2::ggtitle(venn_title) +
            ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5, size = 14, face = "bold"))
          ggplot2::ggsave(paste0(venn_path, ".png"), plot = p, width = 8, height = 6, dpi = 300)
          ggplot2::ggsave(paste0(venn_path, ".pdf"), plot = p, width = 8, height = 6, dpi = 300)
          message("  Created DREX Venn: ", cell_type, " ", gene_set)
        }, error = function(e) message("  Error creating Venn: ", e$message))
      }
    }

    # DR effect comparison
    dr_key <- paste0(cell_type, "_DR_effect_", gene_set)
    if (dr_key %in% names(all_gene_lists)) {
      gene_lists <- all_gene_lists[[dr_key]]

      if (length(gene_lists) >= 2) {
        venn_title <- paste0(cell_type, " ", gene_set, "\nDR Intervention Effect")
        venn_path <- file.path(output_dir, paste0(cell_type, "_", gene_set, "_DR_Venn"))

        tryCatch({
          p <- ggVennDiagram::ggVennDiagram(gene_lists, label_alpha = 0) +
            ggplot2::ggtitle(venn_title) +
            ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5, size = 14, face = "bold"))
          ggplot2::ggsave(paste0(venn_path, ".png"), plot = p, width = 8, height = 6, dpi = 300)
          ggplot2::ggsave(paste0(venn_path, ".pdf"), plot = p, width = 8, height = 6, dpi = 300)
          message("  Created DR Venn: ", cell_type, " ", gene_set)
        }, error = function(e) message("  Error creating Venn: ", e$message))
      }
    }

    # EX effect comparison
    ex_key <- paste0(cell_type, "_EX_effect_", gene_set)
    if (ex_key %in% names(all_gene_lists)) {
      gene_lists <- all_gene_lists[[ex_key]]

      if (length(gene_lists) >= 2) {
        venn_title <- paste0(cell_type, " ", gene_set, "\nExercise Intervention Effect")
        venn_path <- file.path(output_dir, paste0(cell_type, "_", gene_set, "_EX_Venn"))

        tryCatch({
          p <- ggVennDiagram::ggVennDiagram(gene_lists, label_alpha = 0) +
            ggplot2::ggtitle(venn_title) +
            ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5, size = 14, face = "bold"))
          ggplot2::ggsave(paste0(venn_path, ".png"), plot = p, width = 8, height = 6, dpi = 300)
          ggplot2::ggsave(paste0(venn_path, ".pdf"), plot = p, width = 8, height = 6, dpi = 300)
          message("  Created EX Venn: ", cell_type, " ", gene_set)
        }, error = function(e) message("  Error creating Venn: ", e$message))
      }
    }
  }
}

################################################################################
# Analysis 2: Intervention-Specific and Shared Genes
################################################################################
message("\n=== Identifying Intervention-Specific vs Shared Genes ===")

intervention_summary <- list()

for (cell_type in schwann_cell_types) {
  for (gene_set in focus_sets) {

    # Get DREX, DR, and EX gene sets for comparison
    drex_vs_hfd <- read_gene_list(file.path(enrichment_root, paste0("DREXvsHFD_", cell_type, "_enrichment"), paste0(gene_set, "_Genes.csv")))
    dr_vs_hfd <- read_gene_list(file.path(enrichment_root, paste0("DRvsHFD_", cell_type, "_enrichment"), paste0(gene_set, "_Genes.csv")))
    ex_vs_hfd <- read_gene_list(file.path(enrichment_root, paste0("EXvsHFD_", cell_type, "_enrichment"), paste0(gene_set, "_Genes.csv")))

    if (length(drex_vs_hfd) == 0 && length(dr_vs_hfd) == 0 && length(ex_vs_hfd) == 0) next

    # Calculate overlaps
    drex_specific <- setdiff(drex_vs_hfd, union(dr_vs_hfd, ex_vs_hfd))
    dr_specific <- setdiff(dr_vs_hfd, union(drex_vs_hfd, ex_vs_hfd))
    ex_specific <- setdiff(ex_vs_hfd, union(drex_vs_hfd, dr_vs_hfd))

    drex_dr_shared <- intersect(drex_vs_hfd, dr_vs_hfd)
    drex_ex_shared <- intersect(drex_vs_hfd, ex_vs_hfd)
    dr_ex_shared <- intersect(dr_vs_hfd, ex_vs_hfd)

    all_three_shared <- Reduce(intersect, list(drex_vs_hfd, dr_vs_hfd, ex_vs_hfd))

    # Save gene lists
    out_folder <- file.path(output_dir, paste0(cell_type, "_", gene_set, "_InterventionSets"))
    dir.create(out_folder, showWarnings = FALSE, recursive = TRUE)

    if (length(drex_specific) > 0) save_df(tibble(Gene = sort(drex_specific)), file.path(out_folder, "DREX_specific.csv"))
    if (length(dr_specific) > 0) save_df(tibble(Gene = sort(dr_specific)), file.path(out_folder, "DR_specific.csv"))
    if (length(ex_specific) > 0) save_df(tibble(Gene = sort(ex_specific)), file.path(out_folder, "EX_specific.csv"))
    if (length(drex_dr_shared) > 0) save_df(tibble(Gene = sort(drex_dr_shared)), file.path(out_folder, "DREX_DR_shared.csv"))
    if (length(drex_ex_shared) > 0) save_df(tibble(Gene = sort(drex_ex_shared)), file.path(out_folder, "DREX_EX_shared.csv"))
    if (length(dr_ex_shared) > 0) save_df(tibble(Gene = sort(dr_ex_shared)), file.path(out_folder, "DR_EX_shared.csv"))
    if (length(all_three_shared) > 0) save_df(tibble(Gene = sort(all_three_shared)), file.path(out_folder, "All_Interventions_shared.csv"))

    # Record summary
    intervention_summary[[length(intervention_summary) + 1]] <- tibble(
      cell_type = cell_type,
      gene_set = gene_set,
      n_DREX_vs_HFD = length(drex_vs_hfd),
      n_DR_vs_HFD = length(dr_vs_hfd),
      n_EX_vs_HFD = length(ex_vs_hfd),
      n_DREX_specific = length(drex_specific),
      n_DR_specific = length(dr_specific),
      n_EX_specific = length(ex_specific),
      n_DREX_DR_shared = length(drex_dr_shared),
      n_DREX_EX_shared = length(drex_ex_shared),
      n_DR_EX_shared = length(dr_ex_shared),
      n_All_shared = length(all_three_shared)
    )

    message("  ", cell_type, " ", gene_set, ": DREX-specific=", length(drex_specific),
            ", DR-specific=", length(dr_specific), ", EX-specific=", length(ex_specific),
            ", All-shared=", length(all_three_shared))
  }
}

# Save summary table
if (length(intervention_summary) > 0) {
  summary_df <- dplyr::bind_rows(intervention_summary)
  save_df(summary_df, file.path(output_dir, "Intervention_Response_Summary.csv"))

  # Create visualizations of summary
  for (gene_set in focus_sets) {
    plot_data <- summary_df %>%
      dplyr::filter(gene_set == !!gene_set) %>%
      tidyr::pivot_longer(
        cols = starts_with("n_"),
        names_to = "category",
        values_to = "count"
      ) %>%
      dplyr::mutate(category = gsub("^n_", "", category))

    if (nrow(plot_data) == 0) next

    p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = cell_type, y = count, fill = category)) +
      ggplot2::geom_col(position = "dodge") +
      ggplot2::theme_bw() +
      ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)) +
      ggplot2::labs(
        title = paste0("Intervention Response: ", gene_set),
        x = "Cell Type",
        y = "Number of Genes",
        fill = "Category"
      )

    save_plot(p, file.path(output_dir, paste0("Intervention_Summary_", gene_set, ".png")), width = 12, height = 8)
  }
}

################################################################################
# Analysis 3: Exercise-Specific Rescue Analysis
################################################################################
message("\n=== Exercise-Specific Rescue Analysis ===")

# Compare EX vs DREX to identify exercise-unique effects (beyond DR)
exercise_rescue <- list()

for (cell_type in schwann_cell_types) {
  for (gene_set in focus_sets) {

    ex_vs_hfd <- read_gene_list(file.path(enrichment_root, paste0("EXvsHFD_", cell_type, "_enrichment"), paste0(gene_set, "_Genes.csv")))
    drex_vs_hfd <- read_gene_list(file.path(enrichment_root, paste0("DREXvsHFD_", cell_type, "_enrichment"), paste0(gene_set, "_Genes.csv")))
    dr_vs_hfd <- read_gene_list(file.path(enrichment_root, paste0("DRvsHFD_", cell_type, "_enrichment"), paste0(gene_set, "_Genes.csv")))

    if (length(ex_vs_hfd) == 0) next

    # Genes changed by EX but not DR (exercise-specific)
    ex_not_dr <- setdiff(ex_vs_hfd, dr_vs_hfd)

    # Genes changed by both EX and DR (synergistic)
    ex_and_dr <- intersect(ex_vs_hfd, dr_vs_hfd)

    # Genes only in DREX (combined intervention unique)
    drex_unique <- setdiff(drex_vs_hfd, union(ex_vs_hfd, dr_vs_hfd))

    out_folder <- file.path(output_dir, paste0(cell_type, "_", gene_set, "_ExerciseRescue"))
    dir.create(out_folder, showWarnings = FALSE, recursive = TRUE)

    if (length(ex_not_dr) > 0) save_df(tibble(Gene = sort(ex_not_dr)), file.path(out_folder, "Exercise_specific_not_DR.csv"))
    if (length(ex_and_dr) > 0) save_df(tibble(Gene = sort(ex_and_dr)), file.path(out_folder, "Exercise_and_DR_synergistic.csv"))
    if (length(drex_unique) > 0) save_df(tibble(Gene = sort(drex_unique)), file.path(out_folder, "DREX_combined_unique.csv"))

    exercise_rescue[[length(exercise_rescue) + 1]] <- tibble(
      cell_type = cell_type,
      gene_set = gene_set,
      n_EX_total = length(ex_vs_hfd),
      n_EX_not_DR = length(ex_not_dr),
      n_EX_and_DR = length(ex_and_dr),
      n_DREX_unique = length(drex_unique)
    )

    message("  ", cell_type, " ", gene_set, ": EX-specific=", length(ex_not_dr),
            ", EX+DR synergy=", length(ex_and_dr), ", DREX-unique=", length(drex_unique))
  }
}

if (length(exercise_rescue) > 0) {
  rescue_df <- dplyr::bind_rows(exercise_rescue)
  save_df(rescue_df, file.path(output_dir, "Exercise_Rescue_Summary.csv"))
}

################################################################################
# Summary Report
################################################################################
message("\n=== Creating Summary Report ===")

wb <- openxlsx::createWorkbook()

if (exists("summary_df") && nrow(summary_df) > 0) {
  openxlsx::addWorksheet(wb, "Intervention_Summary")
  openxlsx::writeData(wb, "Intervention_Summary", summary_df)
}

if (exists("rescue_df") && nrow(rescue_df) > 0) {
  openxlsx::addWorksheet(wb, "Exercise_Rescue")
  openxlsx::writeData(wb, "Exercise_Rescue", rescue_df)
}

openxlsx::saveWorkbook(wb, file.path(output_dir, "Intervention_Response_Analysis.xlsx"), overwrite = TRUE)

message("\n=== Analysis Complete ===")
message("Output directory: ", output_dir)
message("Check for Venn diagrams, gene lists, and summary statistics")
