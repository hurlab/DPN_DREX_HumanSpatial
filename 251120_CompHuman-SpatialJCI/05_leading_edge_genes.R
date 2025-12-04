################################################################################
# Analysis #5: Leading Edge Gene Analysis
#
# For enriched pathways, identify "leading edge genes" (core genes driving enrichment):
# - Consistency check: Are the same genes driving enrichment across comparisons?
# - Hub genes: Genes appearing in multiple enriched pathways
# - Pathway centrality: Genes ranked by how many pathways they participate in
################################################################################

if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  script_path <- rstudioapi::getActiveDocumentContext()$path
  setwd(dirname(script_path))
}

options(repos = c(CRAN = "https://cloud.r-project.org"))

if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(
  dplyr, tidyr, ggplot2, tibble, purrr, stringr,
  openxlsx, ggraph, igraph
)

################################################################################
# Settings
################################################################################
enrichment_root <- "Output_JCI/00_DEGoverlap_Enrichment_Analysis"
output_dir <- "Output_JCI/05_Leading_Edge_Analysis"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# Cell types to analyze
schwann_cell_types <- c("mySC", "nmSC", "ImmSC", "majorSC", "aggSC")

# Comparison groups
comparison_groups <- c("HFDvsSD", "DRvsHFD", "EXvsHFD", "DREXvsHFD")

# Gene sets to analyze
focus_sets <- c("Overlap_MS", "Overlap_All3")

# Enrichment types (richR only)
enrichment_types <- c("richR_GO", "richR_KEGG")

# Pathway significance cutoff
pathway_padj_cutoff <- 0.05

# Minimum number of pathways for a gene to be considered a hub
min_pathways_for_hub <- 3

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

    cn <- tolower(colnames(df))
    colnames(df) <- cn

    # Identify key columns
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
    geneid_col <- if ("geneid" %in% cn) "geneid" else if ("core_enrichment" %in% cn) "core_enrichment" else if ("genes" %in% cn) "genes" else NULL

    if (is.null(padj_col) || is.null(geneid_col)) return(NULL)

    # Select and filter
    result <- df %>%
      dplyr::select(
        Term = all_of(term_col),
        padj = all_of(padj_col),
        geneID = all_of(geneid_col)
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
message("=== Leading Edge Gene Analysis ===")

# Collect all pathway-gene associations
pathway_gene_associations <- list()
all_hub_genes <- list()

for (comp_group in comparison_groups) {
  message("\n--- Comparison: ", comp_group, " ---")

  for (cell_type in schwann_cell_types) {
    message("  Cell Type: ", cell_type)

    for (gene_set in focus_sets) {
      for (enrich_type in enrichment_types) {

        base_name <- paste0(comp_group, "_", cell_type)
        enrich_folder <- file.path(enrichment_root, paste0(base_name, "_enrichment"))
        enrich_file <- file.path(enrich_folder, paste0(gene_set, "_", enrich_type, ".csv"))

        enrich_data <- read_enrichment_file(enrich_file)
        if (is.null(enrich_data)) next

        # Parse genes from geneID column (usually "/" separated)
        for (i in 1:nrow(enrich_data)) {
          pathway <- enrich_data$Term[i]
          genes_str <- enrich_data$geneID[i]

          if (is.na(genes_str) || genes_str == "") next

          # Split by "/" or "," or ";" depending on format
          genes <- unlist(strsplit(genes_str, split = "[/,;]"))
          genes <- trimws(genes)
          genes <- genes[genes != ""]

          if (length(genes) == 0) next

          # Record associations
          for (gene in genes) {
            pathway_gene_associations[[length(pathway_gene_associations) + 1]] <- tibble(
              comparison = comp_group,
              cell_type = cell_type,
              gene_set = gene_set,
              enrich_type = enrich_type,
              pathway = pathway,
              gene = gene,
              pathway_padj = enrich_data$padj[i]
            )
          }
        }

        message("    ", gene_set, " ", enrich_type, ": ", nrow(enrich_data), " pathways")
      }
    }
  }
}

if (length(pathway_gene_associations) == 0) {
  stop("No pathway-gene associations found. Make sure enrichment analysis has completed.")
}

# Combine all associations
combined_associations <- dplyr::bind_rows(pathway_gene_associations)
save_df(combined_associations, file.path(output_dir, "All_Pathway_Gene_Associations.csv"))

message("\nTotal pathway-gene associations: ", nrow(combined_associations))
message("Unique genes: ", n_distinct(combined_associations$gene))
message("Unique pathways: ", n_distinct(combined_associations$pathway))

################################################################################
# Analysis 1: Hub Gene Identification
################################################################################
message("\n=== Identifying Hub Genes ===")

# Count how many pathways each gene participates in
hub_genes_all <- combined_associations %>%
  dplyr::group_by(gene) %>%
  dplyr::summarise(
    n_pathways = n_distinct(pathway),
    n_comparisons = n_distinct(comparison),
    n_celltypes = n_distinct(cell_type),
    pathways = paste(unique(pathway), collapse = " | "),
    comparisons = paste(unique(comparison), collapse = ", "),
    celltypes = paste(unique(cell_type), collapse = ", "),
    mean_pathway_padj = mean(pathway_padj),
    .groups = "drop"
  ) %>%
  dplyr::arrange(desc(n_pathways), desc(n_comparisons))

save_df(hub_genes_all, file.path(output_dir, "Hub_Genes_All.csv"))

# Filter for true hub genes (≥ min_pathways_for_hub pathways)
hub_genes_filtered <- hub_genes_all %>%
  dplyr::filter(n_pathways >= min_pathways_for_hub)

save_df(hub_genes_filtered, file.path(output_dir, paste0("Hub_Genes_Top_", min_pathways_for_hub, "plus.csv")))

message("Genes in ≥", min_pathways_for_hub, " pathways: ", nrow(hub_genes_filtered))

# Hub genes by cell type
for (cell_type in schwann_cell_types) {
  hub_by_ct <- combined_associations %>%
    dplyr::filter(cell_type == !!cell_type) %>%
    dplyr::group_by(gene) %>%
    dplyr::summarise(
      n_pathways = n_distinct(pathway),
      n_comparisons = n_distinct(comparison),
      pathways = paste(unique(pathway), collapse = " | "),
      .groups = "drop"
    ) %>%
    dplyr::arrange(desc(n_pathways)) %>%
    dplyr::filter(n_pathways >= min_pathways_for_hub)

  if (nrow(hub_by_ct) > 0) {
    save_df(hub_by_ct, file.path(output_dir, paste0("Hub_Genes_", cell_type, ".csv")))
    message("  ", cell_type, ": ", nrow(hub_by_ct), " hub genes")

    all_hub_genes[[cell_type]] <- hub_by_ct
  }
}

################################################################################
# Analysis 2: Hub Gene Visualization
################################################################################
message("\n=== Creating Hub Gene Visualizations ===")

# Plot 1: Top 30 hub genes
top_hubs <- hub_genes_all %>%
  dplyr::slice_head(n = 30)

p1 <- ggplot2::ggplot(top_hubs, ggplot2::aes(x = reorder(gene, n_pathways), y = n_pathways, fill = n_celltypes)) +
  ggplot2::geom_col() +
  ggplot2::coord_flip() +
  ggplot2::theme_bw() +
  ggplot2::labs(
    title = "Top 30 Hub Genes (by Pathway Count)",
    x = "Gene",
    y = "Number of Pathways",
    fill = "# Cell Types"
  ) +
  ggplot2::scale_fill_gradient(low = "lightblue", high = "darkblue")

save_plot(p1, file.path(output_dir, "Top_Hub_Genes.png"), width = 10, height = 12)
save_plot(p1, file.path(output_dir, "Top_Hub_Genes.pdf"), width = 10, height = 12)

# Plot 2: Hub gene distribution by comparison
hub_by_comparison <- combined_associations %>%
  dplyr::group_by(comparison, gene) %>%
  dplyr::summarise(n_pathways = n_distinct(pathway), .groups = "drop") %>%
  dplyr::filter(n_pathways >= min_pathways_for_hub)

p2 <- ggplot2::ggplot(hub_by_comparison, ggplot2::aes(x = comparison, y = n_pathways)) +
  ggplot2::geom_boxplot(fill = "lightblue") +
  ggplot2::geom_jitter(width = 0.2, alpha = 0.3) +
  ggplot2::theme_bw() +
  ggplot2::labs(
    title = "Hub Gene Distribution by Comparison",
    x = "Comparison Group",
    y = "Number of Pathways per Hub Gene"
  )

save_plot(p2, file.path(output_dir, "Hub_Distribution_by_Comparison.png"), width = 10, height = 8)
save_plot(p2, file.path(output_dir, "Hub_Distribution_by_Comparison.pdf"), width = 10, height = 8)

################################################################################
# Analysis 3: Pathway Network Analysis
################################################################################
message("\n=== Creating Pathway Networks ===")

# For each cell type and comparison, create a gene-pathway network
for (comp_group in comparison_groups) {
  for (cell_type in schwann_cell_types) {

    subset_data <- combined_associations %>%
      dplyr::filter(comparison == comp_group, cell_type == !!cell_type, gene_set == "Overlap_All3")

    if (nrow(subset_data) == 0) next

    # Create bipartite graph (genes and pathways)
    # Limit to top pathways and hub genes for visualization
    top_pathways <- subset_data %>%
      dplyr::group_by(pathway) %>%
      dplyr::summarise(n_genes = n_distinct(gene), .groups = "drop") %>%
      dplyr::arrange(desc(n_genes)) %>%
      dplyr::slice_head(n = 15) %>%
      dplyr::pull(pathway)

    hub_genes_in_subset <- subset_data %>%
      dplyr::group_by(gene) %>%
      dplyr::summarise(n_pathways = n_distinct(pathway), .groups = "drop") %>%
      dplyr::filter(n_pathways >= 2) %>%
      dplyr::pull(gene)

    network_data <- subset_data %>%
      dplyr::filter(pathway %in% top_pathways, gene %in% hub_genes_in_subset)

    if (nrow(network_data) == 0) next

    # Create edge list
    edges <- network_data %>%
      dplyr::select(from = gene, to = pathway)

    # Create graph
    tryCatch({
      g <- igraph::graph_from_data_frame(edges, directed = FALSE)

      # Set node types
      igraph::V(g)$type <- ifelse(igraph::V(g)$name %in% network_data$gene, "Gene", "Pathway")

      # Save network plot
      png_path <- file.path(output_dir, paste0(comp_group, "_", cell_type, "_Network.png"))
      pdf_path <- file.path(output_dir, paste0(comp_group, "_", cell_type, "_Network.pdf"))

      png(png_path, width = 12, height = 12, units = "in", res = 300)
      set.seed(42)
      plot(g,
           vertex.color = ifelse(igraph::V(g)$type == "Gene", "lightblue", "salmon"),
           vertex.size = 5,
           vertex.label.cex = 0.6,
           vertex.label.color = "black",
           edge.color = "gray70",
           layout = igraph::layout_with_fr(g),
           main = paste0(comp_group, " ", cell_type, "\nGene-Pathway Network"))
      dev.off()

      pdf(pdf_path, width = 12, height = 12)
      set.seed(42)
      plot(g,
           vertex.color = ifelse(igraph::V(g)$type == "Gene", "lightblue", "salmon"),
           vertex.size = 5,
           vertex.label.cex = 0.6,
           vertex.label.color = "black",
           edge.color = "gray70",
           layout = igraph::layout_with_fr(g),
           main = paste0(comp_group, " ", cell_type, "\nGene-Pathway Network"))
      dev.off()

      message("  Created network: ", comp_group, " ", cell_type)
    }, error = function(e) {
      message("  Error creating network for ", comp_group, " ", cell_type, ": ", e$message)
    })
  }
}

################################################################################
# Analysis 4: Cross-Cell-Type Consistency
################################################################################
message("\n=== Analyzing Cross-Cell-Type Consistency ===")

# Find genes that are hubs across multiple cell types
cross_celltype_hubs <- hub_genes_all %>%
  dplyr::filter(n_celltypes >= 2, n_pathways >= min_pathways_for_hub) %>%
  dplyr::arrange(desc(n_celltypes), desc(n_pathways))

save_df(cross_celltype_hubs, file.path(output_dir, "Cross_CellType_Hub_Genes.csv"))

message("Genes that are hubs in ≥2 cell types: ", nrow(cross_celltype_hubs))

################################################################################
# Summary Report
################################################################################
message("\n=== Creating Summary Report ===")

wb <- openxlsx::createWorkbook()

openxlsx::addWorksheet(wb, "All_Hub_Genes")
openxlsx::writeData(wb, "All_Hub_Genes", hub_genes_all)

if (nrow(hub_genes_filtered) > 0) {
  openxlsx::addWorksheet(wb, "Top_Hub_Genes")
  openxlsx::writeData(wb, "Top_Hub_Genes", hub_genes_filtered)
}

if (nrow(cross_celltype_hubs) > 0) {
  openxlsx::addWorksheet(wb, "Cross_CellType_Hubs")
  openxlsx::writeData(wb, "Cross_CellType_Hubs", cross_celltype_hubs)
}

# Add sheets for each cell type
for (cell_type in names(all_hub_genes)) {
  sheet_name <- paste0("Hubs_", cell_type)
  openxlsx::addWorksheet(wb, sheet_name)
  openxlsx::writeData(wb, sheet_name, all_hub_genes[[cell_type]])
}

openxlsx::saveWorkbook(wb, file.path(output_dir, "Leading_Edge_Analysis.xlsx"), overwrite = TRUE)

message("\n=== Analysis Complete ===")
message("Output directory: ", output_dir)
message("Hub genes identified: ", nrow(hub_genes_filtered))
message("Cross-cell-type hub genes: ", nrow(cross_celltype_hubs))
message("Check for network diagrams and hub gene lists")
