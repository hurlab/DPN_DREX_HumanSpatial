################################################################################
# Analysis #2: DEG Overlap Analysis - Mouse vs Cibersort Human DEGs
#
# This script compares the Cibersort-derived human Schwann cell DEGs (C vs DPN)
# with mouse scRNA-seq DEGs across Schwann cell populations.
#
# Mouse cell types included: mySC, nmSC, ImmSC, majorSC, aggSC
# Comparisons included: HFDvsSD, DRvsHFD, EXvsHFD, DREXvsHFD
#
# Outputs:
# - Overlap gene sets for each mouse comparison/cell type
# - Venn diagrams
# - Summary tables and statistics
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
  dplyr, tidyr, ggplot2, openxlsx, tibble, stringr, purrr,
  ggVennDiagram, homologene
)

################################################################################
# Settings
################################################################################
# Input files
cibersort_file <- "DEGs_SchwannCells_C_vs_DPN.xlsx"
mouse_deg_dirs <- c("../DEG", "../DEG_Major", "../251120_CompHuman-SpatialJCI/DEGs_aggSC")
padj_cutoff_human <- 0.05
pval_cutoff_mouse <- 0.01

# Schwann cell types to analyze
schwann_cell_types <- c("mySC", "nmSC", "ImmSC", "majorSC", "aggSC")

# Comparison groups to analyze
comparison_groups <- c("HFDvsSD", "DRvsHFD", "EXvsHFD", "DREXvsHFD")

# Minimum genes for reporting
min_genes_for_report <- 1

# Output directory
output_dir <- "Output_260107/02_Overlap_Mouse_Cibersort"
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

save_venn <- function(set_list, title, out_path) {
  if (length(set_list) < 2 || length(set_list) > 5) {
    warning("Venn diagrams require 2-5 sets")
    return(NULL)
  }
  dir.create(dirname(out_path), showWarnings = FALSE, recursive = TRUE)

  p <- ggVennDiagram::ggVennDiagram(set_list, label_alpha = 0,
                                     set_color = "black", set_size = 4,
                                     edge_size = 1) +
    ggplot2::scale_fill_gradient(low = "#FFFFCC", high = "#87CEEB") +
    ggplot2::scale_color_manual(values = rep("grey30", length(set_list))) +
    ggplot2::ggtitle(title) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(hjust = 0.5, size = 14, face = "bold"),
      text = ggplot2::element_text(size = 12, color = "black")
    )

  ggplot2::ggsave(paste0(out_path, ".png"), plot = p, width = 8, height = 6, dpi = 300)
  ggplot2::ggsave(paste0(out_path, ".pdf"), plot = p, width = 8, height = 6, dpi = 300)
  invisible(p)
}

read_cibersort_deg <- function(file_path, padj_cutoff = 0.05) {
  df <- openxlsx::read.xlsx(file_path, detectDates = FALSE)
  cn <- tolower(gsub("\\s+", "_", colnames(df)))
  colnames(df) <- cn

  df %>%
    dplyr::filter(!is.na(gene), gene != "") %>%
    dplyr::filter(adj.p.val < padj_cutoff) %>%
    dplyr::pull(gene)
}

read_mouse_deg_file <- function(file_path) {
  df <- suppressWarnings(read.csv(file_path, stringsAsFactors = FALSE, check.names = FALSE))

  # Handle empty first column
  if (is.na(colnames(df)[1]) || colnames(df)[1] == "" || colnames(df)[1] %in% c("X", "...1")) {
    colnames(df)[1] <- "Gene"
  } else {
    colnames(df)[1] <- "Gene"
  }

  cn <- tolower(gsub("\\s+", "_", colnames(df)))
  colnames(df) <- cn

  # Check required columns
  pval_col <- "p_val"
  lfc_col <- if ("avg_log2fc" %in% cn) "avg_log2fc" else if ("log2foldchange" %in% cn) "log2foldchange" else NULL

  if (!pval_col %in% cn || is.null(lfc_col) || !lfc_col %in% cn) {
    return(character(0))
  }

  df %>%
    dplyr::filter(!is.na(gene), gene != "") %>%
    dplyr::filter(.data[[pval_col]] < pval_cutoff_mouse) %>%
    dplyr::distinct(gene) %>%
    dplyr::pull()
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
message("=== DEG Overlap Analysis: Mouse vs Cibersort Human DEGs ===")

# Load Cibersort human DEGs and map to mouse
message("\nLoading Cibersort human DEGs...")
cibersort_human <- read_cibersort_deg(cibersort_file, padj_cutoff = padj_cutoff_human)
message("  Total Cibersort DEGs (adj.P.Val < ", padj_cutoff_human, "): ", length(cibersort_human))

# Map to mouse orthologs
human2mouse <- build_human_to_mouse_map()
cibersort_mouse <- map_genes_to_mouse(cibersort_human, human2mouse)
message("  Mapped to mouse orthologs: ", length(cibersort_mouse))

# Save mapping info
save_df(tibble(Gene = sort(unique(cibersort_human))), file.path(output_dir, "Cibersort_Human_Genes.csv"))
save_df(tibble(Gene = sort(unique(cibersort_mouse))), file.path(output_dir, "Cibersort_Mouse_Genes.csv"))

################################################################################
# Process Mouse DEG Files
################################################################################
message("\n=== Processing Mouse scRNA-seq DEG Files ===")

all_summaries <- list()
all_overlaps <- list()

for (input_dir in mouse_deg_dirs) {
  if (!dir.exists(input_dir)) {
    message("  Skipping non-existent directory: ", input_dir)
    next
  }

  files <- list.files(input_dir, pattern = "\\.csv$", full.names = TRUE, recursive = FALSE)
  files <- files[!basename(files) %>% startsWith(".")]
  files <- files[!grepl("spia", basename(files), ignore.case = TRUE)]

  # Filter for Schwann cells and comparison groups
  files <- files[sapply(files, function(f) {
    base <- safe_base(tools::file_path_sans_ext(basename(f)))
    parts <- strsplit(base, "_", fixed = TRUE)[[1]]
    comp_group <- if (length(parts) >= 1) parts[1] else NA_character_
    cell_type <- if (length(parts) >= 2) parts[2] else NA_character_

    cell_pass <- !is.na(cell_type) && cell_type %in% schwann_cell_types
    comp_pass <- !is.na(comp_group) && comp_group %in% comparison_groups

    cell_pass && comp_pass
  })]

  if (length(files) == 0) {
    message("  No matching files in: ", input_dir)
    next
  }

  message("  Processing ", length(files), " file(s) from ", basename(input_dir))

  for (mouse_file in files) {
    base <- safe_base(tools::file_path_sans_ext(basename(mouse_file)))
    parts <- strsplit(base, "_", fixed = TRUE)[[1]]
    comp_group <- parts[1]
    cell_type <- parts[2]

    message("    - ", comp_group, " ", cell_type)

    # Read mouse DEGs
    mouse_genes <- read_mouse_deg_file(mouse_file)
    if (length(mouse_genes) == 0) {
      message("      Skipping (no usable genes)")
      next
    }

    # Calculate overlap
    overlap_genes <- intersect(mouse_genes, cibersort_mouse)
    mouse_only <- setdiff(mouse_genes, cibersort_mouse)
    cibersort_only <- setdiff(cibersort_mouse, mouse_genes)

    message("      Mouse DEGs: ", length(mouse_genes))
    message("      Overlap: ", length(overlap_genes))

    # Save gene lists
    per_out <- file.path(output_dir, paste0(base, "_overlap"))
    dir.create(per_out, showWarnings = FALSE, recursive = TRUE)

    save_df(tibble(Gene = sort(unique(mouse_genes))), file.path(per_out, "Mouse_all_Genes.csv"))
    save_df(tibble(Gene = sort(unique(overlap_genes))), file.path(per_out, "Overlap_Genes.csv"))
    save_df(tibble(Gene = sort(unique(mouse_only))), file.path(per_out, "Mouse_only_Genes.csv"))
    save_df(tibble(Gene = sort(unique(cibersort_only))), file.path(per_out, "Cibersort_only_Genes.csv"))

    # Create Venn diagram
    venn_list <- list(
      Mouse = mouse_genes,
      Cibersort = cibersort_mouse
    )
    venn_title <- paste0(comp_group, " ", cell_type, ": Mouse vs Cibersort")
    venn_path <- file.path(per_out, "Venn_Diagram")
    save_venn(venn_list, venn_title, venn_path)

    # Store summary
    all_summaries[[length(all_summaries) + 1]] <- tibble(
      comparison = comp_group,
      cell_type = cell_type,
      n_mouse = length(mouse_genes),
      n_cibersort = length(cibersort_mouse),
      n_overlap = length(overlap_genes),
      overlap_pct_mouse = round(100 * length(overlap_genes) / length(mouse_genes), 2),
      overlap_pct_cibersort = round(100 * length(overlap_genes) / length(cibersort_mouse), 2)
    )

    # Store overlap genes
    if (length(overlap_genes) > 0) {
      all_overlaps[[base]] <- tibble(
        comparison = comp_group,
        cell_type = cell_type,
        gene = overlap_genes
      )
    }
  }
}

################################################################################
# Create Summary Tables
################################################################################
message("\n=== Creating Summary Tables ===")

if (length(all_summaries) > 0) {
  summary_df <- dplyr::bind_rows(all_summaries) %>%
    dplyr::arrange(dplyr::desc(n_overlap))

  save_df(summary_df, file.path(output_dir, "Overlap_Summary.csv"))

  message("\nOverlap Summary:")
  print(summary_df)
}

################################################################################
# Create Master Overlap Gene List
################################################################################
message("\n=== Creating Master Overlap Gene List ===")

if (length(all_overlaps) > 0) {
  all_overlap_genes <- dplyr::bind_rows(all_overlaps)

  # Count how many comparisons each gene appears in
  gene_counts <- all_overlap_genes %>%
    dplyr::group_by(gene) %>%
    dplyr::summarise(
      n_comparisons = n(),
      comparisons = paste(unique(paste(comparison, cell_type, sep = "_")), collapse = "; "),
      .groups = "drop"
    ) %>%
    dplyr::arrange(desc(n_comparisons), gene)

  save_df(gene_counts, file.path(output_dir, "Master_Overlap_Genes.csv"))

  message("\nTop overlapping genes:")
  print(head(gene_counts, 20))
}

################################################################################
# Create Excel Workbook
################################################################################
message("\n=== Creating Excel Workbook ===")

if (length(all_summaries) > 0) {
  wb <- openxlsx::createWorkbook()

  # Summary sheet
  openxlsx::addWorksheet(wb, "Overlap_Summary")
  openxlsx::writeData(wb, "Overlap_Summary", summary_df)

  # Master overlap genes
  if (length(all_overlaps) > 0) {
    openxlsx::addWorksheet(wb, "Master_Overlap_Genes")
    openxlsx::writeData(wb, "Master_Overlap_Genes", gene_counts)
  }

  # Per-comparison sheets
  for (i in seq_len(nrow(summary_df))) {
    comp <- summary_df$comparison[i]
    ct <- summary_df$cell_type[i]
    base <- paste0(comp, "_", ct)

    overlap_file <- file.path(output_dir, paste0(base, "_overlap", "Overlap_Genes.csv"))
    if (file.exists(overlap_file)) {
      sheet_name <- safe_base(paste0(comp, "_", ct), limit = 31)
      openxlsx::addWorksheet(wb, sheet_name)
      overlap_df <- read.csv(overlap_file)
      openxlsx::writeData(wb, sheet_name, overlap_df)
    }
  }

  output_excel <- file.path(output_dir, "Overlap_Summary.xlsx")
  openxlsx::saveWorkbook(wb, output_excel, overwrite = TRUE)
  message("  Excel workbook saved: ", output_excel)
}

################################################################################
# Final Report
################################################################################
message("\n=== Analysis Complete ===")
message("Output directory: ", output_dir)
message("\nResults:")
message("  - Overlap summary tables")
message("  - Venn diagrams for each comparison")
message("  - Master overlap gene list")
message("  - Excel summary workbook")

if (length(all_summaries) > 0) {
  message("\nKey findings:")
  message("  - Total mouse comparisons analyzed: ", nrow(summary_df))
  message("  - Maximum overlap: ", max(summary_df$n_overlap), " genes")
  message("  - Mean overlap: ", round(mean(summary_df$n_overlap), 1), " genes")
  message("  - Comparison with highest overlap: ",
          summary_df$comparison[which.max(summary_df$n_overlap)], " ",
          summary_df$cell_type[which.max(summary_df$n_overlap)])
}
