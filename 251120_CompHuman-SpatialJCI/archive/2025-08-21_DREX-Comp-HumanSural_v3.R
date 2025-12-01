################################################################################
# Initialize the workspace
################################################################################
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  script_path <- rstudioapi::getActiveDocumentContext()$path
  setwd(dirname(script_path))
  base_dir <- dirname(script_path)
}

# Set a default CRAN repo for non-interactive installs
options(repos = c(CRAN = "https://cloud.r-project.org"))

# Required packages
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(
  dplyr, tidyr, ggplot2, ggVennDiagram, tools, readxl, stringr,
  org.Mm.eg.db, org.Hs.eg.db, AnnotationDbi, homologene,
  pheatmap, tibble, openxlsx
)

################################################################################
# Settings
################################################################################
schwann_deg_path  <- "./DEGs_JCI_DPN/SchwannDEG_Severe-Moderate_noMito.csv"
jci_deg_path      <- "./DEGs_JCI_DPN/JCI184075.sdd3_BulkRNAseqDEGs.xlsx"
jci_deg_sheet     <- "deseq2_results"

# Filters for the two added datasets
padj_extra_cutoff <- 0.001
lfc_extra_cutoff  <- 1

# Folders to process
mouse_deg_dirs <- c(
  "../DEG",
  "../DEG_Major"
)

# Corresponding output folders (one per input)
output_roots <- c(
  "Output_DEG_vsJCI_Schwann",
  "Output_DEG_Major_vsJCI_Schwann"
)

# Create outputs
invisible(mapply(function(o) dir.create(o, showWarnings = FALSE, recursive = TRUE), output_roots))

################################################################################
# Helpers: safe file base, plotting, and I/O
################################################################################
safe_base <- function(x, limit = 150) {
  # shorten and remove problematic characters for long Windows paths
  x <- gsub("[^A-Za-z0-9._-]+", "_", x)
  if (nchar(x) > limit) substr(x, 1, limit) else x
}

save_df <- function(df, path) {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  utils::write.csv(df, path, row.names = FALSE)
}

save_plot <- function(p, path, width = 7, height = 6, dpi = 300) {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  ggplot2::ggsave(filename = path, plot = p, width = width, height = height, dpi = dpi, limitsize = FALSE)
}

sanitize_sheet <- function(x) {
  x <- gsub('[:\\\\/?*\\[\\]]', "_", x)   # invalid chars
  x <- ifelse(nchar(x) == 0, "Sheet", x)
  substr(x, 1, 31)                        # Excel 31-char limit
}

map_genes_to_mouse <- function(genes, mapping_tbl) {
  tibble::tibble(Human_Symbol = genes) %>%
    dplyr::filter(!is.na(Human_Symbol), Human_Symbol != "") %>%
    dplyr::mutate(Mouse_Symbol = mapping_tbl$Mouse_Symbol[match(Human_Symbol, mapping_tbl$Human_Symbol)]) %>%
    dplyr::filter(!is.na(Mouse_Symbol)) %>%
    dplyr::distinct(Mouse_Symbol) %>%
    dplyr::pull(Mouse_Symbol)
}

plot_and_save_venn <- function(set_list, title, file_base) {
  p <- ggVennDiagram::ggVennDiagram(set_list, label_alpha = 0) +
    ggplot2::scale_fill_gradient(low = "#f2f5fb", high = "#5f82c9", guide = "colourbar") +
    ggplot2::ggtitle(title) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(hjust = 0.5, color = "#1f1f1f"),
      text = ggplot2::element_text(color = "#1f1f1f"),
      plot.background = ggplot2::element_rect(fill = "white", color = NA)
    )
  # Center-align any text/label layers
  p$layers <- lapply(p$layers, function(l) {
    if (inherits(l$geom, c("GeomText", "GeomLabel", "GeomSfText", "GeomSfLabel"))) {
      l$aes_params$hjust <- 0.5
      l$aes_params$vjust <- 0.5
    }
    l
  })
  ggplot2::ggsave(paste0(file_base, ".png"), plot = p, width = 8, height = 6, dpi = 300, limitsize = FALSE)
  ggplot2::ggsave(paste0(file_base, ".pdf"), plot = p, width = 8, height = 6, dpi = 300, limitsize = FALSE)
}


# Build Human -> Mouse symbol mapping (keep one mouse symbol per human)
build_human_to_mouse_map <- function() {
  hom <- homologene::homologeneData
  human <- hom %>%
    dplyr::filter(Taxonomy == 9606) %>%
    dplyr::select(HID, Human_Symbol = Gene.Symbol)
  mouse <- hom %>%
    dplyr::filter(Taxonomy == 10090) %>%
    dplyr::select(HID, Mouse_Entrez = Gene.ID, Mouse_Symbol = Gene.Symbol)
  joined <- dplyr::left_join(human, mouse, by = "HID") %>%
    dplyr::filter(!is.na(Mouse_Symbol))
  # pick the one with the lowest Entrez per human to make it deterministic
  joined %>%
    dplyr::arrange(Human_Symbol, Mouse_Entrez) %>%
    dplyr::group_by(Human_Symbol) %>%
    dplyr::slice(1) %>%
    dplyr::ungroup() %>%
    dplyr::select(Human_Symbol, Mouse_Symbol)
}

human2mouse <- build_human_to_mouse_map()


################################################################################
# New datasets: load and filter (abs(log2FC)>1 & padj<0.001) then map to mouse
################################################################################
read_schwann_deg <- function(file_path, lfc_cutoff = 1, padj_cutoff = 0.001) {
  df <- suppressWarnings(read.csv(file_path, stringsAsFactors = FALSE, check.names = FALSE))
  
  if (!"Gene" %in% colnames(df)) {
    colnames(df)[1] <- "Gene"
  }
  
  cn <- tolower(gsub("\\s+", "_", colnames(df)))
  colnames(df) <- cn
  
  gene_col <- "gene"
  lfc_col <- if ("avg_log2fc" %in% cn) "avg_log2fc" else if ("log2foldchange" %in% cn) "log2foldchange" else stop("Cannot find log2FC in Schwann DEG file.")
  padj_col <- if ("p_val_adj" %in% cn) "p_val_adj" else if ("padj" %in% cn) "padj" else stop("Cannot find padj in Schwann DEG file.")
  
  df %>%
    dplyr::filter(!is.na(.data[[gene_col]]), .data[[gene_col]] != "") %>%
    dplyr::filter(abs(.data[[lfc_col]]) > lfc_cutoff, .data[[padj_col]] < padj_cutoff) %>%
    dplyr::transmute(Gene = as.character(.data[[gene_col]]),
                     log2FC = .data[[lfc_col]],
                     padj = .data[[padj_col]]) %>%
    dplyr::distinct(Gene, .keep_all = TRUE)
}

read_jci_bulk_deg <- function(file_path, sheet = "deseq2_results", lfc_cutoff = 1, padj_cutoff = 0.001) {
  df <- suppressWarnings(readxl::read_excel(file_path, sheet = sheet))
  cn <- tolower(gsub("\\s+", "_", colnames(df)))
  colnames(df) <- cn
  
  gene_col <- if ("gene" %in% cn) "gene" else stop("Cannot find 'Gene' column in JCI bulk DEG file.")
  lfc_col  <- if ("log2foldchange" %in% cn) "log2foldchange" else stop("Cannot find log2FoldChange in JCI bulk DEG file.")
  padj_col <- if ("padj" %in% cn) "padj" else stop("Cannot find padj in JCI bulk DEG file.")
  
  df %>%
    dplyr::filter(!is.na(.data[[gene_col]]), .data[[gene_col]] != "") %>%
    dplyr::filter(abs(.data[[lfc_col]]) > lfc_cutoff, .data[[padj_col]] < padj_cutoff) %>%
    dplyr::transmute(Gene = as.character(.data[[gene_col]]),
                     log2FC = .data[[lfc_col]],
                     padj = .data[[padj_col]]) %>%
    dplyr::distinct(Gene, .keep_all = TRUE)
}

schwann_deg <- read_schwann_deg(schwann_deg_path, lfc_cutoff = lfc_extra_cutoff, padj_cutoff = padj_extra_cutoff)
jci_bulk_deg <- read_jci_bulk_deg(jci_deg_path, sheet = jci_deg_sheet, lfc_cutoff = lfc_extra_cutoff, padj_cutoff = padj_extra_cutoff)

schwann_mouse_genes <- map_genes_to_mouse(schwann_deg$Gene, human2mouse)
jci_mouse_genes     <- map_genes_to_mouse(jci_bulk_deg$Gene, human2mouse)

extra_mouse_sets <- list(
  Schwann_noMito = schwann_mouse_genes,
  JCI_bulk       = jci_mouse_genes
)


################################################################################
# Read one mouse DEG file and return significant genes and log2FC
################################################################################
read_mouse_deg_file <- function(file_path) {
  df <- suppressWarnings(read.csv(file_path, stringsAsFactors = FALSE, check.names = FALSE))
  
  # First column contains gene symbols even if unnamed
  if (is.na(colnames(df)[1]) || colnames(df)[1] == "" || colnames(df)[1] %in% c("X", "...1")) {
    colnames(df)[1] <- "Gene"
  } else {
    # enforce common name
    colnames(df)[1] <- "Gene"
  }
  
  # normalize column names to locate p_val_adj and avg_log2FC
  cn <- tolower(gsub("\\s+", "_", colnames(df)))
  colnames(df) <- cn
  
  padj_col <- "p_val_adj"
  lfc_col  <- if ("avg_log2fc" %in% cn) "avg_log2fc" else if ("log2foldchange" %in% cn) "log2foldchange" else NULL
  if (!padj_col %in% cn) {
    warning(paste("p_val_adj column not found in", basename(file_path), "- skipping"))
    return(NULL)
  }
  if (is.null(lfc_col) || !lfc_col %in% cn) {
    warning(paste("log2FC column not found in", basename(file_path), "- skipping"))
    return(NULL)
  }
  
  df %>%
    dplyr::filter(!is.na(gene), gene != "") %>%
    dplyr::filter(.data[[padj_col]] < 0.05) %>%
    dplyr::select(Gene = gene, Mouse_log2FC = all_of(lfc_col), Mouse_padj = all_of(padj_col)) %>%
    dplyr::distinct(Gene, .keep_all = TRUE)
}

################################################################################
# Compare a single mouse DEG file against JCI bulk and Schwann sets
################################################################################
compare_one_file <- function(mouse_file, out_dir, extra_sets = list()) {
  message("Processing: ", mouse_file)
  base <- safe_base(tools::file_path_sans_ext(basename(mouse_file)))
  
  # parse "comp_group" and "cell_type" from the base name split by "_"
  parts <- strsplit(base, "_", fixed = TRUE)[[1]]
  comp_group <- if (length(parts) >= 1) parts[1] else NA_character_
  cell_type  <- if (length(parts) >= 2) parts[2] else NA_character_
  
  m_df <- read_mouse_deg_file(mouse_file)
  if (is.null(m_df) || nrow(m_df) == 0) {
    schwann_genes <- if (!is.null(extra_sets$Schwann_noMito)) extra_sets$Schwann_noMito else character(0)
    jci_genes     <- if (!is.null(extra_sets$JCI_bulk)) extra_sets$JCI_bulk else character(0)
    return(tibble::tibble(
      file = basename(mouse_file),
      comp_group = comp_group,
      cell_type = cell_type,
      n_mouse_sig = NA_integer_, n_schwann_sig = length(unique(schwann_genes)),
      n_jci_sig = length(unique(jci_genes)),
      n_overlap_schwann = NA_integer_, n_overlap_jci = NA_integer_, n_overlap_all_three = NA_integer_,
      jaccard_mouse_vs_union = NA_real_
    ))
  }
  m_genes <- unique(m_df$Gene)
  
  schwann_genes <- if (!is.null(extra_sets$Schwann_noMito)) extra_sets$Schwann_noMito else character(0)
  jci_genes     <- if (!is.null(extra_sets$JCI_bulk)) extra_sets$JCI_bulk else character(0)
  
  overlap_schwann <- intersect(m_genes, schwann_genes)
  overlap_jci     <- intersect(m_genes, jci_genes)
  overlap_all_three <- intersect(overlap_schwann, jci_genes)
  
  union_all <- union(m_genes, union(schwann_genes, jci_genes))
  inter_mouse_union <- intersect(m_genes, union(schwann_genes, jci_genes))
  jaccard_mouse_union <- if (length(union_all) == 0) NA_real_ else length(inter_mouse_union) / length(union_all)
  
  summary_row <- tibble::tibble(
    file               = basename(mouse_file),
    comp_group         = comp_group,
    cell_type          = cell_type,
    n_mouse_sig        = length(unique(m_genes)),
    n_schwann_sig      = length(unique(schwann_genes)),
    n_jci_sig          = length(unique(jci_genes)),
    n_overlap_schwann  = length(overlap_schwann),
    n_overlap_jci      = length(overlap_jci),
    n_overlap_all_three = length(overlap_all_three),
    jaccard_mouse_vs_union = jaccard_mouse_union
  )
  
  save_df(tibble::tibble(MouseGene = sort(unique(m_genes))), file.path(out_dir, paste0(base, "_Mouse_SignifGeneList.csv")))
  save_df(tibble::tibble(MouseGene = sort(unique(schwann_genes))), file.path(out_dir, paste0(base, "_Schwann_MouseGeneList.csv")))
  save_df(tibble::tibble(MouseGene = sort(unique(jci_genes))), file.path(out_dir, paste0(base, "_JCI_MouseGeneList.csv")))
  save_df(tibble::tibble(MouseGene = sort(overlap_schwann)), file.path(out_dir, paste0(base, "_Overlap_Mouse_Schwann.csv")))
  save_df(tibble::tibble(MouseGene = sort(overlap_jci)), file.path(out_dir, paste0(base, "_Overlap_Mouse_JCI.csv")))
  save_df(tibble::tibble(MouseGene = sort(overlap_all_three)), file.path(out_dir, paste0(base, "_Overlap_AllThree.csv")))
  
  venn_sets <- list(
    Mouse_scRNA       = m_genes,
    Schwann_noMito    = schwann_genes,
    JCI_bulk          = jci_genes
  )
  venn_sets <- Filter(function(x) !is.null(x) && length(x) > 0, venn_sets)
  if (length(venn_sets) >= 2) {
    venn_base <- file.path(out_dir, paste0(base, "_Venn3way"))
    plot_and_save_venn(
      venn_sets,
      title = paste0("Mouse/Schwann/JCI: ", base),
      file_base = venn_base
    )
  }
  
  return(summary_row)
}

# Helpers to match selected comparisons and cell types
normalize_key <- function(x) tolower(gsub("[^A-Za-z0-9]+", "", x))

is_selected <- function(comp_group, cell_type) {
  if (is.na(comp_group) || is.na(cell_type)) return(FALSE)
  allowed_comp <- c("HFD vs SD", "DR vs HFD", "EX vs HFD", "DREX vs HFD")
  allowed_cell <- c("majorSC", "mySC", "nmSC", "ImmSC")
  normalize_key(comp_group) %in% normalize_key(allowed_comp) &&
    normalize_key(cell_type) %in% normalize_key(allowed_cell)
}

################################################################################
# Compare for a whole folder and write a master summary (+ selected subset)
################################################################################
compare_folder <- function(input_dir, output_dir, extra_sets) {
  message("=== Folder: ", input_dir, " ===")
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
  
  files <- list.files(input_dir, pattern = "\\.csv$", full.names = TRUE, recursive = FALSE)
  files <- files[!basename(files) %>% startsWith(".")]
  # Exclude pathway SPIA outputs that do not contain DEG-level columns
  files <- files[!grepl("spia", basename(files), ignore.case = TRUE)]
  if (length(files) == 0) {
    warning("No CSV files found in: ", input_dir)
    return(invisible(NULL))
  }
  
  # ---------- Full run (unchanged behavior) ----------
  per_file_out <- file.path(output_dir, "per_file")
  dir.create(per_file_out, showWarnings = FALSE, recursive = TRUE)
  
  all_summaries <- lapply(files, function(f) {
    tryCatch(
      compare_one_file(f, per_file_out, extra_sets = extra_sets),
      error = function(e) {
        warning("Failed on ", basename(f), ": ", conditionMessage(e))
        parts <- strsplit(safe_base(tools::file_path_sans_ext(basename(f))), "_", fixed = TRUE)[[1]]
        comp_group <- if (length(parts) >= 1) parts[1] else NA_character_
        cell_type  <- if (length(parts) >= 2) parts[2] else NA_character_
        tibble::tibble(
          file = basename(f),
          comp_group = comp_group,
          cell_type = cell_type,
          n_mouse_sig = NA_integer_, n_schwann_sig = NA_integer_, n_jci_sig = NA_integer_,
          n_overlap_schwann = NA_integer_, n_overlap_jci = NA_integer_, n_overlap_all_three = NA_integer_,
          jaccard_mouse_vs_union = NA_real_
        )
      }
    )
  })
  
  master <- dplyr::bind_rows(all_summaries) %>%
    dplyr::arrange(dplyr::desc(n_overlap_all_three), dplyr::desc(n_overlap_schwann), dplyr::desc(n_overlap_jci))
  
  save_df(master, file.path(output_dir, "Master_Summary.csv"))
  
  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "Summary")
  openxlsx::writeData(wb, "Summary", master)
  
  cell_types <- sort(unique(master$cell_type))
  cell_types <- cell_types[!is.na(cell_types)]
  for (ct in cell_types) {
    sheet <- sanitize_sheet(ct)
    openxlsx::addWorksheet(wb, sheet)
    df_ct <- master %>% dplyr::filter(cell_type == ct) %>%
      dplyr::arrange(dplyr::desc(n_overlap_all_three), dplyr::desc(n_overlap_schwann), dplyr::desc(n_overlap_jci))
    openxlsx::writeData(wb, sheet, df_ct)
  }
  
  xlsx_path <- file.path(output_dir, "Master_Summary.xlsx")
  openxlsx::saveWorkbook(wb, xlsx_path, overwrite = TRUE)
  message("Master Excel written: ", xlsx_path)
  
  # ---------- Selected run (filtered subset) ----------
  # pick files by parsing comp_group and cell_type from filename
  pick_files <- vapply(files, function(f) {
    base <- safe_base(tools::file_path_sans_ext(basename(f)))
    parts <- strsplit(base, "_", fixed = TRUE)[[1]]
    comp_group <- if (length(parts) >= 1) parts[1] else NA_character_
    cell_type  <- if (length(parts) >= 2) parts[2] else NA_character_
    is_selected(comp_group, cell_type)
  }, logical(1))
  
  sel_files <- files[pick_files]
  
  if (length(sel_files) > 0) {
    per_file_sel_out <- file.path(output_dir, "per_file_select")
    dir.create(per_file_sel_out, showWarnings = FALSE, recursive = TRUE)
    
    sel_summaries <- lapply(sel_files, function(f) {
      tryCatch(
        compare_one_file(f, per_file_sel_out, extra_sets = extra_sets),
        error = function(e) {
          warning("Failed on ", basename(f), ": ", conditionMessage(e))
          parts <- strsplit(safe_base(tools::file_path_sans_ext(basename(f))), "_", fixed = TRUE)[[1]]
          comp_group <- if (length(parts) >= 1) parts[1] else NA_character_
          cell_type  <- if (length(parts) >= 2) parts[2] else NA_character_
          tibble::tibble(
            file = basename(f),
            comp_group = comp_group,
            cell_type = cell_type,
            n_mouse_sig = NA_integer_, n_schwann_sig = NA_integer_, n_jci_sig = NA_integer_,
            n_overlap_schwann = NA_integer_, n_overlap_jci = NA_integer_, n_overlap_all_three = NA_integer_,
            jaccard_mouse_vs_union = NA_real_
          )
        }
      )
    })
    
    master_sel <- dplyr::bind_rows(sel_summaries) %>%
      dplyr::arrange(dplyr::desc(n_overlap_all_three), dplyr::desc(n_overlap_schwann), dplyr::desc(n_overlap_jci))
    
    save_df(master_sel, file.path(output_dir, "Master_Summary_selected.csv"))
    
    wb2 <- openxlsx::createWorkbook()
    openxlsx::addWorksheet(wb2, "Summary_selected")
    openxlsx::writeData(wb2, "Summary_selected", master_sel)
    
    sel_cell_types <- sort(unique(master_sel$cell_type))
    sel_cell_types <- sel_cell_types[!is.na(sel_cell_types)]
    for (ct in sel_cell_types) {
      sheet <- sanitize_sheet(ct)
      openxlsx::addWorksheet(wb2, sheet)
      df_ct <- master_sel %>% dplyr::filter(cell_type == ct) %>%
        dplyr::arrange(dplyr::desc(n_overlap_all_three), dplyr::desc(n_overlap_schwann), dplyr::desc(n_overlap_jci))
      openxlsx::writeData(wb2, sheet, df_ct)
    }
    
    xlsx_path_sel <- file.path(output_dir, "Master_Summary_selected.xlsx")
    openxlsx::saveWorkbook(wb2, xlsx_path_sel, overwrite = TRUE)
    message("Selected Excel written: ", xlsx_path_sel)
  } else {
    message("No files matched the selected comparisons and cell types in: ", input_dir)
  }
  
  invisible(master)
}



################################################################################
# Run for each folder
################################################################################
invisible(mapply(function(in_dir, out_dir) {
  compare_folder(in_dir, out_dir, extra_sets = extra_mouse_sets)
}, mouse_deg_dirs, output_roots))

message("All done.")
