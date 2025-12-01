################################################################################
# Analysis #4: Direction-of-Change Analysis
#
# Analyzes whether DEGs change in the same direction across species:
# - Concordant DEGs: Same direction in mouse and human (both up or both down)
# - Discordant DEGs: Opposite directions (mouse up, human down or vice versa)
#
# This requires reading the full DEG files with log2FC values
################################################################################

if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  script_path <- rstudioapi::getActiveDocumentContext()$path
  setwd(dirname(script_path))
}

options(repos = c(CRAN = "https://cloud.r-project.org"))

if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(
  dplyr, tidyr, ggplot2, tibble, purrr, stringr,
  openxlsx, homologene, readxl
)

################################################################################
# Settings
################################################################################
schwann_deg_path <- "./DEGs_JCI_DPN/SchwannDEG_Severe-Moderate_noMito.csv"
jci_deg_path     <- "./DEGs_JCI_DPN/JCI184075.sdd3_BulkRNAseqDEGs.xlsx"
jci_deg_sheet    <- "deseq2_results"

mouse_deg_dirs <- c("../DEG", "../DEG_Major")
output_dir <- "Output_JCI/Direction_Analysis"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# Schwann cell types
schwann_cell_types <- c("mySC", "nmSC", "ImmSC", "majorSC")

# Comparison groups filter
comparison_groups <- c("HFDvsSD", "DRvsHFD", "EXvsHFD", "DREXvsHFD")

# Thresholds
padj_cutoff <- 0.05
lfc_cutoff <- 0  # Use 0 to include all significant genes, or 1 for stringent

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

# Read human Schwann DEGs with log2FC
read_schwann_deg_with_lfc <- function(file_path) {
  df <- suppressWarnings(read.csv(file_path, stringsAsFactors = FALSE, check.names = FALSE))
  if (!"Gene" %in% colnames(df)) colnames(df)[1] <- "Gene"
  cn <- tolower(gsub("\\s+", "_", colnames(df)))
  colnames(df) <- cn

  gene_col <- "gene"
  lfc_col  <- if ("avg_log2fc" %in% cn) "avg_log2fc" else if ("log2foldchange" %in% cn) "log2foldchange" else stop("Cannot find log2FC")
  padj_col <- if ("p_val_adj" %in% cn) "p_val_adj" else if ("padj" %in% cn) "padj" else stop("Cannot find padj")

  df %>%
    dplyr::filter(!is.na(.data[[gene_col]]), .data[[gene_col]] != "") %>%
    dplyr::transmute(
      Human_Symbol = as.character(.data[[gene_col]]),
      Human_log2FC = .data[[lfc_col]],
      Human_padj = .data[[padj_col]]
    ) %>%
    dplyr::distinct(Human_Symbol, .keep_all = TRUE)
}

# Read JCI bulk DEGs with log2FC
read_jci_bulk_deg_with_lfc <- function(file_path, sheet = "deseq2_results") {
  df <- suppressWarnings(readxl::read_excel(file_path, sheet = sheet))
  cn <- tolower(gsub("\\s+", "_", colnames(df)))
  colnames(df) <- cn

  gene_col <- if ("gene" %in% cn) "gene" else stop("Cannot find 'Gene' column")
  lfc_col  <- if ("log2foldchange" %in% cn) "log2foldchange" else stop("Cannot find log2FoldChange")
  padj_col <- if ("padj" %in% cn) "padj" else stop("Cannot find padj")

  df %>%
    dplyr::filter(!is.na(.data[[gene_col]]), .data[[gene_col]] != "") %>%
    dplyr::transmute(
      Human_Symbol = as.character(.data[[gene_col]]),
      Human_log2FC = .data[[lfc_col]],
      Human_padj = .data[[padj_col]]
    ) %>%
    dplyr::distinct(Human_Symbol, .keep_all = TRUE)
}

# Read mouse DEG files with log2FC
read_mouse_deg_with_lfc <- function(file_path) {
  df <- suppressWarnings(read.csv(file_path, stringsAsFactors = FALSE, check.names = FALSE))
  if (is.na(colnames(df)[1]) || colnames(df)[1] == "" || colnames(df)[1] %in% c("X", "...1")) {
    colnames(df)[1] <- "Gene"
  } else {
    colnames(df)[1] <- "Gene"
  }
  cn <- tolower(gsub("\\s+", "_", colnames(df)))
  colnames(df) <- cn

  padj_col <- "p_val_adj"
  lfc_col  <- if ("avg_log2fc" %in% cn) "avg_log2fc" else if ("log2foldchange" %in% cn) "log2foldchange" else NULL

  if (!padj_col %in% cn || is.null(lfc_col) || !lfc_col %in% cn) return(NULL)

  df %>%
    dplyr::filter(!is.na(gene), gene != "") %>%
    dplyr::transmute(
      Mouse_Symbol = as.character(gene),
      Mouse_log2FC = .data[[lfc_col]],
      Mouse_padj = .data[[padj_col]]
    ) %>%
    dplyr::distinct(Mouse_Symbol, .keep_all = TRUE)
}

################################################################################
# Load human datasets
################################################################################
message("=== Loading Human Datasets ===")

human2mouse <- build_human_to_mouse_map()

schwann_deg <- read_schwann_deg_with_lfc(schwann_deg_path) %>%
  dplyr::left_join(human2mouse, by = "Human_Symbol") %>%
  dplyr::filter(!is.na(Mouse_Symbol)) %>%
  dplyr::distinct(Mouse_Symbol, .keep_all = TRUE)

jci_bulk_deg <- read_jci_bulk_deg_with_lfc(jci_deg_path, sheet = jci_deg_sheet) %>%
  dplyr::left_join(human2mouse, by = "Human_Symbol") %>%
  dplyr::filter(!is.na(Mouse_Symbol)) %>%
  dplyr::distinct(Mouse_Symbol, .keep_all = TRUE)

message("Schwann DEGs mapped to mouse: ", nrow(schwann_deg))
message("JCI bulk DEGs mapped to mouse: ", nrow(jci_bulk_deg))

################################################################################
# Main Analysis
################################################################################
message("\n=== Direction-of-Change Analysis ===")

all_results <- list()

for (input_dir in mouse_deg_dirs) {
  files <- list.files(input_dir, pattern = "\\.csv$", full.names = TRUE, recursive = FALSE)
  files <- files[!basename(files) %>% startsWith(".")]
  files <- files[!grepl("spia", basename(files), ignore.case = TRUE)]

  # Filter for Schwann cells only
  files <- files[sapply(files, function(f) {
    parts <- strsplit(safe_base(tools::file_path_sans_ext(basename(f))), "_", fixed = TRUE)[[1]]
    comp_group <- if (length(parts) >= 1) parts[1] else NA_character_
    cell_type <- if (length(parts) >= 2) parts[2] else NA_character_

    # Check both cell type and comparison group filters
    cell_pass <- !is.na(cell_type) && cell_type %in% schwann_cell_types
    comp_pass <- !is.na(comp_group) && comp_group %in% comparison_groups

    cell_pass && comp_pass
  })]

  message("\n--- Folder: ", input_dir, " ---")

  for (mouse_file in files) {
    base <- safe_base(tools::file_path_sans_ext(basename(mouse_file)))
    parts <- strsplit(base, "_", fixed = TRUE)[[1]]
    comp_group <- if (length(parts) >= 1) parts[1] else NA_character_
    cell_type  <- if (length(parts) >= 2) parts[2] else NA_character_

    message("  Processing: ", basename(mouse_file))

    mouse_deg <- read_mouse_deg_with_lfc(mouse_file)
    if (is.null(mouse_deg) || nrow(mouse_deg) == 0) {
      message("    Skipping (no data)")
      next
    }

    # Filter by padj
    mouse_deg <- mouse_deg %>% dplyr::filter(Mouse_padj < padj_cutoff)

    # Merge with Schwann data
    merged_schwann <- mouse_deg %>%
      dplyr::inner_join(schwann_deg, by = "Mouse_Symbol") %>%
      dplyr::filter(Human_padj < padj_cutoff) %>%
      dplyr::mutate(
        Mouse_direction = dplyr::case_when(
          Mouse_log2FC > lfc_cutoff ~ "Up",
          Mouse_log2FC < -lfc_cutoff ~ "Down",
          TRUE ~ "No change"
        ),
        Human_direction = dplyr::case_when(
          Human_log2FC > lfc_cutoff ~ "Up",
          Human_log2FC < -lfc_cutoff ~ "Down",
          TRUE ~ "No change"
        ),
        concordance = dplyr::case_when(
          Mouse_direction == Human_direction ~ "Concordant",
          Mouse_direction == "No change" | Human_direction == "No change" ~ "Ambiguous",
          TRUE ~ "Discordant"
        )
      )

    # Merge with JCI data
    merged_jci <- mouse_deg %>%
      dplyr::inner_join(jci_bulk_deg, by = "Mouse_Symbol") %>%
      dplyr::filter(Human_padj < padj_cutoff) %>%
      dplyr::mutate(
        Mouse_direction = dplyr::case_when(
          Mouse_log2FC > lfc_cutoff ~ "Up",
          Mouse_log2FC < -lfc_cutoff ~ "Down",
          TRUE ~ "No change"
        ),
        Human_direction = dplyr::case_when(
          Human_log2FC > lfc_cutoff ~ "Up",
          Human_log2FC < -lfc_cutoff ~ "Down",
          TRUE ~ "No change"
        ),
        concordance = dplyr::case_when(
          Mouse_direction == Human_direction ~ "Concordant",
          Mouse_direction == "No change" | Human_direction == "No change" ~ "Ambiguous",
          TRUE ~ "Discordant"
        )
      )

    # Save detailed results
    out_folder <- file.path(output_dir, paste0(base, "_direction"))
    dir.create(out_folder, showWarnings = FALSE, recursive = TRUE)

    if (nrow(merged_schwann) > 0) {
      save_df(merged_schwann, file.path(out_folder, "Mouse_Schwann_direction.csv"))

      # Save concordant and discordant separately
      concordant_schwann <- merged_schwann %>% dplyr::filter(concordance == "Concordant")
      discordant_schwann <- merged_schwann %>% dplyr::filter(concordance == "Discordant")

      if (nrow(concordant_schwann) > 0) save_df(concordant_schwann, file.path(out_folder, "Concordant_Schwann.csv"))
      if (nrow(discordant_schwann) > 0) save_df(discordant_schwann, file.path(out_folder, "Discordant_Schwann.csv"))
    }

    if (nrow(merged_jci) > 0) {
      save_df(merged_jci, file.path(out_folder, "Mouse_JCI_direction.csv"))

      concordant_jci <- merged_jci %>% dplyr::filter(concordance == "Concordant")
      discordant_jci <- merged_jci %>% dplyr::filter(concordance == "Discordant")

      if (nrow(concordant_jci) > 0) save_df(concordant_jci, file.path(out_folder, "Concordant_JCI.csv"))
      if (nrow(discordant_jci) > 0) save_df(discordant_jci, file.path(out_folder, "Discordant_JCI.csv"))
    }

    # Summary statistics
    all_results[[length(all_results) + 1]] <- tibble(
      comparison = comp_group,
      cell_type = cell_type,
      n_overlap_schwann = nrow(merged_schwann),
      n_concordant_schwann = sum(merged_schwann$concordance == "Concordant", na.rm = TRUE),
      n_discordant_schwann = sum(merged_schwann$concordance == "Discordant", na.rm = TRUE),
      pct_concordant_schwann = if (nrow(merged_schwann) > 0) round(100 * sum(merged_schwann$concordance == "Concordant", na.rm = TRUE) / nrow(merged_schwann), 1) else NA,
      n_overlap_jci = nrow(merged_jci),
      n_concordant_jci = sum(merged_jci$concordance == "Concordant", na.rm = TRUE),
      n_discordant_jci = sum(merged_jci$concordance == "Discordant", na.rm = TRUE),
      pct_concordant_jci = if (nrow(merged_jci) > 0) round(100 * sum(merged_jci$concordance == "Concordant", na.rm = TRUE) / nrow(merged_jci), 1) else NA
    )

    message("    Schwann: ", nrow(merged_schwann), " overlap, ",
            sum(merged_schwann$concordance == "Concordant", na.rm = TRUE), " concordant, ",
            sum(merged_schwann$concordance == "Discordant", na.rm = TRUE), " discordant")
    message("    JCI: ", nrow(merged_jci), " overlap, ",
            sum(merged_jci$concordance == "Concordant", na.rm = TRUE), " concordant, ",
            sum(merged_jci$concordance == "Discordant", na.rm = TRUE), " discordant")
  }
}

################################################################################
# Summary and Visualization
################################################################################
if (length(all_results) > 0) {
  summary_df <- dplyr::bind_rows(all_results)
  save_df(summary_df, file.path(output_dir, "Direction_Analysis_Summary.csv"))

  message("\n=== Creating Visualizations ===")

  # Plot 1: Concordance rates
  p1 <- ggplot2::ggplot(summary_df, ggplot2::aes(x = cell_type, y = pct_concordant_schwann, fill = comparison)) +
    ggplot2::geom_col(position = "dodge") +
    ggplot2::theme_bw() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)) +
    ggplot2::labs(
      title = "Mouse-Schwann Concordance Rate",
      x = "Cell Type",
      y = "% Concordant Genes",
      fill = "Comparison"
    )

  save_plot(p1, file.path(output_dir, "Concordance_Schwann.png"), width = 12, height = 8)
  save_plot(p1, file.path(output_dir, "Concordance_Schwann.pdf"), width = 12, height = 8)

  # Plot 2: Concordance for JCI
  p2 <- ggplot2::ggplot(summary_df, ggplot2::aes(x = cell_type, y = pct_concordant_jci, fill = comparison)) +
    ggplot2::geom_col(position = "dodge") +
    ggplot2::theme_bw() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)) +
    ggplot2::labs(
      title = "Mouse-JCI Concordance Rate",
      x = "Cell Type",
      y = "% Concordant Genes",
      fill = "Comparison"
    )

  save_plot(p2, file.path(output_dir, "Concordance_JCI.png"), width = 12, height = 8)
  save_plot(p2, file.path(output_dir, "Concordance_JCI.pdf"), width = 12, height = 8)

  # Plot 3: Stacked bar showing concordant vs discordant counts
  plot_data <- summary_df %>%
    tidyr::pivot_longer(
      cols = c(n_concordant_schwann, n_discordant_schwann),
      names_to = "category",
      values_to = "count"
    ) %>%
    dplyr::mutate(category = gsub("^n_", "", category) %>% gsub("_schwann", "", .))

  p3 <- ggplot2::ggplot(plot_data, ggplot2::aes(x = cell_type, y = count, fill = category)) +
    ggplot2::geom_col(position = "stack") +
    ggplot2::facet_wrap(~ comparison, ncol = 3) +
    ggplot2::theme_bw() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)) +
    ggplot2::labs(
      title = "Concordant vs Discordant Genes (Mouse-Schwann)",
      x = "Cell Type",
      y = "Number of Genes",
      fill = "Category"
    )

  save_plot(p3, file.path(output_dir, "Concordant_Discordant_Counts.png"), width = 14, height = 10)
  save_plot(p3, file.path(output_dir, "Concordant_Discordant_Counts.pdf"), width = 14, height = 10)

  # Save Excel workbook
  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "Summary")
  openxlsx::writeData(wb, "Summary", summary_df)
  openxlsx::saveWorkbook(wb, file.path(output_dir, "Direction_Analysis.xlsx"), overwrite = TRUE)
}

message("\n=== Analysis Complete ===")
message("Output directory: ", output_dir)
message("Check for concordant/discordant gene lists and summary statistics")
