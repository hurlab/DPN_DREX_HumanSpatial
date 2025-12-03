################################################################################
# Analysis #7: Protein-Protein Interaction (PPI) Network Analysis
#
# Uses STRING database to analyze PPI networks for:
# - Mouse DEGs (majorSC and aggSC) across interventions
# - Human JCI_SC DEGs
#
# For each gene set:
# - Maps genes to STRING protein IDs
# - Generates PPI network visualizations
# - Performs PPI enrichment analysis (tests if proteins have more interactions than expected)
# - Performs functional enrichment on network (GO/KEGG)
################################################################################

if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  script_path <- rstudioapi::getActiveDocumentContext()$path
  setwd(dirname(script_path))
}

options(repos = c(CRAN = "https://cloud.r-project.org"))

if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(
  dplyr, tidyr, tibble, purrr, stringr, readxl,
  openxlsx, homologene
)

# Install STRINGdb if needed
if (!requireNamespace("STRINGdb", quietly = TRUE)) {
  if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager")
  BiocManager::install("STRINGdb", ask = FALSE)
}
library(STRINGdb)

################################################################################
# Settings
################################################################################
schwann_deg_path <- "./DEGs_JCI_DPN/SchwannDEG_Severe-Moderate_noMito.csv"
mouse_deg_dirs <- c("../DEG_Major", "temp_aggSC")
output_root <- "Output_JCI/PPI_Network_Analysis"
dir.create(output_root, showWarnings = FALSE, recursive = TRUE)

# Focus on specific cell types
mouse_cell_types <- c("majorSC", "aggSC")
comparison_groups <- c("HFDvsSD", "DRvsHFD", "EXvsHFD", "DREXvsHFD")

# STRING settings
mouse_species <- 10090  # Mus musculus
human_species <- 9606   # Homo sapiens
score_threshold <- 400  # Medium confidence (0-1000 scale)
network_limit <- 200    # Max genes for network visualization

# P-value thresholds
pval_mouse_cutoff <- 0.01
padj_human_cutoff <- 0.001
lfc_human_cutoff <- 1

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

read_schwann_deg <- function(file_path, lfc_cutoff = 1, padj_cutoff = 0.001) {
  df <- suppressWarnings(read.csv(file_path, stringsAsFactors = FALSE, check.names = FALSE))
  if (!"Gene" %in% colnames(df)) colnames(df)[1] <- "Gene"
  cn <- tolower(gsub("\\s+", "_", colnames(df)))
  colnames(df) <- cn
  gene_col <- "gene"
  lfc_col  <- if ("avg_log2fc" %in% cn) "avg_log2fc" else if ("log2foldchange" %in% cn) "log2foldchange" else stop("Cannot find log2FC in Schwann DEG file.")
  padj_col <- if ("p_val_adj" %in% cn) "p_val_adj" else if ("padj" %in% cn) "padj" else stop("Cannot find padj in Schwann DEG file.")
  df %>%
    dplyr::filter(!is.na(.data[[gene_col]]), .data[[gene_col]] != "") %>%
    dplyr::filter(abs(.data[[lfc_col]]) > lfc_cutoff, .data[[padj_col]] < padj_cutoff) %>%
    dplyr::distinct(.data[[gene_col]]) %>%
    dplyr::pull()
}

read_mouse_deg_file <- function(file_path, pval_cutoff = 0.01, return_full = FALSE) {
  df <- suppressWarnings(read.csv(file_path, stringsAsFactors = FALSE, check.names = FALSE))
  if (is.na(colnames(df)[1]) || colnames(df)[1] == "" || colnames(df)[1] %in% c("X", "...1")) {
    colnames(df)[1] <- "Gene"
  } else {
    colnames(df)[1] <- "Gene"
  }
  cn <- tolower(gsub("\\s+", "_", colnames(df)))
  colnames(df) <- cn

  pval_col <- "p_val"
  lfc_col  <- if ("avg_log2fc" %in% cn) "avg_log2fc" else if ("log2foldchange" %in% cn) "log2foldchange" else NULL

  if (!pval_col %in% cn || is.null(lfc_col)) return(NULL)

  df_filtered <- df %>%
    dplyr::filter(!is.na(gene), gene != "") %>%
    dplyr::filter(.data[[pval_col]] < pval_cutoff)

  if (return_full) {
    df_filtered %>%
      dplyr::transmute(gene = gene, log2FC = .data[[lfc_col]], pval = .data[[pval_col]])
  } else {
    df_filtered %>% dplyr::distinct(gene) %>% dplyr::pull()
  }
}

################################################################################
# Initialize STRING databases
################################################################################
message("=== Initializing STRING databases ===")
string_mouse <- STRINGdb$new(version = "12.0", species = mouse_species,
                              score_threshold = score_threshold, input_directory = "")
string_human <- STRINGdb$new(version = "12.0", species = human_species,
                              score_threshold = score_threshold, input_directory = "")

################################################################################
# Load human JCI_SC DEGs
################################################################################
message("\n=== Loading Human JCI_SC DEGs ===")
human2mouse <- build_human_to_mouse_map()
schwann_genes <- read_schwann_deg(schwann_deg_path,
                                  lfc_cutoff = lfc_human_cutoff,
                                  padj_cutoff = padj_human_cutoff)
message("Human JCI_SC DEGs: ", length(schwann_genes), " genes")

# Map human genes to STRING IDs
schwann_df <- data.frame(gene = schwann_genes, stringsAsFactors = FALSE)
schwann_mapped <- string_human$map(schwann_df, "gene", removeUnmappedRows = TRUE)
message("  Mapped to STRING: ", nrow(schwann_mapped), " proteins")

# Perform PPI network analysis for human
if (nrow(schwann_mapped) >= 5) {
  out_dir <- file.path(output_root, "JCI_SC")
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

  # Save mapped genes
  save_df(schwann_mapped, file.path(out_dir, "JCI_SC_STRING_mapped.csv"))

  # PPI enrichment test
  message("  Running PPI enrichment...")
  ppi_enrich <- tryCatch({
    string_human$ppi_enrichment(schwann_mapped$STRING_id)
  }, error = function(e) {
    warning("PPI enrichment failed: ", conditionMessage(e))
    NULL
  })

  if (!is.null(ppi_enrich) && length(ppi_enrich) > 0) {
    ppi_df <- data.frame(
      metric = names(ppi_enrich),
      value = as.character(unlist(ppi_enrich)),
      stringsAsFactors = FALSE
    )
    save_df(ppi_df, file.path(out_dir, "JCI_SC_PPI_enrichment.csv"))
    if (!is.null(ppi_enrich$p_value)) {
      message("    PPI enrichment p-value: ", ppi_enrich$p_value)
    }
  }

  # Generate network visualization (limit to top genes)
  n_plot <- min(network_limit, nrow(schwann_mapped))
  plot_ids <- schwann_mapped$STRING_id[1:n_plot]

  message("  Generating network plot (", n_plot, " proteins)...")
  pdf(file.path(out_dir, "JCI_SC_PPI_network.pdf"), width = 12, height = 12)
  tryCatch({
    string_human$plot_network(plot_ids)
  }, error = function(e) {
    warning("Network plot failed: ", conditionMessage(e))
  })
  dev.off()

  # Functional enrichment on the network
  message("  Running functional enrichment on network...")
  for (category in c("Process", "KEGG")) {
    enrich_res <- tryCatch({
      suppressWarnings(string_human$get_enrichment(plot_ids, category = category))
    }, error = function(e) {
      warning("Enrichment (", category, ") failed: ", conditionMessage(e))
      NULL
    })

    if (!is.null(enrich_res) && is.data.frame(enrich_res) && nrow(enrich_res) > 0) {
      save_df(enrich_res, file.path(out_dir, paste0("JCI_SC_STRING_", category, ".csv")))
      message("    ", category, ": ", nrow(enrich_res), " terms")
    }
  }
}

################################################################################
# Process mouse DEG files
################################################################################
message("\n=== Processing Mouse DEG files ===")

all_results <- list()

for (input_dir in mouse_deg_dirs) {
  if (!dir.exists(input_dir)) {
    message("Skipping (directory not found): ", input_dir)
    next
  }

  files <- list.files(input_dir, pattern = "\\.csv$", full.names = TRUE, recursive = FALSE)
  files <- files[!basename(files) %>% startsWith(".")]

  # Filter for specific cell types and comparisons
  files <- files[sapply(files, function(f) {
    parts <- strsplit(safe_base(tools::file_path_sans_ext(basename(f))), "_", fixed = TRUE)[[1]]
    comp_group <- if (length(parts) >= 1) parts[1] else NA_character_
    cell_type <- if (length(parts) >= 2) parts[2] else NA_character_

    cell_pass <- !is.na(cell_type) && cell_type %in% mouse_cell_types
    comp_pass <- !is.na(comp_group) && comp_group %in% comparison_groups

    cell_pass && comp_pass
  })]

  message("\n--- Folder: ", input_dir, " ---")

  for (mouse_file in files) {
    message("Processing: ", basename(mouse_file))
    base <- safe_base(tools::file_path_sans_ext(basename(mouse_file)))
    parts <- strsplit(base, "_", fixed = TRUE)[[1]]
    comp_group <- if (length(parts) >= 1) parts[1] else NA_character_
    cell_type  <- if (length(parts) >= 2) parts[2] else NA_character_

    mouse_genes <- read_mouse_deg_file(mouse_file, pval_cutoff = pval_mouse_cutoff)
    if (is.null(mouse_genes) || length(mouse_genes) == 0) {
      warning("  Skipping (no genes): ", basename(mouse_file))
      next
    }

    message("  Mouse DEGs: ", length(mouse_genes), " genes")

    # Map to STRING
    mouse_df <- data.frame(gene = mouse_genes, stringsAsFactors = FALSE)
    mouse_mapped <- string_mouse$map(mouse_df, "gene", removeUnmappedRows = TRUE)
    message("  Mapped to STRING: ", nrow(mouse_mapped), " proteins")

    if (nrow(mouse_mapped) < 5) {
      warning("  Skipping (too few mapped proteins)")
      next
    }

    # Create output directory
    out_dir <- file.path(output_root, paste0(comp_group, "_", cell_type))
    dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

    # Save mapped genes
    save_df(mouse_mapped, file.path(out_dir, "Mouse_STRING_mapped.csv"))

    # PPI enrichment test
    message("  Running PPI enrichment...")
    ppi_enrich <- tryCatch({
      string_mouse$ppi_enrichment(mouse_mapped$STRING_id)
    }, error = function(e) {
      warning("  PPI enrichment failed: ", conditionMessage(e))
      NULL
    })

    if (!is.null(ppi_enrich) && length(ppi_enrich) > 0) {
      ppi_df <- data.frame(
        metric = names(ppi_enrich),
        value = as.character(unlist(ppi_enrich)),
        stringsAsFactors = FALSE
      )
      save_df(ppi_df, file.path(out_dir, "Mouse_PPI_enrichment.csv"))

      if (!is.null(ppi_enrich$p_value)) {
        message("    PPI enrichment p-value: ", ppi_enrich$p_value)
      }

      all_results[[length(all_results) + 1]] <- tibble(
        comparison = comp_group,
        cell_type = cell_type,
        n_genes = length(mouse_genes),
        n_mapped = nrow(mouse_mapped),
        ppi_pvalue = if (!is.null(ppi_enrich$p_value)) ppi_enrich$p_value else NA,
        ppi_n_expected_edges = if (!is.null(ppi_enrich$number_of_expected_edges)) ppi_enrich$number_of_expected_edges else NA,
        ppi_n_edges = if (!is.null(ppi_enrich$number_of_edges)) ppi_enrich$number_of_edges else NA
      )
    }

    # Generate network visualization
    n_plot <- min(network_limit, nrow(mouse_mapped))
    plot_ids <- mouse_mapped$STRING_id[1:n_plot]

    message("  Generating network plot (", n_plot, " proteins)...")
    pdf(file.path(out_dir, "Mouse_PPI_network.pdf"), width = 12, height = 12)
    tryCatch({
      string_mouse$plot_network(plot_ids)
    }, error = function(e) {
      warning("  Network plot failed: ", conditionMessage(e))
    })
    dev.off()

    # Functional enrichment on the network
    message("  Running functional enrichment on network...")
    for (category in c("Process", "KEGG")) {
      enrich_res <- tryCatch({
        suppressWarnings(string_mouse$get_enrichment(plot_ids, category = category))
      }, error = function(e) {
        warning("  Enrichment (", category, ") failed: ", conditionMessage(e))
        NULL
      })

      if (!is.null(enrich_res) && is.data.frame(enrich_res) && nrow(enrich_res) > 0) {
        save_df(enrich_res, file.path(out_dir, paste0("Mouse_STRING_", category, ".csv")))
        message("    ", category, ": ", nrow(enrich_res), " terms")
      }
    }
  }
}

################################################################################
# Summary
################################################################################
if (length(all_results) > 0) {
  summary_df <- dplyr::bind_rows(all_results) %>%
    dplyr::arrange(ppi_pvalue)

  save_df(summary_df, file.path(output_root, "PPI_Analysis_Summary.csv"))

  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "Summary")
  openxlsx::writeData(wb, "Summary", summary_df)
  openxlsx::saveWorkbook(wb, file.path(output_root, "PPI_Analysis_Summary.xlsx"), overwrite = TRUE)

  message("\n=== PPI Network Analysis Complete ===")
  message("Summary saved to: ", file.path(output_root, "PPI_Analysis_Summary.csv"))
} else {
  message("\n=== No PPI results generated ===")
}

message("Output directory: ", output_root)
