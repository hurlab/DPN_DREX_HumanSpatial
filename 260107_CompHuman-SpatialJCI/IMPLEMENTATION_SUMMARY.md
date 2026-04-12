# Implementation Summary: Cibersort Schwann Cell DEG Analysis Pipeline

**Date:** January 8, 2026
**Task:** Create analysis scripts for Cibersort-derived human Schwann cell DEGs
**Location:** `260107_CompHuman-SpatialJCI/`

---

## 1. Project Setup

### 1.1 New Directory Structure
```
260107_CompHuman-SpatialJCI/
├── DEGs_SchwannCells_C_vs_DPN.xlsx    # Input: Human Cibersort DEGs
├── 01_enrichment_cibersort.R          # Script 1: GO/KEGG enrichment
├── 02_overlap_mouse_cibersort.R       # Script 2: Mouse-human overlap
├── SUMMARY_Cibersort_Analysis.md      # Results interpretation
├── IMPLEMENTATION_SUMMARY.md          # This file
└── Output_260107/                     # All outputs
    ├── 01_Enrichment_Cibersort/
    └── 02_Overlap_Mouse_Cibersort/
```

### 1.2 Input Data
- **File:** `DEGs_SchwannCells_C_vs_DPN.xlsx`
- **Columns:** gene, logFC, AveExpr, t, P.Value, adj.P.Val, B
- **DEG cutoff:** adj.P.Val < 0.05 (as specified by user)
- **Total genes:** 14,528
- **DEGs identified:** 163 (85 upregulated, 78 downregulated)

---

## 2. Script 1: GO and KEGG Enrichment Analysis

### 2.1 File: `01_enrichment_cibersort.R`

**Purpose:** Perform functional enrichment analysis on Cibersort-derived human Schwann cell DEGs

**Key Features:**
1. Reads Excel file using `openxlsx`
2. Filters DEGs using `adj.P.Val < 0.05`
3. Maps human genes to mouse orthologs via `homologene` package
4. Runs GO and KEGG enrichment using `richR`
5. Generates dot plots for visualization
6. Creates comprehensive Excel summary workbook

**Dependencies:**
```r
pacman::p_load(
  dplyr, tidyr, ggplot2, openxlsx, tibble, stringr,
  AnnotationDbi, org.Mm.eg.db, homologene
)
library(richR)  # Installed from GitHub: guokai8/richR
```

**Parameters:**
```r
padj_cutoff <- 0.05               # DEG cutoff (user-specified)
min_genes_for_enrichment <- 5     # Minimum genes for enrichment
```

**Outputs Generated:**

| File | Description |
|------|-------------|
| `Human_Up_Genes.csv` | 85 upregulated human genes |
| `Human_Down_Genes.csv` | 78 downregulated human genes |
| `Human_All_Genes.csv` | All 163 human DEGs |
| `Mouse_Up_Genes.csv` | 73 mouse orthologs (up) |
| `Mouse_Down_Genes.csv` | 69 mouse orthologs (down) |
| `Mouse_All_Genes.csv` | 142 mouse orthologs (all) |
| `GO_All_richR.csv` | 299 GO terms (all DEGs) |
| `GO_Up_richR.csv` | 210 GO terms (upregulated) |
| `GO_Down_richR.csv` | 281 GO terms (downregulated) |
| `KEGG_All_richR.csv` | 3 KEGG pathways (all) |
| `KEGG_Up_richR.csv` | 4 KEGG pathways (up) |
| `KEGG_Down_richR.csv` | 6 KEGG pathways (down) |
| `GO_*.png/pdf` | Dot plots for each GO result |
| `KEGG_*.png/pdf` | Dot plots for each KEGG result |
| `Enrichment_Summary.xlsx` | Excel workbook with all results |

**Key Functions:**
```r
read_cibersort_deg()         # Read and filter Excel DEGs
build_human_to_mouse_map()   # Create ortholog mapping table
map_genes_to_mouse()         # Convert gene symbols
create_dot_plot()            # Generate visualization
```

**Implementation Notes:**
- richR uses different column names than expected:
  - `Padj` (not `p.adjust`)
  - `Term` (not `description`)
  - `Significant` (not `Count`)
- Scripts were updated to handle richR output format correctly
- Dot plots show top 20 terms by adjusted p-value

---

## 3. Script 2: Mouse-Human Overlap Analysis

### 3.1 File: `02_overlap_mouse_cibersort.R`

**Purpose:** Compare Cibersort human DEGs with mouse scRNA-seq DEGs across Schwann cell populations

**Key Features:**
1. Reads mouse DEG files from multiple directories:
   - `../DEG/` - Fine-grained cell types (mySC, nmSC, ImmSC)
   - `../DEG_Major/` - Major cell types (majorSC)
   - `../251120_CompHuman-SpatialJCI/DEGs_aggSC/` - Aggregated Schwann cells
2. Filters for Schwann cell types: `c("mySC", "nmSC", "ImmSC", "majorSC", "aggSC")`
3. Filters for comparisons: `c("HFDvsSD", "DRvsHFD", "EXvsHFD", "DREXvsHFD")`
4. Maps human genes to mouse orthologs for overlap calculation
5. Generates Venn diagrams for each comparison
6. Creates master overlap gene list with occurrence counts

**Dependencies:**
```r
pacman::p_load(
  dplyr, tidyr, ggplot2, openxlsx, tibble, stringr, purrr,
  ggVennDiagram, homologene
)
```

**Parameters:**
```r
padj_cutoff_human <- 0.05    # Human DEG cutoff
pval_cutoff_mouse <- 0.01    # Mouse DEG cutoff (raw p-value)
schwann_cell_types <- c("mySC", "nmSC", "ImmSC", "majorSC", "aggSC")
comparison_groups <- c("HFDvsSD", "DRvsHFD", "EXvsHFD", "DREXvsHFD")
```

**Mouse DEG Files Processed:** 20 total
- 12 from `DEG/` (3 cell types × 4 comparisons)
- 4 from `DEG_Major/` (1 cell type × 4 comparisons)
- 4 from `DEGs_aggSC/` (1 cell type × 4 comparisons)

**Outputs Generated:**

| File | Description |
|------|-------------|
| `Cibersort_Human_Genes.csv` | 163 human DEGs |
| `Cibersort_Mouse_Genes.csv` | 142 mouse orthologs |
| `Overlap_Summary.csv` | Summary table (20 comparisons × 7 columns) |
| `Master_Overlap_Genes.csv` | 48 genes with occurrence counts |
| `Overlap_Summary.xlsx` | Excel workbook with all summaries |
| `{comparison}_{celltype}_overlap/` | Directory per comparison |
| &nbsp;&nbsp;├── `Mouse_all_Genes.csv` | Mouse DEGs for this comparison |
| &nbsp;&nbsp;├── `Overlap_Genes.csv` | Overlapping genes |
| &nbsp;&nbsp;├── `Mouse_only_Genes.csv` | Mouse-specific genes |
| &nbsp;&nbsp;├── `Cibersort_only_Genes.csv` | Human-specific genes |
| &nbsp;&nbsp;└── `Venn_Diagram.png/pdf` | Venn diagram visualization |

**Key Functions:**
```r
read_cibersort_deg()         # Read human DEGs from Excel
read_mouse_deg_file()         # Read mouse DEGs from CSV
build_human_to_mouse_map()    # Create ortholog mapping
map_genes_to_mouse()          # Convert genes
save_venn()                   # Generate Venn diagrams
```

**Overlap Summary Statistics:**
- Maximum overlap: 34 genes (EXvsHFD majorSC)
- Mean overlap: 6.8 genes
- Range: 0-34 genes
- Top overlapping gene: Fkbp3 (appears in 9/20 comparisons)

---

## 4. Key Implementation Decisions

### 4.1 Package Choice: richR vs clusterProfiler
- **Decision:** Used `richR` (as used in original 251120 pipeline)
- **Reason:** Consistency with existing analysis workflow
- **Installation:** From GitHub (`guokai8/richR`) since not on CRAN
- **Note:** richR uses different column naming convention

### 4.2 Human-to-Mouse Ortholog Mapping
- **Package:** `homologene`
- **Approach:** Keep first match when multiple mouse orthologs exist
- **Success rate:** 87.1% (142/163 genes mapped)
- **Limitation:** ~13% of human genes lack clear mouse orthologs

### 4.3 Mouse DEG Filtering
- **Cutoff:** Raw p-value < 0.01 (not adjusted p-value)
- **Reasoning:** Consistent with original 251120 pipeline
- **Note:** This is less stringent than human cutoff (adj.P.Val < 0.05)

### 4.4 Schwann Cell Types Analyzed
```r
c("mySC", "nmSC", "ImmSC", "majorSC", "aggSC")
```
- **mySC:** Myelinating Schwann cells
- **nmSC:** Non-myelinating Schwann cells
- **ImmSC:** Immature Schwann cells
- **majorSC:** Major Schwann cell category
- **aggSC:** Aggregated Schwann cells (mySC + nmSC + ImmSC)

### 4.5 Comparison Groups
```r
c("HFDvsSD", "DRvsHFD", "EXvsHFD", "DREXvsHFD")
```
- **HFDvsSD:** Disease baseline (high-fat diet vs standard diet)
- **DRvsHFD:** Diet restriction intervention
- **EXvsHFD:** Exercise intervention
- **DREXvsHFD:** Combined diet restriction + exercise

---

## 5. Technical Challenges and Solutions

### 5.1 Challenge: richR Package Not on CRAN
**Solution:**
```r
if (!requireNamespace("richR", quietly = TRUE)) {
  if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes")
  remotes::install_github("guokai8/richR", quiet = TRUE)
}
```

### 5.2 Challenge: Different Column Names in richR Output
**Issue:** richR uses `Padj`, `Term`, `Significant` instead of `p.adjust`, `description`, `Count`

**Solution:** Updated script to use correct column names:
```r
# Before (incorrect):
go_df$neg_log10_padj <- -log10(go_df$p.adjust)
top_terms <- enrich_df %>% dplyr::arrange(p.adjust) %>% dplyr::pull(description)

# After (correct):
go_df$neg_log10_padj <- -log10(go_df$Padj)
top_terms <- enrich_df %>% dplyr::arrange(Padj) %>% dplyr::pull(Term)
```

### 5.3 Challenge: Bioconductor Version Compatibility
**Issue:** R 4.5 requires Bioconductor 3.22, but some packages expect 3.20

**Solution:** Used `org.Mm.eg.db` only (mouse annotation); removed `org.Hs.eg.db` dependency since we map to mouse orthologs before enrichment

### 5.4 Challenge: Many-to-Many Homologene Mapping
**Issue:** Some human genes map to multiple mouse genes

**Warning:** (Non-critical) "Detected an unexpected many-to-many relationship"

**Decision:** Keep first match (lowest Entrez ID) - consistent with original pipeline

---

## 6. Code Architecture

### 6.1 Helper Functions

**File Path Handling:**
```r
safe_base <- function(x, limit = 150) {
  x <- gsub("[^A-Za-z0-9._-]+", "_", x)
  if (nchar(x) > limit) substr(x, 1, limit) else x
}
```

**CSV Saving:**
```r
save_df <- function(df, path) {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  utils::write.csv(df, path, row.names = FALSE)
}
```

**Plot Saving:**
```r
save_plot <- function(p, path, width = 10, height = 8, dpi = 300) {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  ggplot2::ggsave(filename = path, plot = p, width = width, height = height, dpi = dpi, limitsize = FALSE)
}
```

**Venn Diagram:**
```r
save_venn <- function(set_list, title, out_path) {
  # Uses ggVennDiagram package
  # Generates both PNG and PDF
}
```

### 6.2 Data Reading Functions

**Cibersort Excel:**
```r
read_cibersort_deg <- function(file_path, padj_cutoff = 0.05) {
  df <- openxlsx::read.xlsx(file_path, detectDates = FALSE)
  cn <- tolower(gsub("\\s+", "_", colnames(df)))
  colnames(df) <- cn
  df %>% dplyr::filter(!is.na(gene), gene != "") %>%
       dplyr::filter(adj.p.val < padj_cutoff) %>%
       dplyr::pull(gene)
}
```

**Mouse CSV:**
```r
read_mouse_deg_file <- function(file_path) {
  df <- suppressWarnings(read.csv(file_path, stringsAsFactors = FALSE, check.names = FALSE))
  # Handle empty first column
  # Normalize column names
  # Filter by p_val < 0.01
}
```

---

## 7. Output File Organization

### 7.1 Directory Structure
```
Output_260107/
├── 01_Enrichment_Cibersort/
│   ├── Gene lists (6 CSV files)
│   ├── Enrichment results (6 CSV files)
│   ├── Dot plots (12 files: PNG + PDF for each)
│   ├── Summary.csv
│   └── Enrichment_Summary.xlsx
└── 02_Overlap_Mouse_Cibersort/
    ├── Summary files (3 CSV + 1 XLSX)
    ├── Cibersort reference files (2 CSV)
    └── 20 comparison directories
        └── {comparison}_{celltype}_overlap/
            ├── 4 CSV files
            └── 2 Venn diagrams (PNG + PDF)
```

### 7.2 File Naming Convention
- Enrichment: `{GO|KEGG}_{All|Up|Down}_richR.csv`
- Plots: `{GO|KEGG}_{All|Up|Down}_DotPlot.{png|pdf}`
- Overlap: `{comparison}_{celltype}_overlap/`
- Master files: `Master_Overlap_Genes.csv`, `Overlap_Summary.csv`

---

## 8. Results Summary

### 8.1 Enrichment Analysis Results

**GO Terms:**
- All DEGs: 299 enriched terms (Padj < 0.05)
- Upregulated: 210 terms
- Downregulated: 281 terms

**Top GO Terms (All DEGs):**
1. Spliceosomal tri-snRNP complex assembly (Padj=0.0020)
2. Cysteine transport (Padj=0.0097)
3. Negative regulation of cell cycle process (Padj=0.0104)
4. Attachment of GPI anchor to protein (Padj=0.0135)
5. Ribonucleoprotein complex biogenesis (Padj=0.0146)

**KEGG Pathways:**
- All DEGs: 3 pathways
- Upregulated: 4 pathways
- Downregulated: 6 pathways

**Key KEGG Pathways:**
1. Cell cycle (Padj=0.230)
2. GPI-anchor biosynthesis (Padj=0.659)
3. TGF-beta signaling pathway (Padj=0.659)

### 8.2 Overlap Analysis Results

**Highest Overlaps:**
1. EXvsHFD majorSC: 34 genes (23.9% of human DEGs)
2. EXvsHFD aggSC: 19 genes (13.4%)
3. EXvsHFD mySC: 16 genes (11.3%)

**Most Conserved Genes:**
1. Fkbp3: 9/20 comparisons
2. Faim: 7/20 comparisons
3. Atg13, Gpcpd1, Krit1: 6/20 comparisons each

---

## 9. Usage Instructions

### 9.1 Running the Scripts

**From the 260107_CompHuman-SpatialJCI directory:**

```bash
# Run enrichment analysis
Rscript 01_enrichment_cibersort.R

# Run overlap analysis
Rscript 02_overlap_mouse_cibersort.R
```

**Requirements:**
- R >= 4.0
- Required packages installed via `pacman`
- richR from GitHub
- Input file in same directory: `DEGs_SchwannCells_C_vs_DPN.xlsx`
- Mouse DEG files in relative directories

### 9.2 Modifying Parameters

**To change DEG cutoff:**
```r
padj_cutoff <- 0.01  # More stringent
```

**To analyze different cell types:**
```r
schwann_cell_types <- c("mySC", "nmSC")  # Fewer types
```

**To analyze different comparisons:**
```r
comparison_groups <- c("EXvsHFD", "DREXvsHFD")  # Only interventions
```

---

## 10. Files Created

### 10.1 Analysis Scripts
| File | Lines | Purpose |
|------|-------|---------|
| `01_enrichment_cibersort.R` | ~330 | GO/KEGG enrichment |
| `02_overlap_mouse_cibersort.R` | ~250 | Mouse-human overlap |

### 10.2 Documentation
| File | Purpose |
|------|---------|
| `SUMMARY_Cibersort_Analysis.md` | Biological interpretation of results |
| `IMPLEMENTATION_SUMMARY.md` | This file - technical documentation |

### 10.3 Output Statistics
- Total directories created: 23
- Total CSV files: ~100
- Total PNG files: 20 (Venn) + 6 (GO) + 3 (KEGG) = 29
- Total PDF files: Same as PNG
- Total Excel workbooks: 2

---

## 11. Comparison with Original Pipeline (251120)

### Similarities:
1. Both use `richR` for enrichment
2. Both use `homologene` for ortholog mapping
3. Both filter mouse DEGs by raw p-value < 0.01
4. Both generate Venn diagrams with `ggVennDiagram`
5. Both analyze Schwann cell populations

### Differences:
1. **Simpler focus:** Only 2 scripts vs 10 in original
2. **Single human dataset:** Cibersort only (no JCI_Bulk)
3. **No significance testing:** Script 09 omitted
4. **Different cell type aggregation:** Uses pre-computed aggSC files
5. **Simplified output:** Numbered directories (01, 02) vs detailed structure

### Consistency Achieved:
- Column naming conventions
- File path handling
- Helper function structure
- richR output processing
- Venn diagram styling

---

## 12. Future Enhancements

### Potential Additions:
1. **Direction of change analysis:** Compare up/down regulation patterns
2. **Pathway-level overlap:** Enrichment of overlapping gene sets
3. **Network analysis:** PPI networks for core genes
4. **Statistical testing:** Hypergeometric tests for overlap significance
5. **Visualization:** Heatmaps of overlap patterns

### Code Improvements:
1. Add progress bars for long-running operations
2. Implement parallel processing for enrichment
3. Add error recovery for missing files
4. Create summary HTML report
5. Add command-line argument parsing

---

## 13. Lessons Learned

### 13.1 Package Installation
- GitHub packages need explicit installation handling
- Bioconductor version compatibility matters
- Some packages have non-standard column names

### 13.2 Cross-Species Analysis
- Ortholog mapping always has some failures
- Mouse gene symbols should be used for consistency
- Consider bidirectional mapping for completeness

### 13.3 File Organization
- Numbered directories help with execution order
- Consistent naming prevents confusion
- Separate outputs by analysis type

### 13.4 Documentation
- Implementation notes separate from results
- Technical details help with reproducibility
- Usage examples simplify future work

---

## 14. Validation Checklist

- [x] Scripts run without errors
- [x] All output files generated
- [x] Gene lists contain expected number of genes
- [x] Enrichment results have proper format
- [x] Venn diagrams render correctly
- [x] Dot plots are readable
- [x] Excel workbooks open properly
- [x] Column names are consistent
- [x] File paths are handled correctly
- [x] Results are biologically interpretable

---

**Implementation completed:** January 8, 2026
**Total runtime:** ~5 minutes for both scripts
**Disk usage:** ~2 MB for outputs
**Status:** Ready for use
