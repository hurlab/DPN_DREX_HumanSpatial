################################################################################
# Enrichment on Mouse vs JCI bulk vs Schwann overlaps
# - Reads JCI bulk (human) and Schwann (human) DEGs, maps to mouse symbols
# - Reads mouse scRNA-seq DEG CSVs (DEG/ and DEG_Major/)
# - Builds overlap/unique gene sets per mouse comparison
# - Runs GO/KEGG enrichment (prefers richR; falls back to clusterProfiler if absent)
# - Writes gene lists and enrichment tables to Output_JCI_Schwann_enrichment/
################################################################################

if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  script_path <- rstudioapi::getActiveDocumentContext()$path
  setwd(dirname(script_path))
}

options(repos = c(CRAN = "https://cloud.r-project.org"))

if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(
  dplyr, tidyr, readxl, tibble, purrr, stringr,
  homologene, AnnotationDbi, org.Mm.eg.db, openxlsx,
  ggVennDiagram, ggplot2, parallel
)

################################################################################
# Settings
################################################################################
schwann_deg_path <- "./DEGs_JCI_DPN/SchwannDEG_Severe-Moderate_noMito.csv"
jci_deg_path     <- "./DEGs_JCI_DPN/JCI184075.sdd3_BulkRNAseqDEGs.xlsx"
jci_deg_sheet    <- "deseq2_results"

mouse_deg_dirs <- c("../DEG", "../DEG_Major")
output_root    <- "Output_JCI_Schwann_enrichment"

padj_extra_cutoff <- 0.001
lfc_extra_cutoff  <- 1
min_genes_for_enrichment <- 5

# Schwann cell type filter (set to NULL to include all cell types)
schwann_cell_types <- c("mySC", "nmSC", "ImmSC", "SC3", "majorSC")

# Parallel processing (set cores = 1 to disable parallelization)
# Use 75% of available cores (adjust fraction as needed: 0.5 = 50%, 0.8 = 80%, etc.)
# Re-enabled for Linux/WSL2 environment (Windows issues don't apply here)
n_cores <- max(1, floor(parallel::detectCores() * 0.75))

dir.create(output_root, showWarnings = FALSE, recursive = TRUE)

################################################################################
# Helpers
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
  p <- ggVennDiagram::ggVennDiagram(set_list, label_alpha = 0) +
    ggplot2::ggtitle(title) +
    ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5, size = 14, face = "bold"))
  ggplot2::ggsave(paste0(out_path, ".png"), plot = p, width = 8, height = 6, dpi = 300)
  ggplot2::ggsave(paste0(out_path, ".pdf"), plot = p, width = 8, height = 6, dpi = 300)
  invisible(p)
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
    dplyr::distinct(.data[[gene_col]]) %>%
    dplyr::pull()
}

read_mouse_deg_file <- function(file_path) {
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
  if (!padj_col %in% cn || is.null(lfc_col) || !lfc_col %in% cn) return(character(0))
  df %>%
    dplyr::filter(!is.na(gene), gene != "") %>%
    dplyr::filter(.data[[padj_col]] < 0.05) %>%
    dplyr::distinct(gene) %>%
    dplyr::pull()
}

map_to_entrez <- function(symbols) {
  suppressWarnings({
    AnnotationDbi::select(org.Mm.eg.db, keys = symbols, keytype = "SYMBOL", columns = "ENTREZID") %>%
      dplyr::filter(!is.na(ENTREZID)) %>%
      dplyr::distinct(ENTREZID) %>%
      dplyr::pull(ENTREZID)
  })
}

run_enrichment <- function(genes, set_name, out_dir, organism = "mmu", go_annot = NULL, kegg_annot = NULL) {
  if (length(genes) < min_genes_for_enrichment) return(NULL)
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

  rich_ok <- requireNamespace("richR", quietly = TRUE)
  cp_ok   <- requireNamespace("clusterProfiler", quietly = TRUE)

  # --- Try richR (GO + KEGG) using pre-built annotations if available ---
  if (rich_ok) {
    try({
      if (is.null(go_annot)) {
        go_annot <- richR::buildAnnot(species = "mouse", keytype = "SYMBOL", anntype = "GO")
      }
      go_res <- richR::richGO(genes, godata = go_annot, organism = "mouse", keytype = "SYMBOL")
      save_df(as.data.frame(go_res), file.path(out_dir, paste0(set_name, "_richR_GO.csv")))
    }, silent = TRUE)
    try({
      if (is.null(kegg_annot)) {
        kegg_annot <- richR::buildAnnot(species = "mouse", keytype = "SYMBOL", anntype = "KEGG")
      }
      ko_res <- richR::richKEGG(genes, kodata = kegg_annot, organism = "mouse", keytype = "SYMBOL")
      save_df(as.data.frame(ko_res), file.path(out_dir, paste0(set_name, "_richR_KEGG.csv")))
    }, silent = TRUE)
  }

  # --- Fallback: clusterProfiler ---
  if (cp_ok) {
    # GO BP
    go_cp <- tryCatch(
      clusterProfiler::enrichGO(
        gene          = genes,
        OrgDb         = org.Mm.eg.db,
        keyType       = "SYMBOL",
        ont           = "BP",
        pAdjustMethod = "BH",
        readable      = TRUE
      ),
      error = function(e) NULL
    )
    if (!is.null(go_cp)) {
      save_df(as.data.frame(go_cp), file.path(out_dir, paste0(set_name, "_clusterProfiler_GO.csv")))
    }

    # KEGG (requires Entrez IDs)
    entrez <- map_to_entrez(genes)
    kegg_cp <- tryCatch(
      clusterProfiler::enrichKEGG(
        gene          = entrez,
        organism      = organism,
        keyType       = "kegg",
        pAdjustMethod = "BH"
      ),
      error = function(e) NULL
    )
    if (!is.null(kegg_cp)) {
      save_df(as.data.frame(kegg_cp), file.path(out_dir, paste0(set_name, "_clusterProfiler_KEGG.csv")))
    }
  }
}

################################################################################
# Load shared datasets
################################################################################
human2mouse <- build_human_to_mouse_map()

schwann_human <- read_schwann_deg(schwann_deg_path, lfc_cutoff = lfc_extra_cutoff, padj_cutoff = padj_extra_cutoff)
schwann_mouse <- map_genes_to_mouse(schwann_human, human2mouse)

jci_human <- read_jci_bulk_deg(jci_deg_path, sheet = jci_deg_sheet, lfc_cutoff = lfc_extra_cutoff, padj_cutoff = padj_extra_cutoff)
jci_mouse <- map_genes_to_mouse(jci_human, human2mouse)

################################################################################
# Pre-build richR annotations (if available) to save time
################################################################################
go_annot <- NULL
kegg_annot <- NULL

if (requireNamespace("richR", quietly = TRUE)) {
  message("Building richR annotations for mouse (GO and KEGG)...")
  tryCatch({
    go_annot <- richR::buildAnnot(species = "mouse", keytype = "SYMBOL", anntype = "GO")
    message("  ✓ GO annotations built successfully")
  }, error = function(e) {
    message("  ✗ Failed to build GO annotations: ", e$message)
    go_annot <<- NULL
  })

  tryCatch({
    kegg_annot <- richR::buildAnnot(species = "mouse", keytype = "SYMBOL", anntype = "KEGG", builtin = FALSE)
    message("  ✓ KEGG annotations built successfully")
  }, error = function(e) {
    message("  ✗ Failed to build KEGG annotations: ", e$message)
    kegg_annot <<- NULL
  })
} else {
  message("richR not available - will use clusterProfiler only")
}

################################################################################
# Per-mouse-file enrichment
################################################################################
all_summaries <- list()

for (input_dir in mouse_deg_dirs) {
  files <- list.files(input_dir, pattern = "\\.csv$", full.names = TRUE, recursive = FALSE)
  files <- files[!basename(files) %>% startsWith(".")]
  files <- files[!grepl("spia", basename(files), ignore.case = TRUE)]

  # Filter for Schwann cells only if specified
  if (!is.null(schwann_cell_types)) {
    files <- files[sapply(files, function(f) {
      parts <- strsplit(safe_base(tools::file_path_sans_ext(basename(f))), "_", fixed = TRUE)[[1]]
      cell_type <- if (length(parts) >= 2) parts[2] else NA_character_
      !is.na(cell_type) && cell_type %in% schwann_cell_types
    })]
    message("=== Folder: ", input_dir, " (filtering for Schwann cells: ", paste(schwann_cell_types, collapse = ", "), ") ===")
  } else {
    message("=== Folder: ", input_dir, " (all cell types) ===")
  }

  if (length(files) == 0) {
    message("  No files match the filter criteria")
    next
  }

  message("  Processing ", length(files), " file(s)...")

  for (mouse_file in files) {
    base <- safe_base(tools::file_path_sans_ext(basename(mouse_file)))
    parts <- strsplit(base, "_", fixed = TRUE)[[1]]
    comp_group <- if (length(parts) >= 1) parts[1] else NA_character_
    cell_type  <- if (length(parts) >= 2) parts[2] else NA_character_

    message("  - Processing: ", basename(mouse_file))

    mouse_genes <- read_mouse_deg_file(mouse_file)
    if (length(mouse_genes) == 0) {
      warning("    Skipping (no usable genes): ", basename(mouse_file))
      next
    }

    overlap_ms   <- intersect(mouse_genes, schwann_mouse)
    overlap_mj   <- intersect(mouse_genes, jci_mouse)
    overlap_sj   <- intersect(schwann_mouse, jci_mouse)
    overlap_all3 <- Reduce(intersect, list(mouse_genes, schwann_mouse, jci_mouse))

    mouse_only   <- setdiff(mouse_genes, union(schwann_mouse, jci_mouse))
    schwann_only <- setdiff(schwann_mouse, union(mouse_genes, jci_mouse))
    jci_only     <- setdiff(jci_mouse, union(mouse_genes, schwann_mouse))

    set_list <- list(
      Mouse_all      = mouse_genes,
      Schwann_all    = schwann_mouse,
      JCI_all        = jci_mouse,
      Overlap_MS     = overlap_ms,
      Overlap_MJ     = overlap_mj,
      Overlap_SJ     = overlap_sj,
      Overlap_All3   = overlap_all3,
      Mouse_only     = mouse_only,
      Schwann_only   = schwann_only,
      JCI_only       = jci_only
    )

    per_out <- file.path(output_root, paste0(base, "_enrichment"))
    dir.create(per_out, showWarnings = FALSE, recursive = TRUE)

    # Save gene lists
    purrr::iwalk(set_list, function(gs, nm) {
      save_df(tibble(Gene = sort(unique(gs))), file.path(per_out, paste0(nm, "_Genes.csv")))
    })

    # Generate Venn diagrams for 3-way comparisons
    venn_3way <- list(
      Mouse = mouse_genes,
      Schwann = schwann_mouse,
      JCI = jci_mouse
    )
    venn_title <- paste0(comp_group, " ", cell_type, ": Mouse vs Schwann vs JCI")
    venn_path <- file.path(per_out, paste0(base, "_Venn3way"))
    save_venn(venn_3way, venn_title, venn_path)

    # Run enrichment analysis with parallelization
    # Note: mclapply doesn't work on Windows; use parLapply instead
    if (n_cores > 1 && .Platform$OS.type != "windows") {
      message("    Running enrichment in parallel (", n_cores, " cores)...")
      parallel::mclapply(names(set_list), function(nm) {
        gs <- set_list[[nm]]
        run_enrichment(gs, nm, out_dir = per_out, go_annot = go_annot, kegg_annot = kegg_annot)
      }, mc.cores = n_cores, mc.preschedule = FALSE)
    } else if (n_cores > 1 && .Platform$OS.type == "windows") {
      message("    Running enrichment in parallel on Windows (", n_cores, " cores)...")
      cl <- parallel::makeCluster(n_cores)
      on.exit(parallel::stopCluster(cl), add = TRUE)
      # Export required objects and functions to cluster
      parallel::clusterExport(cl, c("run_enrichment", "save_df", "map_to_entrez",
                                    "min_genes_for_enrichment", "go_annot", "kegg_annot",
                                    "set_list", "per_out"),
                              envir = environment())
      parallel::clusterEvalQ(cl, {
        library(dplyr)
        library(tibble)
        library(AnnotationDbi)
        library(org.Mm.eg.db)
      })
      parallel::parLapply(cl, names(set_list), function(nm) {
        gs <- set_list[[nm]]
        run_enrichment(gs, nm, out_dir = per_out, go_annot = go_annot, kegg_annot = kegg_annot)
      })
    } else {
      message("    Running enrichment sequentially...")
      purrr::iwalk(set_list, function(gs, nm) {
        run_enrichment(gs, nm, out_dir = per_out, go_annot = go_annot, kegg_annot = kegg_annot)
      })
    }

    all_summaries[[length(all_summaries) + 1]] <- tibble(
      file = basename(mouse_file),
      comp_group = comp_group,
      cell_type = cell_type,
      n_mouse = length(mouse_genes),
      n_schwann = length(schwann_mouse),
      n_jci = length(jci_mouse),
      n_overlap_ms = length(overlap_ms),
      n_overlap_mj = length(overlap_mj),
      n_overlap_sj = length(overlap_sj),
      n_overlap_all3 = length(overlap_all3)
    )
  }
}

################################################################################
# Master summary workbook
################################################################################
if (length(all_summaries) > 0) {
  master <- dplyr::bind_rows(all_summaries) %>%
    dplyr::arrange(dplyr::desc(n_overlap_all3), dplyr::desc(n_overlap_ms), dplyr::desc(n_overlap_mj))
  save_df(master, file.path(output_root, "Master_Enrichment_Summary.csv"))
  
  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, "Summary")
  openxlsx::writeData(wb, "Summary", master)
  
  cell_types <- sort(unique(master$cell_type))
  cell_types <- cell_types[!is.na(cell_types)]
  for (ct in cell_types) {
    sheet <- gsub('[:\\\\/?*\\[\\]]', "_", ct)
    sheet <- substr(ifelse(nchar(sheet) == 0, "Sheet", sheet), 1, 31)
    openxlsx::addWorksheet(wb, sheet)
    df_ct <- master %>% dplyr::filter(cell_type == ct)
    openxlsx::writeData(wb, sheet, df_ct)
  }
  
  openxlsx::saveWorkbook(wb, file.path(output_root, "Master_Enrichment_Summary.xlsx"), overwrite = TRUE)
  message("Enrichment summary written to ", output_root)
} else {
  message("No summaries generated.")
}

message("All enrichment analyses complete.")
