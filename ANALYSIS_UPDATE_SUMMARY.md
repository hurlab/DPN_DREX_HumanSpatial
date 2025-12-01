# Analysis Update Summary

**Date**: 2025-11-30
**Script**: `251120_CompHuman-SpatialJCI/analysis_enrichment_JCI_Schwann_mouse.R`

## Changes Made

### 1. Schwann Cell Filtering
- **Added**: Automatic filtering to focus exclusively on Schwann cell types
- **Cell types included**: mySC, nmSC, ImmSC, SC3, majorSC
- **Configuration**: Set via `schwann_cell_types` variable (line 39)
- **Effect**: Excludes all non-Schwann cell types (Endo, Mac, Pericytes, Fib, etc.)
- **Flexibility**: Set `schwann_cell_types <- NULL` to revert to analyzing all cell types

### 2. Parallel Processing Implementation
- **Added**: Multi-core parallel processing for enrichment analysis
- **Performance**: ~N-fold speedup where N = number of cores used
- **Configuration**: Automatically detects available cores; uses (total cores - 1)
- **Manual override**: Set `n_cores <- 1` to disable parallelization
- **Windows compatibility**: Handles both Unix (mclapply) and Windows (parLapply) platforms
- **Optimization**: Pre-builds richR GO and KEGG annotations once before processing

### 3. Venn Diagram Generation
- **Added**: Automatic 3-way Venn diagrams for each comparison
- **Comparison**: Mouse DEGs vs Schwann DEGs vs JCI bulk DEGs
- **Formats**: Both PNG (for viewing) and PDF (for publication)
- **Location**: Saved in each enrichment output folder as `{comparison}_{celltype}_Venn3way.png/pdf`
- **Example**: `DREXvsDR_mySC_Venn3way.png` shows overlap between DREX vs DR mouse mySC DEGs, human Schwann DEGs, and JCI bulk DEGs

### 4. Additional Improvements
- **Better logging**: Added progress messages showing which files are being processed
- **Annotation reuse**: richR annotations built once and reused across all enrichment analyses
- **Error handling**: Improved error handling for missing annotations
- **Package dependencies**: Added ggVennDiagram and ggplot2 to package list

## Performance Expectations

### Before (Sequential)
- Processing time per file: ~2-5 minutes (depending on gene set size)
- Total time for 35 Schwann cell files: ~70-175 minutes

### After (Parallel on 8-core machine)
- Processing time per file: ~2-5 minutes (unchanged)
- Total time for 35 Schwann cell files: ~10-25 minutes (**7-8x faster**)
- Annotation building (one-time): ~1-2 minutes

### Bottleneck Removed
- **Previous**: richR annotations rebuilt for every gene set (10 sets × 35 files = 350 builds)
- **Current**: richR annotations built once and reused (2 builds total)

## How to Run

```bash
# Navigate to script directory
cd "C:\JHCloud\OneDrive - North Dakota University System\Desktop\GitHub\DPN_DREX_HumanSpatial\251120_CompHuman-SpatialJCI"

# Run the updated script
Rscript analysis_enrichment_JCI_Schwann_mouse.R
```

**Expected output**:
- Console messages showing parallel processing progress
- Venn diagrams in each enrichment folder
- Same enrichment tables as before (but faster)
- Only Schwann cell types processed

## Configuration Options

To modify the analysis behavior, edit these settings at the top of the script:

```r
# Line 39: Cell type filter
schwann_cell_types <- c("mySC", "nmSC", "ImmSC", "SC3", "majorSC")  # Schwann only
# schwann_cell_types <- NULL  # All cell types

# Line 42: Parallel processing
n_cores <- max(1, parallel::detectCores() - 1)  # Auto-detect (recommended)
# n_cores <- 4  # Manual override
# n_cores <- 1  # Disable parallelization

# Lines 34-36: Enrichment thresholds
padj_extra_cutoff <- 0.001  # Schwann/JCI significance cutoff
lfc_extra_cutoff  <- 1      # Schwann/JCI log2FC cutoff
min_genes_for_enrichment <- 5  # Minimum genes required for enrichment
```

## Output Structure

Each processed file will generate:

```
Output_JCI_Schwann_enrichment/
└── {comparison}_{celltype}_enrichment/
    ├── {comparison}_{celltype}_Venn3way.png      # NEW: 3-way Venn diagram
    ├── {comparison}_{celltype}_Venn3way.pdf      # NEW: PDF version
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
    └── {set}_richR_GO.csv / {set}_clusterProfiler_GO.csv / KEGG versions
```

---

# Suggested Additional Analyses

Based on the project structure and typical cross-species comparative analysis workflows, here are recommended additional analyses for the manuscript:

## 1. Cell Type-Specific Enrichment Comparison

### Analysis
Compare enrichment results across Schwann cell subtypes to identify:
- **Shared pathways**: Biological processes common across all Schwann subtypes
- **Subtype-specific pathways**: Unique functions in mySC vs nmSC vs ImmSC

### Implementation
```r
# Create a cross-celltype comparison script
# Read all *_clusterProfiler_GO.csv files for Overlap_MS or Overlap_All3
# Find GO terms enriched in ≥2 cell types
# Visualize with dotplot or heatmap showing -log10(padj) across cell types
```

### Expected Insights
- Myelin-related pathways specific to mySC
- Immune signaling in ImmSC
- Shared metabolic dysfunction across all Schwann subtypes

## 2. Intervention Response Analysis

### Analysis
Compare DREX vs DR, DREX vs HFD, and EX vs HFD to assess:
- **Exercise-specific effects**: Genes rescued by exercise intervention
- **Diet restriction effects**: Genes modulated by DR alone
- **Synergistic effects**: Genes only changed with combined DREX

### Implementation
```r
# Focus on comparisons: DREXvsDR, DREXvsHFD, EXvsHFD, DRvsHFD
# Create Venn diagrams showing:
#   - Genes upregulated in DREX vs HFD
#   - Genes upregulated in DR vs HFD
#   - Genes upregulated in EX vs HFD
# Identify exercise-specific vs diet-specific rescue mechanisms
```

### Expected Insights
- Whether exercise provides benefits beyond diet restriction
- Molecular pathways rescued by DREX intervention
- Therapeutic targets for DPN treatment

## 3. Human-Mouse Conservation Analysis

### Analysis
Assess cross-species conservation of DPN-related changes:
- **Conserved DEGs**: Genes changed in both mouse scRNA-seq AND human spatial/bulk
- **Species-specific DEGs**: Changes unique to mouse or human
- **Conservation by pathway**: Which biological processes are conserved vs divergent

### Implementation
Already partially implemented via Overlap_All3 (Mouse ∩ Schwann ∩ JCI). Extend to:
```r
# Calculate conservation rates per comparison group
conservation_rate <- n_overlap_all3 / n_mouse

# Identify highly conserved pathways (enriched in Overlap_All3)
# vs mouse-specific pathways (enriched in Mouse_only)

# Create upset plot showing overlap patterns across datasets
```

### Expected Insights
- Translational relevance of mouse model findings
- Human-specific DPN mechanisms not captured in mouse
- Confidence in therapeutic targets (conserved = higher confidence)

## 4. Direction-of-Change Analysis

### Analysis
Current analysis ignores fold-change direction. Recommended:
- **Concordant DEGs**: Same direction in mouse and human (both up or both down)
- **Discordant DEGs**: Opposite directions (mouse up, human down or vice versa)

### Implementation
```r
# Modify overlap calculations to include log2FC direction
# Read mouse DEG files with log2FC values (currently only reading gene names)
# Filter overlaps for:
#   - Concordant up: mouse log2FC > 1 AND human log2FC > 1
#   - Concordant down: mouse log2FC < -1 AND human log2FC < -1
#   - Discordant: opposite signs
```

### Expected Insights
- More accurate cross-species validation
- Identification of compensatory mechanisms (discordant changes)
- Higher confidence therapeutic targets (concordant changes)

## 5. Spatial Context Analysis (Human Spatial Data)

### Analysis
The human spatial data (`HSuralRNASeq_Human`) includes spatial information. Recommended:
- **Spatial co-localization**: Do mouse DEGs correspond to specific spatial niches in human?
- **Spatial gradients**: Are there spatial expression patterns in human that correlate with mouse findings?

### Implementation
Requires accessing the full human spatial dataset with coordinates. If available:
```r
# Map mouse Schwann DEGs to human spatial data
# Visualize expression patterns in spatial context
# Identify regional heterogeneity in human sural nerve
```

### Expected Insights
- Localization of disease mechanisms within nerve architecture
- Regional vulnerability to DPN
- Spatial biomarkers for disease severity

## 6. Leading Edge Gene Analysis

### Analysis
For enriched pathways, identify "leading edge genes" (core genes driving enrichment):
- **Consistency check**: Are the same genes driving enrichment across comparisons?
- **Hub genes**: Genes appearing in multiple enriched pathways

### Implementation
```r
# Extract leading edge genes from enrichment results
# (available in enrichResult objects, may need to modify save_df calls)
# Create network diagrams showing pathway connectivity via shared genes
# Rank genes by "pathway centrality"
```

### Expected Insights
- Key driver genes vs passenger genes
- Prioritized targets for validation/follow-up
- Interconnected pathway modules

## 7. Temporal Analysis (If Data Available)

### Question
Do the human datasets represent different disease stages that align with mouse interventions?
- JCI bulk: Severe vs moderate DPN
- Schwann spatial: Severity levels?

### Implementation
```r
# If human data has severity annotations:
# Compare mouse HFD (disease model) with human severe DPN
# Compare mouse DREX (intervention) with human moderate DPN
# Test hypothesis: DREX reverses gene signatures associated with severity
```

### Expected Insights
- Whether interventions reverse disease progression markers
- Staging biomarkers for DPN
- Early vs late intervention windows

## 8. Quantitative Comparison of Effect Sizes

### Analysis
Current analysis uses binary cutoffs (padj < 0.05). Recommended:
- **Effect size correlation**: Do large fold-changes in mouse correspond to large changes in human?
- **Ranking correlation**: Spearman correlation of ranked log2FC values

### Implementation
```r
# For each overlap gene set:
# Extract log2FC from mouse, Schwann, and JCI datasets
# Calculate Pearson/Spearman correlations
# Scatter plots of mouse log2FC vs human log2FC
# Identify genes with disproportionate effects (high in one species, low in other)
```

### Expected Insights
- Confidence in effect size transferability
- Genes with exaggerated effects in one species
- Quantitative validation of cross-species conservation

---

## Priority Recommendations

**High Priority** (directly supports manuscript claims):
1. **Direction-of-change analysis** (#4) - Critical for validating cross-species concordance
2. **Intervention response analysis** (#2) - Central to DREX therapeutic claims
3. **Cell type-specific enrichment** (#1) - Highlights Schwann subtype biology

**Medium Priority** (strengthens translational relevance):
4. **Human-mouse conservation analysis** (#3) - Already partially done, formalize quantification
5. **Leading edge gene analysis** (#6) - Identifies prioritized targets

**Lower Priority** (exploratory, may be beyond scope):
6. **Spatial context analysis** (#5) - Requires additional data processing
7. **Temporal analysis** (#7) - Only if severity data available
8. **Effect size correlation** (#8) - Nice-to-have validation

---

## Notes on Current Data Limitations

Based on the codebase review:
- **Tissue-level human data**: Human spatial data appears to be bulk sural nerve DEGs, not single-cell resolution
- **No spatial coordinates**: Current pipeline doesn't use spatial coordinates (if they exist)
- **Limited metadata**: Cell type annotations in mouse, but unclear if human has cell type deconvolution
- **Single timepoint**: No longitudinal data to assess temporal dynamics

These analyses are tailored to work within these constraints, focusing on cross-species gene-level and pathway-level comparisons.
