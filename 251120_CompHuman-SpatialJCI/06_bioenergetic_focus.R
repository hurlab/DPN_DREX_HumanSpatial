################################################################################
# Bioenergetic-focused analyses for mouse scRNA DEGs vs Schwann/JCI human DEGs
# - Overlap and directionality (mouse vs Schwann vs JCI)
# - Metabolic/lactate-support scores per comparison
# - RichR enrichment (GO BP + KEGG) on overlaps/unique sets
# - Optional rank-based GSEA on curated metabolic gene sets (fgsea if available)
# Outputs: Output_Bioenergetic_Focus/
################################################################################

if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  script_path <- rstudioapi::getActiveDocumentContext()$path
  setwd(dirname(script_path))
}

options(repos = c(CRAN = "https://cloud.r-project.org"))

if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(
  dplyr, tidyr, readxl, tibble, purrr, stringr,
  homologene, openxlsx
)

################################################################################
# Settings
################################################################################
schwann_deg_path <- "./DEGs_JCI_DPN/SchwannDEG_Severe-Moderate_noMito.csv"
jci_deg_path     <- "./DEGs_JCI_DPN/JCI184075.sdd3_BulkRNAseqDEGs.xlsx"
jci_deg_sheet    <- "deseq2_results"

mouse_deg_dirs <- c("../DEG", "../DEG_Major")
output_root    <- "Output_JCI/Bioenergetic_Focus"

# Cell type and comparison filters
schwann_cell_types <- c("mySC", "nmSC", "ImmSC", "majorSC")
comparison_groups <- c("HFDvsSD", "DRvsHFD", "EXvsHFD", "DREXvsHFD")

padj_mouse_cutoff    <- 0.05
padj_human_cutoff    <- 0.001
lfc_human_cutoff     <- 1
min_genes_enrich     <- 5

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
    dplyr::transmute(Gene = as.character(.data[[gene_col]]),
                     log2FC = .data[[lfc_col]],
                     padj = .data[[padj_col]])
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
                     padj = .data[[padj_col]])
}

read_mouse_deg_file <- function(file_path, padj_cutoff = 0.05) {
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
    dplyr::filter(.data[[padj_col]] < padj_cutoff) %>%
    dplyr::transmute(Gene = gene, log2FC = .data[[lfc_col]], padj = .data[[padj_col]])
}

################################################################################
# Gene sets (curated metabolic focus)
################################################################################
metabolic_sets <- list(
  Lactate_Shuttle = c("Slc16a1", "Slc16a3", "Ldha", "Ldhb", "Pdk1", "Pdk3", "Pdk4",
                      "Ppargc1a", "Hk2", "Pfkp", "Pkm", "Pdhb", "Pdha1", "Pdha2"),
  Glycolysis_Core = c("Hk1", "Hk2", "Gpi1", "Pfkfb3", "Pfkp", "Aldoa", "Gapdh",
                      "Pgk1", "Pgk2", "Pglyrp1", "Eno1", "Eno2", "Pkm", "Pklr", "Ldha", "Ldhb"),
  OXPHOS_Complex = c("Ndufa1", "Ndufa2", "Ndufb3", "Ndufs1", "Ndufs2", "Ndufv1",
                     "Sdha", "Sdhb", "Uqcrc1", "Uqcrc2", "Cox4i1", "Cox5b",
                     "Atp5f1a", "Atp5f1b", "Atp5mc1", "Atp5mc2"),
  FA_Oxidation = c("Cpt1a", "Cpt1b", "Cpt2", "Acadm", "Acadl", "Acads", "Echs1",
                   "Hadha", "Hadhb", "Acox1", "Decr1", "Ppara"),
  HIF_Response = c("Hif1a", "Vegfa", "EglN3", "Slc2a1", "Slc2a3", "Pdk1", "Pdk3",
                   "P4ha1", "P4ha2", "Adm", "Car9", "Bnip3")
)

################################################################################
# Enrichment wrappers
################################################################################
run_richr_enrichment <- function(genes, set_name, out_dir, organism = "mmu") {
  if (length(genes) < min_genes_enrich) return(NULL)
  if (!requireNamespace("richR", quietly = TRUE)) {
    warning("richR not installed; skipping ", set_name)
    return(NULL)
  }
  rich_fun <- get0("rich_enrich", envir = asNamespace("richR"), inherits = FALSE)
  if (is.null(rich_fun)) {
    warning("rich_enrich not found in richR; skipping ", set_name)
    return(NULL)
  }
  res <- tryCatch(
    rich_fun(gene = genes, enrichDatabase = c("GO_Biological_Process_2021", "KEGG_2021_Mouse"), organism = organism),
    error = function(e) { warning("richR failed for ", set_name, ": ", conditionMessage(e)); NULL }
  )
  if (!is.null(res)) {
    out_path <- file.path(out_dir, paste0(set_name, "_richR.csv"))
    save_df(as.data.frame(res), out_path)
  }
}

run_fgsea_sets <- function(ranks, set_list, set_name, out_dir) {
  if (!requireNamespace("fgsea", quietly = TRUE)) {
    warning("fgsea not installed; skipping GSEA for ", set_name)
    return(NULL)
  }
  ranks <- sort(ranks, decreasing = TRUE)
  # Drop zero ranks to avoid noise
  ranks <- ranks[!is.na(ranks) & ranks != 0]
  if (length(ranks) < 10) return(NULL)
  res <- tryCatch(
    fgsea::fgsea(pathways = set_list, stats = ranks, minSize = 5, maxSize = 500, nperm = 2000),
    error = function(e) { warning("fgsea failed for ", set_name, ": ", conditionMessage(e)); NULL }
  )
  if (!is.null(res)) {
    save_df(as.data.frame(res), file.path(out_dir, paste0(set_name, "_fgsea.csv")))
  }
}

################################################################################
# Load data
################################################################################
human2mouse <- build_human_to_mouse_map()

schwann_deg <- read_schwann_deg(schwann_deg_path, lfc_cutoff = lfc_human_cutoff, padj_cutoff = padj_human_cutoff)
schwann_mouse <- map_genes_to_mouse(schwann_deg$Gene, human2mouse)

jci_deg <- read_jci_bulk_deg(jci_deg_path, sheet = jci_deg_sheet, lfc_cutoff = lfc_human_cutoff, padj_cutoff = padj_human_cutoff)
jci_mouse <- map_genes_to_mouse(jci_deg$Gene, human2mouse)

################################################################################
# Main loop
################################################################################
all_summary <- list()

for (input_dir in mouse_deg_dirs) {
  files <- list.files(input_dir, pattern = "\\.csv$", full.names = TRUE, recursive = FALSE)
  files <- files[!basename(files) %>% startsWith(".")]
  files <- files[!grepl("spia", basename(files), ignore.case = TRUE)]

  # Filter by cell type and comparison group
  files <- files[sapply(files, function(f) {
    parts <- strsplit(safe_base(tools::file_path_sans_ext(basename(f))), "_", fixed = TRUE)[[1]]
    comp_group <- if (length(parts) >= 1) parts[1] else NA_character_
    cell_type <- if (length(parts) >= 2) parts[2] else NA_character_

    cell_pass <- !is.na(cell_type) && cell_type %in% schwann_cell_types
    comp_pass <- !is.na(comp_group) && comp_group %in% comparison_groups

    cell_pass && comp_pass
  })]

  message("=== Folder: ", input_dir, " ===")

  for (mouse_file in files) {
    message("Processing: ", basename(mouse_file))
    base <- safe_base(tools::file_path_sans_ext(basename(mouse_file)))
    parts <- strsplit(base, "_", fixed = TRUE)[[1]]
    comp_group <- if (length(parts) >= 1) parts[1] else NA_character_
    cell_type  <- if (length(parts) >= 2) parts[2] else NA_character_
    
    m_df <- read_mouse_deg_file(mouse_file, padj_cutoff = padj_mouse_cutoff)
    if (is.null(m_df) || nrow(m_df) == 0) {
      warning("Skipping (no usable genes): ", basename(mouse_file))
      next
    }
    mouse_genes <- unique(m_df$Gene)
    
    # Overlaps
    overlap_ms   <- intersect(mouse_genes, schwann_mouse)
    overlap_mj   <- intersect(mouse_genes, jci_mouse)
    overlap_sj   <- intersect(schwann_mouse, jci_mouse)
    overlap_all3 <- Reduce(intersect, list(mouse_genes, schwann_mouse, jci_mouse))
    
    mouse_only   <- setdiff(mouse_genes, union(schwann_mouse, jci_mouse))
    schwann_only <- setdiff(schwann_mouse, union(mouse_genes, jci_mouse))
    jci_only     <- setdiff(jci_mouse, union(mouse_genes, schwann_mouse))
    
    # Directionality concordance (mouse vs Schwann/JCI where applicable)
    concord_ms <- m_df %>%
      dplyr::filter(Gene %in% overlap_ms) %>%
      dplyr::mutate(sign_mouse = sign(log2FC))
    conc_ms_dir <- tibble(
      n_ms_concord_up = sum(concord_ms$sign_mouse > 0),
      n_ms_concord_down = sum(concord_ms$sign_mouse < 0)
    )
    
    concord_mj <- m_df %>%
      dplyr::filter(Gene %in% overlap_mj) %>%
      dplyr::mutate(sign_mouse = sign(log2FC))
    conc_mj_dir <- tibble(
      n_mj_concord_up = sum(concord_mj$sign_mouse > 0),
      n_mj_concord_down = sum(concord_mj$sign_mouse < 0)
    )
    
    # Lactate-support score
    lactate_genes <- metabolic_sets$Lactate_Shuttle
    lactate_df <- m_df %>% dplyr::filter(Gene %in% lactate_genes)
    lactate_score <- if (nrow(lactate_df) == 0) NA_real_ else mean(lactate_df$log2FC, na.rm = TRUE)
    
    # Mito proportion (simple proxy)
    mito_go <- c("Cox4i1", "Cox5b", "Atp5f1a", "Atp5f1b", "Ndufs1", "Ndufs2", "Ndufv1",
                 "Sdha", "Sdhb", "Uqcrc1", "Uqcrc2", "Cox6a1", "Cox7b", "Tomm20", "Tomm40")
    mito_df <- m_df %>% dplyr::filter(Gene %in% mito_go)
    mito_up   <- sum(mito_df$log2FC > 0)
    mito_down <- sum(mito_df$log2FC < 0)
    
    # Output directory per comparison
    per_out <- file.path(output_root, base)
    dir.create(per_out, showWarnings = FALSE, recursive = TRUE)
    
    # Save gene lists
    save_df(tibble(Gene = sort(mouse_genes)), file.path(per_out, "Mouse_SignifGenes.csv"))
    save_df(tibble(Gene = sort(schwann_mouse)), file.path(per_out, "Schwann_Mouse_SignifGenes.csv"))
    save_df(tibble(Gene = sort(jci_mouse)), file.path(per_out, "JCI_Mouse_SignifGenes.csv"))
    save_df(tibble(Gene = sort(overlap_ms)), file.path(per_out, "Overlap_Mouse_Schwann.csv"))
    save_df(tibble(Gene = sort(overlap_mj)), file.path(per_out, "Overlap_Mouse_JCI.csv"))
    save_df(tibble(Gene = sort(overlap_all3)), file.path(per_out, "Overlap_AllThree.csv"))
    save_df(tibble(Gene = sort(mouse_only)), file.path(per_out, "Mouse_only.csv"))
    save_df(tibble(Gene = sort(schwann_only)), file.path(per_out, "Schwann_only.csv"))
    save_df(tibble(Gene = sort(jci_only)), file.path(per_out, "JCI_only.csv"))
    
    # Enrichment (richR) on overlaps/uniques
    enrich_sets <- list(
      Overlap_MS   = overlap_ms,
      Overlap_MJ   = overlap_mj,
      Overlap_All3 = overlap_all3,
      Mouse_only   = mouse_only,
      Schwann_only = schwann_only,
      JCI_only     = jci_only
    )
    purrr::iwalk(enrich_sets, function(gs, nm) {
      run_richr_enrichment(gs, nm, out_dir = per_out)
    })
    
    # Rank-based GSEA on metabolic sets (mouse DEGs)
    ranks <- m_df %>% dplyr::transmute(Gene, rank = log2FC) %>% tibble::deframe()
    run_fgsea_sets(ranks, metabolic_sets, set_name = "MetabolicPanels", out_dir = per_out)
    
    all_summary[[length(all_summary) + 1]] <- tibble(
      file = basename(mouse_file),
      comp_group = comp_group,
      cell_type = cell_type,
      n_mouse = length(mouse_genes),
      n_schwann = length(schwann_mouse),
      n_jci = length(jci_mouse),
      n_overlap_ms = length(overlap_ms),
      n_overlap_mj = length(overlap_mj),
      n_overlap_all3 = length(overlap_all3),
      lactate_score = lactate_score,
      mito_up = mito_up,
      mito_down = mito_down,
      n_ms_concord_up = conc_ms_dir$n_ms_concord_up,
      n_ms_concord_down = conc_ms_dir$n_ms_concord_down,
      n_mj_concord_up = conc_mj_dir$n_mj_concord_up,
      n_mj_concord_down = conc_mj_dir$n_mj_concord_down
    )
  }
}

################################################################################
# Master summary workbook
################################################################################
if (length(all_summary) > 0) {
  master <- dplyr::bind_rows(all_summary) %>%
    dplyr::arrange(dplyr::desc(n_overlap_all3), dplyr::desc(n_overlap_ms), dplyr::desc(n_overlap_mj))
  save_df(master, file.path(output_root, "Master_Bioenergetic_Summary.csv"))
  
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
  
  openxlsx::saveWorkbook(wb, file.path(output_root, "Master_Bioenergetic_Summary.xlsx"), overwrite = TRUE)
  message("Bioenergetic summary written to ", output_root)
} else {
  message("No summaries generated.")
}

message("Bioenergetic analyses complete.")
