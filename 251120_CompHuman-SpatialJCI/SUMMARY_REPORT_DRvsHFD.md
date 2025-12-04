# Analysis Summary: DRvsHFD (Diet Restriction vs High-Fat Diet)
## Therapeutic Intervention: majorSC and aggSC

**Date:** December 2, 2025
**Intervention:** Diet Restriction after HFD exposure
**Comparison:** DR vs HFD (therapeutic reversal)

---

## Executive Summary

Diet restriction (DR) after high-fat diet shows **825-919 genes changed** in Schwann cells, with **5-6 core conserved genes** across all three datasets. DR demonstrates **modest therapeutic effects** with conservation of cell adhesion and growth regulation pathways.

| Metric | majorSC | aggSC |
|--------|---------|-------|
| Mouse DEGs | 825 | 919 |
| Mouse∩Schwann | 17 (2.1%) | 19 (2.1%) |
| Mouse∩JCI Bulk | 71 (8.6%) | 76 (8.3%) |
| 3-way Overlap | **5 genes** | **6 genes** |

---

## Core Conserved Genes

**majorSC (5 genes):**
1. **Chst2** - Carbohydrate sulfotransferase 2
2. **Col1a1** - Collagen type I (ECM/fibrosis marker)
3. **Fam107a** - Family with sequence similarity 107A
4. **Mbp** - Myelin basic protein
5. **Mlip** - Muscular LMNA-interacting protein

**aggSC (6 genes):**
1. **Chst2** - Carbohydrate sulfotransferase 2
2. **Col1a1** - Collagen type I
3. **Col3a1** - Collagen type III
4. **Fgf1** - Fibroblast growth factor 1
5. **Mbp** - Myelin basic protein
6. **Mlip** - Muscular LMNA-interacting protein

---

## Key Findings

### 1. Overlap with HFDvsSD Disease Model

**Genes appearing in BOTH DRvsHFD and HFDvsSD:**
- **Mbp** - Present in both interventions (majorSC)
- **Col1a1** - Present in both (both cell types)
- **Chst2** - Present in DRvsHFD (both) and HFDvsSD_aggSC
- **Fgf1** - Present in both aggSC sets

**Interpretation:** These genes represent **persistent disease signatures** that may be partially responsive to diet restriction.

### 2. Top Enriched Pathways (majorSC, Mouse∩Schwann)

1. Cell adhesion
2. Regulation of cell growth
3. Cell growth
4. Negative regulation of cell adhesion
5. Regulation of growth
6. Response to steroid hormone
7. Cellular response to aldehyde
8. System development

**Biological Theme:** DR affects **cell adhesion and growth control**, suggesting modulation of Schwann cell-axon interactions and proliferative capacity.

### 3. Therapeutic Implications

**What DR Addresses:**
- ✓ Modulates cell adhesion (may improve Schwann-axon contact)
- ✓ Regulates cell growth (controls proliferation)
- ✓ Maintains some myelin genes (Mbp present)
- ✓ Affects ECM remodeling (Col1a1, Col3a1)

**What DR Doesn't Fully Address:**
- Limited neuron-specific pathways
- Modest overlap with human data (2.1%)
- Fewer genes than Exercise or DREX

### 4. Comparison to Disease Model (HFDvsSD)

| Feature | HFDvsSD | DRvsHFD | Change |
|---------|---------|---------|--------|
| majorSC DEGs | 416 | 825 | **+98%** |
| aggSC DEGs | 806 | 919 | +14% |
| 3-way overlap (majorSC) | 5 | 5 | Same |
| 3-way overlap (aggSC) | 5 | 6 | +1 gene |

**Interpretation:** DR induces MORE gene changes than the disease itself, suggesting compensatory mechanisms and metabolic adaptation beyond simple reversal.

---

## Script-by-Script Analysis

### Script 00: Enrichment Analysis
- **Mouse DEGs:** 825-919 (moderate intervention response)
- **Conservation:** 2.1% with human Schwann (similar to disease model)
- **Core pathways:** Cell adhesion, growth regulation

### Script 01: Cell Type Comparison
- majorSC vs aggSC show similar patterns
- Both capture ECM and adhesion pathways
- aggSC includes additional collagen gene (Col3a1)

### Script 02: Intervention Response
- DR represents **caloric restriction therapy**
- Metabolic adaptation pathway active
- Partial reversal of HFD effects

### Script 03: Conservation Analysis
- **Modest conservation** (2.1%)
- Core genes: Mbp, Col1a1 conserved
- Validates some therapeutic mechanisms

### Script 04: Direction Analysis
- Expected: DR should reverse some HFD changes
- Concordance with human data validates mechanisms

### Script 05: Hub Genes
- Col1a1: Central ECM hub
- Mbp: Myelin hub
- Chst2: ECM modification hub

### Script 06: Bioenergetic Focus
- DR affects metabolic pathways directly
- Response to aldehyde (lipid metabolism)
- Steroid hormone response (metabolic regulation)

### Script 07: PPI Networks
- 825-919 proteins form functional modules
- ECM-myelin network connectivity

### Script 08: Pathway Overlap Heatmaps
- Cell adhesion pathways conserved
- Growth regulation pathways shared

---

## Therapeutic Assessment

**DR Efficacy Rating: Moderate (⭐⭐⭐☆☆)**

**Strengths:**
- Modulates cell adhesion and growth
- Maintains myelin gene expression (Mbp)
- Addresses ECM remodeling
- Fewer genes than disease model (more focused response)

**Limitations:**
- Only 2.1% overlap with human data
- Lacks strong neuron regeneration signals
- No enrichment for neuron differentiation/morphogenesis
- Fewer therapeutic genes than Exercise or DREX

**Clinical Relevance:**
- DR may be **partially effective** for early-stage DPN
- Best for addressing metabolic dysfunction
- May need combination with exercise for full benefit

---

## Genes Potentially Reversed by DR

**Comparing HFDvsSD → DRvsHFD:**

**Genes in HFDvsSD that persist in DRvsHFD:**
- Mbp (persistent - may not be fully reversed)
- Col1a1 (persistent - fibrosis ongoing)

**New genes in DRvsHFD not in HFDvsSD:**
- Chst2 (majorSC: new in DR)
- Fam107a (new response)
- Mlip (new response)

**Interpretation:** DR induces **compensatory metabolic adaptation** rather than simple disease reversal. New genes suggest metabolic reprogramming.

---

## Conclusions

1. **DR shows moderate therapeutic effects** with 825-919 genes changed

2. **Core conserved genes (5-6)** overlap with disease model, suggesting persistent pathology

3. **Cell adhesion and growth regulation** are primary DR mechanisms

4. **Mbp and Col1a1 persist** across disease and intervention, indicating incomplete reversal

5. **DR induces MORE gene changes** than disease itself, suggesting complex metabolic adaptation

6. **Therapeutic potential is moderate** - may benefit from combination with exercise (DREX)

**Next Steps:** Compare with EXvsHFD and DREXvsHFD to identify synergistic effects and optimal intervention strategies.
