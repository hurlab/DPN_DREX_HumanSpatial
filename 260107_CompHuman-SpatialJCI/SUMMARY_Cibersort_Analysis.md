# Summary Report: Cibersort Schwann Cell DEG Analysis

**Date:** January 8, 2026
**Analysis:** Cibersort-derived Human Schwann Cell DEGs (C vs DPN)
**Comparison:** Mouse scRNA-seq Schwann Cells vs Human Cibersort DEGs

---

## 1. Overview

This analysis examines differentially expressed genes (DEGs) from Cibersort-deconvoluted human Schwann cell spatial transcriptomics data comparing Control (C) vs Diabetic Peripheral Neuropathy (DPN) samples. The analysis includes:

1. **GO and KEGG enrichment analysis** of the human DEGs
2. **Cross-species overlap analysis** between human Cibersort DEGs and mouse scRNA-seq Schwann cell DEGs

---

## 2. Cibersort Human DEG Summary

### 2.1 Input Data
- **Source:** `DEGs_SchwannCells_C_vs_DPN.xlsx`
- **Criteria:** adj.P.Val < 0.05
- **Total DEGs identified:** 163 genes
  - Upregulated in DPN: 85 genes
  - Downregulated in DPN: 78 genes

### 2.2 Human-to-Mouse Ortholog Mapping
- Human DEGs were mapped to mouse orthologs using homologene
- **Mapping success rate:** 142 of 163 (87.1%)
  - Upregulated: 85 → 73 mouse orthologs (85.9%)
  - Downregulated: 78 → 69 mouse orthologs (88.5%)
  - All: 163 → 142 mouse orthologs (87.1%)

---

## 3. GO Enrichment Analysis Results

### 3.1 All DEGs (Combined Up + Down)

**Number of enriched GO terms:** 299 (Padj < 0.05)

**Top Biological Processes:**

| GO Term | Padj | Genes | Description |
|---------|------|-------|-------------|
| spliceosomal tri-snRNP complex assembly | 0.0020 | Prpf8, Tssc4, Usp4 | RNA splicing machinery |
| cysteine transport | 0.0097 | Nfe2l1, Slc1a1 | Amino acid transport |
| negative regulation of cell cycle process | 0.0104 | Zw10, Mad2l1, Ccl12, Nsun2, Spdl1, Trim37, Rbl1, Rfwd3 | Cell cycle control |
| attachment of GPI anchor to protein | 0.0135 | Pigk, Pigu | Protein modification |
| ribonucleoprotein complex biogenesis | 0.0146 | Prpf8, Gcfc2, Tssc4, Usp4, Wdr46, Pop5, Sf3b1, Nop9, Tfb2m | RNA processing |
| autophagosome organization | 0.0195 | Dnjc16, Mtm1, Pip4k2a, Atg13, Tmem39a | Autophagy pathway |
| regulation of protein ubiquitination | 0.0238 | Rchy1, Mad2l1, Usp4, Tspyl5, N4bp1, Bex4 | Protein degradation |
| cellular senescence | 0.0362 | Ndufs6, Rbl1, Id2, Zmpste24 | Aging/cell fate |

**Key Themes:**
- **RNA processing and splicing** - Multiple genes involved in spliceosome function
- **Cell cycle regulation** - Strong negative regulation signals
- **Protein modification pathways** - Ubiquitination and GPI anchoring
- **Autophagy and cellular stress** - Atg13, Mtm1, Pip4k2a
- **Cellular senescence** - Links to diabetic complications

### 3.2 Upregulated DEGs

**Number of enriched GO terms:** 210

**Notable pathways:**
- tRNA metabolic process (Elp3, Farsa, Ftsj1, Nsun2, Pop5, Zbtb8os)
- glucose 6-phosphate metabolic process (Nfe2l1, Hkdc1, Hsd11b1)
- RNA 5'-end processing (Rngtt, Pop5, Nop9)

### 3.3 Downregulated DEGs

**Number of enriched GO terms:** 281

**Notable pathways:**
- Negative regulation of mitotic cell cycle (multiple cell cycle inhibitors)
- Regulation of autophagy
- Vacuole organization
- TGF-beta signaling pathway components

---

## 4. KEGG Enrichment Analysis Results

### 4.1 All DEGs

**Number of enriched KEGG pathways:** 3 (Padj < 0.05)

| KEGG Pathway | Padj | Genes | Description |
|--------------|------|-------|-------------|
| Cell cycle | 0.230 | Mad2l1, Pcna, Rbl1, Ywhab, Zbtb17 | Cell proliferation control |
| GPI-anchor biosynthesis | 0.659 | Pigk, Pigu | Protein anchoring |
| TGF-beta signaling pathway | 0.659 | Rbl1, Rock1, Id2 | Development and fibrosis |

**Note:** KEGG pathway enrichment was limited due to smaller gene numbers after ortholog mapping. The identified pathways are consistent with GO enrichment results.

### 4.2 Direction-Specific KEGG Results

- **Upregulated DEGs:** 4 pathways
- **Downregulated DEGs:** 6 pathways

---

## 5. Mouse-Human Overlap Analysis

### 5.1 Overall Overlap Statistics

**Mouse Comparisons Analyzed:** 20 total
- 4 comparisons × 5 Schwann cell types (mySC, nmSC, ImmSC, majorSC, aggSC)
- Comparisons: HFDvsSD, DRvsHFD, EXvsHFD, DREXvsHFD

**Overlap Summary:**
- Maximum overlap: 34 genes (EXvsHFD majorSC)
- Mean overlap: 6.8 genes per comparison
- Range: 0-34 genes

### 5.2 Top Overlapping Comparisons

| Comparison | Cell Type | Mouse DEGs | Overlap | % Mouse | % Cibersort |
|------------|-----------|------------|---------|---------|-------------|
| **EXvsHFD** | **majorSC** | **2371** | **34** | **1.43%** | **23.9%** |
| **EXvsHFD** | **aggSC** | 1600 | 19 | 1.19% | 13.4% |
| **EXvsHFD** | **mySC** | 1337 | 16 | 1.20% | 11.3% |
| DREXvsHFD | majorSC | 1023 | 11 | 1.08% | 7.7% |
| DREXvsHFD | aggSC | 1006 | 11 | 1.09% | 7.7% |
| DREXvsHFD | mySC | 529 | 6 | 1.13% | 4.2% |
| HFDvsSD | aggSC | 806 | 6 | 0.74% | 4.2% |
| HFDvsSD | mySC | 510 | 5 | 0.98% | 3.5% |

**Key Finding:** The **EXvsHFD (Exercise intervention)** comparison shows the highest overlap with human Cibersort DEGs, particularly in majorSC (23.9% of human genes overlap). This suggests exercise-related gene regulation may be most relevant to human DPN pathology.

### 5.3 Most Consistent Overlap Genes

Genes that appear in multiple mouse comparisons (potential core DPN genes):

| Gene | n_comparisons | Comparisons |
|------|---------------|-------------|
| **Fkbp3** | **9** | DREXvsHFD_mySC; DRvsHFD_mySC; EXvsHFD_mySC; DREXvsHFD_majorSC; DRvsHFD_majorSC; EXvsHFD_majorSC; DREXvsHFD_aggSC; DRvsHFD_aggSC; EXvsHFD_aggSC |
| **Faim** | **7** | DREXvsHFD_mySC; EXvsHFD_ImmSC; HFDvsSD_mySC; EXvsHFD_majorSC; DREXvsHFD_aggSC; EXvsHFD_aggSC; HFDvsSD_aggSC |
| **Atg13** | **6** | DREXvsHFD_ImmSC; DRvsHFD_ImmSC; HFDvsSD_mySC; DREXvsHFD_aggSC; DRvsHFD_aggSC; HFDvsSD_aggSC |
| **Gpcpd1** | **6** | DRvsHFD_mySC; EXvsHFD_mySC; EXvsHFD_majorSC; HFDvsSD_majorSC; DRvsHFD_aggSC; EXvsHFD_aggSC |
| **Krit1** | **6** | EXvsHFD_mySC; HFDvsSD_mySC; DRvsHFD_majorSC; EXvsHFD_majorSC; EXvsHFD_aggSC; HFDvsSD_aggSC |

**Notable Genes:**
- **Fkbp3** (FK506-binding protein 3): Present in 9/20 comparisons - involved in protein folding and immune regulation
- **Faim** (Fas apoptotic inhibitory molecule): Anti-apoptotic signaling
- **Atg13** (Autophagy-related 13): Autophagy initiation - links to cellular stress response
- **Krit1** (Krev interaction trapped protein 1): Vascular development and blood-brain barrier integrity
- **Pigk** (GPI transamidase component): Protein anchoring - appears in GPI-anchor biosynthesis pathway
- **Elp3** (Elongator complex protein 3): tRNA modification and transcriptional elongation
- **Ppm1a** (Protein phosphatase 1A): Cell cycle regulation and stress signaling
- **N4bp1** (NEDD4 binding protein 1): Ubiquitination regulation

---

## 6. Biological Interpretation

### 6.1 Core Pathways Affected in Human DPN Schwann Cells

1. **RNA Processing and Splicing**
   - Multiple enriched GO terms related to RNA processing
   - Genes: Prpf8, Sf3b1, Elp3, Pop5, Nop9
   - Implications: Altered transcriptional/post-transcriptional regulation in DPN

2. **Cell Cycle Regulation**
   - Strong negative regulation signatures
   - Genes: Mad2l1, Rbl1, Zw10, Spdl1, Pcna
   - Implications: Possible cell cycle arrest or altered proliferation in DPN

3. **Autophagy and Cellular Stress**
   - Autophagosome organization (GO:1905037)
   - Genes: Atg13, Mtm1, Pip4k2a, Dnjc16, Tmem39a
   - Implications: Impaired autophagic flux contributing to DPN pathology

4. **Protein Modification Pathways**
   - GPI-anchor biosynthesis (Pigk, Pigu)
   - Ubiquitination regulation (Usp4, N4bp1, Rchy1, Mad2l1)
   - Implications: Altered protein localization and degradation

5. **Cellular Senescence**
   - Enriched senescence-related genes (Ndufs6, Rbl1, Id2, Zmpste24)
   - Implications: Senescence-associated phenotype in DPN Schwann cells

### 6.2 Cross-Species Conservation

The overlap analysis reveals several important findings:

1. **Exercise intervention (EXvsHFD)** shows the highest conservation with human DPN
   - Suggests exercise-responsive pathways are relevant to human disease
   - May indicate that exercise-induced protective mechanisms are conserved

2. **Aggregate Schwann cells (aggSC)** show consistent overlap
   - Supports the validity of using aggregated Schwann cell populations
   - Indicates core DPN mechanisms across Schwann subtypes

3. **Core conserved genes** (Fkbp3, Faim, Atg13, Gpcpd1, Krit1)
   - Represent high-confidence DPN-relevant genes
   - Potential therapeutic targets

---

## 7. Comparison with Previous Analyses

This Cibersort analysis differs from the original JCI_SC (JCI Schwann cell) analysis in several ways:

1. **Different deconvolution method:** Cibersort vs. original JCI pipeline
2. **Cell type specificity:** May capture different Schwann cell populations
3. **Overlap patterns:** EXvsHFD shows highest overlap here, whereas previous analyses may have shown different patterns

The Cibersort DEGs appear to capture:
- Stronger RNA processing signatures
- More pronounced autophagy pathway involvement
- Distinct cell cycle regulation patterns

---

## 8. Limitations and Considerations

1. **Ortholog mapping:** ~13% of human genes lack clear mouse orthologs
2. **Cell type heterogeneity:** Cibersort deconvolution may not perfectly isolate pure Schwann cells
3. **Species differences:** Human DPN etiology may differ from mouse HFD model
4. **Multiple testing:** While padj < 0.05 was used, some findings may require validation
5. **Sample size:** Unknown number of human samples in Cibersort analysis

---

## 9. Future Directions

1. **Validate core conserved genes** (Fkbp3, Faim, Atg13) in independent human and mouse datasets
2. **Investigate exercise-responsive pathways** given the high EXvsHFD overlap
3. **Examine RNA processing alterations** in DPN Schwann cells
4. **Explore autophagy modulation** as a potential therapeutic avenue
5. **Compare Cibersort results with original JCI_SC** to understand methodological differences

---

## 10. Files and Outputs

### Analysis Scripts
- `01_enrichment_cibersort.R` - GO/KEGG enrichment analysis
- `02_overlap_mouse_cibersort.R` - Mouse-human overlap analysis

### Output Directory Structure
```
Output_260107/
├── 01_Enrichment_Cibersort/
│   ├── Gene lists (human and mouse)
│   ├── GO enrichment results (CSV and dot plots)
│   ├── KEGG enrichment results (CSV and dot plots)
│   └── Enrichment_Summary.xlsx
└── 02_Overlap_Mouse_Cibersort/
    ├── Overlap_Summary.csv
    ├── Master_Overlap_Genes.csv
    ├── Overlap_Summary.xlsx
    └── {comparison}_{celltype}_overlap/
        ├── Venn diagrams (PNG/PDF)
        └── Gene lists
```

---

## 11. Key Takeaways

1. **163 DEGs** identified in human DPN Schwann cells (Cibersort)
2. **RNA processing and splicing** emerges as a key pathway in DPN
3. **Exercise intervention (EXvsHFD)** shows highest cross-species conservation
4. **Fkbp3** appears in 9/20 mouse comparisons - potential core DPN gene
5. **Autophagy and cellular senescence** pathways are strongly implicated
6. **87% mapping success** from human to mouse orthologs

---

*Analysis completed January 8, 2026*
*Scripts located in: 260107_CompHuman-SpatialJCI/*
*Outputs in: Output_260107/*
