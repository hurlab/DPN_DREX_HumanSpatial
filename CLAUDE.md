# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains R scripts for analyzing diabetic peripheral neuropathy (DPN) using mouse peripheral nerve scRNA-seq data compared against human spatial transcriptomics and bulk RNA-seq datasets. The primary focus is on Schwann cell populations and their differential gene expression across diet/exercise interventions (SD, HFD, DR, DREX, EX).

## Key Datasets

### Mouse scRNA-seq DEG Files
- **DEG/**: Fine-grained cell type DEG files (mySC, nmSC, ImmSC, SC3, Endo, Mac, Pericytes, etc.)
- **DEG_Major/**: Major cell type DEG files (majorSC, majorEndo, majorFib, majorMac, etc.)
- Files follow naming convention: `{comparison}_{celltype}.csv` (e.g., `DREXvsDR_mySC.csv`)

### Human Reference Datasets
- **HSuralRNASeq_Human/**: Human sural nerve spatial transcriptomics DEG table
- **DEGs_JCI_DPN/SchwannDEG_Severe-Moderate_noMito.csv**: Human Schwann cell DEGs
- **DEGs_JCI_DPN/JCI184075.sdd3_BulkRNAseqDEGs.xlsx**: Human bulk RNA-seq DEGs from JCI paper

### Schwann Cell Types
When filtering for Schwann cells, include these cell types:
- `mySC` (myelinating Schwann cells)
- `nmSC` (non-myelinating Schwann cells)
- `ImmSC` (immature Schwann cells)
- `SC3` (Schwann cell subtype 3)
- `majorSC` (major Schwann cell category in DEG_Major/)

## Active Analysis Scripts

### Primary Enrichment Script
**Location**: `251120_CompHuman-SpatialJCI/analysis_enrichment_JCI_Schwann_mouse.R`

**Purpose**:
- Maps human DEGs to mouse orthologs using homologene
- Compares mouse scRNA-seq DEGs against human Schwann and JCI bulk datasets
- Performs GO/KEGG enrichment analysis on overlap sets
- Outputs gene lists and enrichment tables

**Key Parameters**:
```r
padj_extra_cutoff <- 0.001   # For Schwann/JCI datasets
lfc_extra_cutoff  <- 1       # For Schwann/JCI datasets
min_genes_for_enrichment <- 5
```

**Run Command**:
```bash
cd 251120_CompHuman-SpatialJCI && Rscript analysis_enrichment_JCI_Schwann_mouse.R
```

**Outputs**: `251120_CompHuman-SpatialJCI/Output_JCI_Schwann_enrichment/`

### Comparison Pipeline (archived)
**Location**: `archive/2025-08-21_DREX-Comp-HumanSural_v3.R` (do not modify)

Earlier version that compared all cell types against human spatial data.

## Development Setup

### Required R Packages
Install dependencies using pacman:
```r
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(
  dplyr, tidyr, ggplot2, ggVennDiagram, readxl, homologene,
  pheatmap, openxlsx, AnnotationDbi, org.Mm.eg.db, org.Hs.eg.db,
  richR, clusterProfiler
)
```

### Running Scripts
- Always run scripts from their containing directory so relative paths resolve correctly
- Use `cd {script_directory} && Rscript {script_name}.R`
- For interactive sessions: `R -q` then `source("script.R")`

## Code Architecture

### Human-to-Mouse Gene Mapping
- Uses `homologene::homologeneData` to map between species
- Function: `build_human_to_mouse_map()` creates Human_Symbol -> Mouse_Symbol lookup table
- Takes first match (lowest Entrez ID) when multiple mouse orthologs exist
- Function: `map_genes_to_mouse(genes, mapping_tbl)` converts gene lists

### DEG File Reading Functions
- `read_human_deg()`: Reads human spatial data (padj < 0.05)
- `read_schwann_deg()`: Reads Schwann DEGs with custom cutoffs (abs(log2FC) > 1, padj < 0.001)
- `read_jci_bulk_deg()`: Reads JCI bulk Excel file with custom cutoffs
- `read_mouse_deg_file()`: Reads mouse scRNA-seq CSVs (padj < 0.05)

All functions normalize column names to lowercase with underscores for robustness.

### Enrichment Analysis Workflow
1. **Load datasets**: Human Schwann, JCI bulk, mouse scRNA-seq
2. **Map to mouse orthologs**: Convert human genes to mouse symbols
3. **For each mouse DEG file**:
   - Calculate overlap sets: Mouse∩Schwann, Mouse∩JCI, Schwann∩JCI, all three
   - Calculate unique sets: Mouse-only, Schwann-only, JCI-only
   - Save gene lists as CSV files
   - Run enrichment if ≥ 5 genes in set
4. **Enrichment methods** (in order of preference):
   - `richR::richGO()` and `richR::richKEGG()` if available
   - Fallback: `clusterProfiler::enrichGO()` (GO:BP, SYMBOL) and `enrichKEGG()` (KEGG, Entrez)
5. **Output summary**: Master Excel workbook with counts per comparison/cell type

### Output Structure
```
Output_JCI_Schwann_enrichment/
├── Master_Enrichment_Summary.csv
├── Master_Enrichment_Summary.xlsx
└── {comparison}_{celltype}_enrichment/
    ├── Mouse_all_Genes.csv
    ├── Schwann_all_Genes.csv
    ├── JCI_all_Genes.csv
    ├── Overlap_MS_Genes.csv
    ├── Overlap_MJ_Genes.csv
    ├── Overlap_SJ_Genes.csv
    ├── Overlap_All3_Genes.csv
    ├── Mouse_only_Genes.csv
    ├── Schwann_only_Genes.csv
    ├── JCI_only_Genes.csv
    ├── {set}_richR_GO.csv
    ├── {set}_richR_KEGG.csv
    ├── {set}_clusterProfiler_GO.csv
    └── {set}_clusterProfiler_KEGG.csv
```

## Optimization Opportunities

### Current Bottlenecks
1. **Sequential enrichment**: Enrichment runs sequentially per gene set (10 sets × N files)
2. **Rich annotation building**: `richR::buildAnnot()` called repeatedly for same organism
3. **Single-threaded execution**: No parallel processing across files or gene sets

### Parallelization Strategy
- Use `parallel::mclapply()` or `future.apply::future_lapply()` for file-level parallelism
- Pre-build richR annotation objects once before loop
- Parallelize enrichment across multiple gene sets within each file
- Consider `BiocParallel::bplapply()` for KEGG/GO enrichment

## Coding Conventions

### Style
- **Tidyverse style**: pipe-friendly, snake_case names, 2-space indentation
- **Package loading**: Always use `pacman::p_load()` for auto-installation
- **Column name normalization**: `tolower(gsub("\\s+", "_", colnames(df)))`

### Helper Functions
- `safe_base(x, limit = 150)`: Sanitizes file names for Windows paths
- `save_df(df, path)`: Writes CSV with automatic directory creation
- `save_plot(p, path, ...)`: Saves ggplot as PNG/PDF
- `sanitize_sheet(x)`: Cleans Excel sheet names (31-char limit, no special chars)

### File Naming
- Use `safe_base()` to sanitize all derived file names
- Limit to 150 characters for Windows compatibility
- Remove special characters except `._-`

## Comparison Groups

Mouse intervention groups being compared:
- **SD**: Standard diet
- **HFD**: High-fat diet
- **DR**: Diet restriction
- **DREX**: Diet restriction + exercise
- **EX**: Exercise only

Common comparisons in DEG files:
- `DREXvsDR`, `DREXvsHFD`, `DRvsHFD`, `DRvsSD`, `HFDvsSD`, `EXvsHFD`, `EXvsDREX`

## Important Notes

- **Archive folders**: Do not modify or process scripts in `archive/` subdirectories
- **Relative paths**: Scripts assume execution from their containing directory
- **Timeouts**: Enrichment can timeout for large gene sets (>500 genes); consider splitting
- **Missing values**: Human-to-mouse mapping may lose ~10-30% of genes without orthologs
- **Reproducibility**: All outputs are deterministic; safe to regenerate from source data
