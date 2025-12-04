# Analysis Scripts Summary

## Overview
I've created 6 R analysis scripts for your DPN/DREX Schwann cell project. All scripts are configured to:
- Focus on Schwann cells only (mySC, nmSC, ImmSC, SC3, majorSC)
- Use 24 cores (75% of your 32 cores) for parallel processing
- Generate publication-quality figures (PNG and PDF)
- Create Excel workbooks with organized results

## Script Descriptions

### Main Enrichment Script (Modified)
**File**: `251120_CompHuman-SpatialJCI/analysis_enrichment_JCI_Schwann_mouse.R`

**What it does**:
- Maps human Schwann and JCI bulk DEGs to mouse orthologs
- Compares against mouse scRNA-seq DEGs for Schwann cells
- Performs GO/KEGG enrichment analysis (richR + clusterProfiler)
- Creates 3-way Venn diagrams (Mouse vs Schwann vs JCI)
- Processes only Schwann cell types, not all cell types

**Key updates**:
- ✅ Schwann cell filtering added
- ✅ Parallel processing with 24 cores (Windows compatible)
- ✅ Pre-builds richR annotations once (huge time saver)
- ✅ Automatic Venn diagram generation

**Outputs**:
```
Output_JCI_Schwann_enrichment/
├── Master_Enrichment_Summary.csv
├── Master_Enrichment_Summary.xlsx
└── {comparison}_{celltype}_enrichment/
    ├── {comparison}_{celltype}_Venn3way.png/pdf
    ├── *_Genes.csv (gene lists)
    └── *_richR_GO.csv, *_clusterProfiler_GO.csv, etc.
```

---

### Analysis #1: Cell Type-Specific Enrichment Comparison
**File**: `251120_CompHuman-SpatialJCI/analysis_01_celltype_enrichment_comparison.R`

**What it does**:
- Compares enrichment results across Schwann cell subtypes
- Identifies shared pathways (common across mySC, nmSC, ImmSC, SC3)
- Identifies cell-type-specific pathways
- Creates heatmaps and dot plots showing pathway enrichment patterns

**Key analyses**:
1. Shared vs cell-type-specific pathway classification
2. Heatmaps of top 30 pathways across cell types
3. Dot plots showing pathway significance by cell type

**Outputs**:
```
Output_JCI_Schwann_enrichment/CellType_Comparison/
├── Combined_Enrichment_Results.csv
├── {comparison}_{geneset}_{enrichtype}_SharedVsSpecific.csv
├── {comparison}_{geneset}_{enrichtype}_Heatmap.png/pdf
├── {comparison}_{geneset}_{enrichtype}_DotPlot.png/pdf
├── Summary_Statistics.csv
└── CellType_Enrichment_Comparison.xlsx
```

**Expected insights**:
- Myelin-related pathways specific to mySC
- Immune signaling in ImmSC
- Shared metabolic dysfunction across all Schwann subtypes

---

### Analysis #2: Intervention Response Analysis
**File**: `251120_CompHuman-SpatialJCI/analysis_02_intervention_response.R`

**What it does**:
- Compares DREX vs DR vs EX to assess intervention effects
- Identifies exercise-specific genes (not explained by DR alone)
- Identifies DR-specific genes
- Identifies synergistic DREX effects

**Key analyses**:
1. Venn diagrams: DREXvsHFD, DRvsHFD, EXvsHFD comparisons
2. Gene set decomposition: DREX-specific, DR-specific, EX-specific, shared
3. Exercise rescue analysis: genes unique to exercise intervention

**Outputs**:
```
Output_JCI_Schwann_enrichment/Intervention_Response/
├── {celltype}_{geneset}_DREX_Venn.png/pdf
├── {celltype}_{geneset}_DR_Venn.png/pdf
├── {celltype}_{geneset}_EX_Venn.png/pdf
├── {celltype}_{geneset}_InterventionSets/
│   ├── DREX_specific.csv
│   ├── DR_specific.csv
│   ├── EX_specific.csv
│   └── All_Interventions_shared.csv
├── {celltype}_{geneset}_ExerciseRescue/
│   ├── Exercise_specific_not_DR.csv
│   ├── Exercise_and_DR_synergistic.csv
│   └── DREX_combined_unique.csv
├── Intervention_Response_Summary.csv
├── Exercise_Rescue_Summary.csv
└── Intervention_Response_Analysis.xlsx
```

**Expected insights**:
- Whether exercise provides benefits beyond diet restriction
- Molecular pathways rescued by DREX intervention
- Therapeutic targets for DPN treatment

---

### Analysis #3: Human-Mouse Conservation Analysis
**File**: `251120_CompHuman-SpatialJCI/analysis_03_conservation_analysis.R`

**What it does**:
- Calculates cross-species conservation rates
- Identifies highly conserved genes (present in multiple comparisons)
- Compares conserved vs mouse-specific enriched pathways

**Key analyses**:
1. Conservation rate calculation (% overlap between mouse and human)
2. Highly conserved genes (conserved in ≥2 comparisons within same cell type)
3. Species-specific pathway enrichment comparison

**Outputs**:
```
Output_JCI_Schwann_enrichment/Conservation_Analysis/
├── Conservation_Statistics.csv
├── Conservation_Rate_Schwann.png/pdf
├── Conservation_Rate_JCI.png/pdf
├── Conservation_Comparison_Boxplot.png/pdf
├── Gene_Counts_Comparison.png/pdf
├── {celltype}_HighlyConserved_Genes.csv
├── Species_Specificity_Pathways.csv
├── Species_Specificity_Pathways.png/pdf
└── Conservation_Analysis.xlsx
```

**Expected insights**:
- Translational relevance of mouse model findings
- Human-specific DPN mechanisms not captured in mouse
- Confidence in therapeutic targets (conserved = higher confidence)

---

### Analysis #4: Direction-of-Change Analysis
**File**: `251120_CompHuman-SpatialJCI/analysis_04_direction_of_change.R`

**What it does**:
- Analyzes whether genes change in the same direction across species
- Identifies concordant genes (both up or both down in mouse and human)
- Identifies discordant genes (opposite directions)

**Key analyses**:
1. Direction classification: Concordant, Discordant, Ambiguous
2. Concordance rate calculation by cell type and comparison
3. Separate gene lists for concordant and discordant genes

**Outputs**:
```
Output_JCI_Schwann_enrichment/Direction_Analysis/
├── {comparison}_{celltype}_direction/
│   ├── Mouse_Schwann_direction.csv
│   ├── Mouse_JCI_direction.csv
│   ├── Concordant_Schwann.csv
│   ├── Discordant_Schwann.csv
│   ├── Concordant_JCI.csv
│   └── Discordant_JCI.csv
├── Direction_Analysis_Summary.csv
├── Concordance_Schwann.png/pdf
├── Concordance_JCI.png/pdf
├── Concordant_Discordant_Counts.png/pdf
└── Direction_Analysis.xlsx
```

**Expected insights**:
- More accurate cross-species validation
- Identification of compensatory mechanisms (discordant changes)
- Higher confidence therapeutic targets (concordant changes)

---

### Analysis #5: Leading Edge Gene Analysis
**File**: `251120_CompHuman-SpatialJCI/analysis_05_leading_edge_genes.R`

**What it does**:
- Identifies "hub genes" that appear in multiple enriched pathways
- Creates gene-pathway networks
- Identifies genes conserved across cell types and comparisons

**Key analyses**:
1. Hub gene identification (genes in ≥3 pathways)
2. Gene-pathway network visualization
3. Cross-cell-type hub gene consistency
4. Pathway centrality ranking

**Outputs**:
```
Output_JCI_Schwann_enrichment/Leading_Edge_Analysis/
├── All_Pathway_Gene_Associations.csv
├── Hub_Genes_All.csv
├── Hub_Genes_Top_3plus.csv
├── Hub_Genes_{celltype}.csv
├── Cross_CellType_Hub_Genes.csv
├── Top_Hub_Genes.png/pdf
├── Hub_Distribution_by_Comparison.png/pdf
├── {comparison}_{celltype}_Network.png/pdf
└── Leading_Edge_Analysis.xlsx
```

**Expected insights**:
- Key driver genes vs passenger genes
- Prioritized targets for validation/follow-up
- Interconnected pathway modules

---

## Running Order

**IMPORTANT**: Scripts must be run in this order:

1. **First**: `analysis_enrichment_JCI_Schwann_mouse.R` (generates enrichment data)
2. **Then**: Scripts 1-5 can be run in any order (they analyze the enrichment results)

## Estimated Run Times

With 24 cores on your 32-core machine:

| Script | Estimated Time |
|--------|---------------|
| Main enrichment | 10-25 minutes |
| Analysis #1 | 2-5 minutes |
| Analysis #2 | 1-3 minutes |
| Analysis #3 | 1-3 minutes |
| Analysis #4 | 3-5 minutes |
| Analysis #5 | 2-4 minutes |
| **Total** | **~20-45 minutes** |

## Current Status

❌ **R Installation Issue**: Your conda R has a LAPACK library problem. See `R_LAPACK_FIX.md` for solutions.

Once R is fixed, all scripts are ready to run!

## Files Created

### Documentation
- ✅ `CLAUDE.md` - Guide for future Claude Code instances
- ✅ `ANALYSIS_UPDATE_SUMMARY.md` - Detailed change log and analysis descriptions
- ✅ `R_LAPACK_FIX.md` - Instructions to fix R installation
- ✅ `SCRIPTS_SUMMARY.md` - This file

### Analysis Scripts
- ✅ `analysis_enrichment_JCI_Schwann_mouse.R` (updated with parallel processing and Venn diagrams)
- ✅ `analysis_01_celltype_enrichment_comparison.R`
- ✅ `analysis_02_intervention_response.R`
- ✅ `analysis_03_conservation_analysis.R`
- ✅ `analysis_04_direction_of_change.R`
- ✅ `analysis_05_leading_edge_genes.R`

## Next Steps

1. **Fix R installation** (see R_LAPACK_FIX.md)
2. **Test R**: `Rscript -e "print('R is working')"`
3. **Run main enrichment**: `cd 251120_CompHuman-SpatialJCI && Rscript analysis_enrichment_JCI_Schwann_mouse.R`
4. **Run additional analyses**: `Rscript analysis_01_*.R` through `analysis_05_*.R`
5. **Review outputs** in `Output_JCI_Schwann_enrichment/` subfolders

## Notes

- All scripts filter for Schwann cells only (change `schwann_cell_types` variable to modify)
- All scripts use parallel processing where applicable
- All scripts save both PNG (for viewing) and PDF (for publication)
- All scripts create Excel workbooks with organized tabs
- Manuscript filename found: `11-21-2025_DREX _MS edits_CLEAN.docx` (note: space in filename)
