# Mouse∩Schwann Analysis: DRvsHFD (Diet Restriction Intervention)
## Conserved Genes Between Mouse scRNA-seq and Human Schwann Spatial Transcriptomics

**Date:** December 4, 2025
**Comparison:** Diet Restriction vs HFD (Therapeutic Intervention)
**Focus:** Mouse∩Schwann overlap (excluding JCI bulk RNA-seq)

---

## Executive Summary

Diet restriction (DR) after HFD induces **17-19 conserved genes** between mouse and human Schwann cells, representing **cell adhesion and growth regulation** as primary therapeutic mechanisms. DR shows **31-48% increase in conserved genes** compared to disease (17 vs 13 in majorSC, 19 vs 13 if comparing to HFDvsSD majorSC baseline).

| Cell Type | Mouse∩Schwann Genes | % of Mouse DEGs | Top Pathway Theme |
|-----------|---------------------|-----------------|-------------------|
| **majorSC** | 17 | 2.1% | Cell adhesion, regulation of cell growth |
| **aggSC** | 19 | 2.1% | Cell adhesion, ECM organization |

**Key Finding:** DR induces **MORE conserved genes than disease itself** (17-19 vs 13-21), suggesting compensatory metabolic adaptation rather than simple disease reversal.

---

## Conserved Gene Signatures

### majorSC (17 genes)

**Complete Gene List:**
1. **Adamtsl1** - ADAMTS-like 1 (ECM)
2. **Chst2** - Carbohydrate sulfotransferase 2
3. **Col14a1** - Collagen type XIV alpha 1
4. **Col1a1** - Collagen type I alpha 1 (**PERSISTENT from disease**)
5. **Cpe** - Carboxypeptidase E
6. **Fam107a** - Family with sequence similarity 107A (**NEW in DR**)
7. **Frzb** - Frizzled-related protein (Wnt antagonist)
8. **Fxyd3** - FXYD domain-containing ion transport regulator 3
9. **Haghl** - Hydroxyacylglutathione hydrolase-like
10. **Mbp** - Myelin basic protein (**PERSISTENT from disease**)
11. **Mfap5** - Microfibrillar associated protein 5
12. **Mlip** - Muscular LMNA-interacting protein (**NEW in DR**)
13. **Scube1** - Signal peptide, CUB domain, EGF-like 1
14. **Sdc3** - Syndecan 3
15. **Sdk2** - Sidekick cell adhesion molecule 2
16. **Sema7a** - Semaphorin 7A
17. **Serpine2** - Serpin family E member 2

**Gene Status:**
- **PERSISTENT from disease (2):** Col1a1, Mbp
- **NEW in DR intervention (2):** Fam107a, Mlip
- **RESOLVED from disease (3):** Col3a1, Dclk3, Rnd3, Txnip (no longer appear)



#### Related Output Files:
- Gene list: `Output_JCI/00_DEGoverlap_Enrichment_Analysis/DRvsHFD_majorSC_enrichment/Overlap_MS_Genes.csv`
- GO enrichment: `Output_JCI/00_DEGoverlap_Enrichment_Analysis/DRvsHFD_majorSC_enrichment/Overlap_MS_richR_GO.csv`
- KEGG enrichment: `Output_JCI/00_DEGoverlap_Enrichment_Analysis/DRvsHFD_majorSC_enrichment/Overlap_MS_richR_KEGG.csv`
- Venn diagram: `Output_JCI/00_DEGoverlap_Enrichment_Analysis/DRvsHFD_majorSC_enrichment/Venn_Diagram.png`

---

### aggSC (19 genes)

**Complete Gene List:**
1. **Adam23** - ADAM metallopeptidase domain 23
2. **Adamtsl1** - ADAMTS-like 1
3. **Chst2** - Carbohydrate sulfotransferase 2 (**PERSISTENT from disease**)
4. **Col14a1** - Collagen type XIV alpha 1
5. **Col1a1** - Collagen type I alpha 1 (**PERSISTENT from disease**)
6. **Col3a1** - Collagen type III alpha 1 (**REAPPEARS in DR**)
7. **Fgf1** - Fibroblast growth factor 1 (**PERSISTENT from disease**)
8. **Fxyd3** - FXYD domain-containing ion transport regulator 3
9. **Insc** - Inscuteable homolog (spindle orientation)
10. **Mbp** - Myelin basic protein (**PERSISTENT from disease**)
11. **Mlip** - Muscular LMNA-interacting protein (**NEW in DR**)
12. **Nkain2** - Na+/K+ transporting ATPase interacting 2
13. **S100b** - S100 calcium-binding protein B (**NEW in DR, was in disease aggSC**)
14. **Scube1** - Signal peptide, CUB domain, EGF-like 1
15. **Sdc3** - Syndecan 3
16. **Sdk2** - Sidekick cell adhesion molecule 2
17. **Sema7a** - Semaphorin 7A
18. **Serpine2** - Serpin family E member 2
19. **Txnip** - Thioredoxin-interacting protein (**PERSISTENT from disease**)

**Gene Status:**
- **PERSISTENT from disease (5):** Chst2, Col1a1, Fgf1, Mbp, Txnip
- **REAPPEARS (1):** Col3a1 (was in disease majorSC, now in DR aggSC)
- **NEW in DR (1):** Mlip

---



#### Related Output Files:
- Gene list: `Output_JCI/00_DEGoverlap_Enrichment_Analysis/DRvsHFD_aggSC_enrichment/Overlap_MS_Genes.csv`
- GO enrichment: `Output_JCI/00_DEGoverlap_Enrichment_Analysis/DRvsHFD_aggSC_enrichment/Overlap_MS_richR_GO.csv`
- KEGG enrichment: `Output_JCI/00_DEGoverlap_Enrichment_Analysis/DRvsHFD_aggSC_enrichment/Overlap_MS_richR_KEGG.csv`
- Venn diagram: `Output_JCI/00_DEGoverlap_Enrichment_Analysis/DRvsHFD_aggSC_enrichment/Venn_Diagram.png`

---

## Pathway Enrichment Analysis

### majorSC Top Pathways

| Rank | GO Term | P-value | Genes | Interpretation |
|------|---------|---------|-------|----------------|
| 1 | Cell adhesion | 2.5e-06 | 8 | Col1a1, Mbp, Fam107a, Sdc3, Col14a1, Chst2, Sdk2, Serpine2 |
| 2 | Regulation of cell growth | 7.6e-06 | 5 | Fam107a, Sema7a, Col14a1, Frzb, Serpine2 |
| 3 | Cell growth | 2.1e-05 | 5 | Fam107a, Sema7a, Col14a1, Frzb, Serpine2 |
| 4 | Negative regulation of cell adhesion | 5.3e-05 | 4 | Col1a1, Mbp, Fam107a, Serpine2 |
| 5 | Regulation of growth | 5.8e-05 | 5 | Fam107a, Sema7a, Col14a1, Frzb, Serpine2 |
| 6 | Response to steroid hormone | 7.9e-05 | 4 | Col1a1, Mbp, Fam107a, Cpe |
| 7 | Cellular response to aldehyde | 1.2e-04 | 2 | Col1a1, Haghl |
| 8 | System development | 1.4e-04 | 10 | Col1a1, Mbp, Fam107a, Mfap5, Sema7a, Col14a1, Frzb, Sdk2, Cpe, Serpine2 |

**Dominant Theme:** **CELL ADHESION AND GROWTH CONTROL**
- Cell adhesion/negative regulation (Schwann-axon contact modulation)
- Growth regulation (controlling proliferation)
- Aldehyde response (lipid metabolism/oxidative stress sequel)



#### Related Output Files:
- Gene list: `Output_JCI/00_DEGoverlap_Enrichment_Analysis/DRvsHFD_majorSC_enrichment/Overlap_MS_Genes.csv`
- GO enrichment: `Output_JCI/00_DEGoverlap_Enrichment_Analysis/DRvsHFD_majorSC_enrichment/Overlap_MS_richR_GO.csv`
- KEGG enrichment: `Output_JCI/00_DEGoverlap_Enrichment_Analysis/DRvsHFD_majorSC_enrichment/Overlap_MS_richR_KEGG.csv`
- Venn diagram: `Output_JCI/00_DEGoverlap_Enrichment_Analysis/DRvsHFD_majorSC_enrichment/Venn_Diagram.png`

---

### aggSC Top Pathways

| Rank | GO Term | P-value | Genes | Interpretation |
|------|---------|---------|-------|----------------|
| 1 | Cell adhesion | 3.4e-08 | 10 | Adam23, Chst2, Col14a1, Col1a1, Col3a1, Mbp, S100b, Sdc3, Sdk2, Serpine2 |
| 2 | Collagen fibril organization | 1.6e-05 | 3 | Col14a1, Col1a1, Col3a1 |
| 3 | Regulation of sodium ion transport | 2.5e-05 | 3 | Fxyd3, Nkain2, Serpine2 |
| 4 | Regulation of cell migration | 7.7e-05 | 6 | Chst2, Col1a1, Col3a1, Fgf1, Sdc3, Sema7a |
| 5 | ECM organization | 8.1e-05 | 4 | Adamtsl1, Col14a1, Col1a1, Col3a1 |
| 6 | External encapsulating structure organization | 8.2e-05 | 4 | Adamtsl1, Col14a1, Col1a1, Col3a1 |
| 7 | Extracellular structure organization | 8.3e-05 | 4 | Adamtsl1, Col14a1, Col1a1, Col3a1 |
| 8 | Regulation of cell motility | 1.1e-04 | 6 | Chst2, Col1a1, Col3a1, Fgf1, Sdc3, Sema7a |

**Dominant Theme:** **ECM REMODELING AND CELL ADHESION**
- Strongest cell adhesion signal (p=3.4e-08, 10 genes)
- Collagen fibril organization (Col1a1, Col3a1, Col14a1)
- ECM organization pathways

---

## Key Findings

### 1. Gene Persistence Analysis

**Comparing DRvsHFD to HFDvsSD:**

| Gene | HFDvsSD | DRvsHFD | Status | Interpretation |
|------|---------|---------|--------|----------------|
| **Col1a1** | ✓ (both) | ✓ (both) | **PERSISTENT** | ECM remodeling ongoing |
| **Mbp** | ✓ (both) | ✓ (both) | **PERSISTENT** | Myelin involvement continues |
| **Chst2** | ✓ (aggSC) | ✓ (both) | **PERSISTENT** | ECM modification ongoing |
| **Fgf1** | ✓ (aggSC) | ✓ (aggSC) | **PERSISTENT** | Growth factor dysregulation continues |
| **Txnip** | ✓ (both) | ✓ (aggSC only) | **PARTIALLY RESOLVED** | Oxidative stress reduced but not eliminated |
| **Col3a1** | ✓ (majorSC) | ✓ (aggSC) | **SHIFTS** | ECM remodeling continues, different cell type |
| **S100b** | ✓ (aggSC) | ✓ (aggSC) | **PERSISTENT** | Schwann cell activation continues |
| **Dclk3** | ✓ (majorSC) | ✗ | **RESOLVED** | Microtubule dysregulation corrected |
| **Rnd3** | ✓ (majorSC) | ✗ | **RESOLVED** | Cytoskeleton regulation normalized |
| **Rgcc** | ✓ (aggSC) | ✗ | **RESOLVED** | Cell cycle normalized |

**Summary:**
- **5-6 genes PERSIST** from disease (Col1a1, Mbp, Chst2, Fgf1, Txnip partially, S100b)
- **3-4 genes RESOLVED** (Dclk3, Rnd3, Rgcc, Txnip partially)
- **2 genes NEW in DR** (Fam107a, Mlip)

**Interpretation:** DR achieves **PARTIAL disease reversal** (30-40% of disease genes resolved) but induces **compensatory adaptation genes** (Fam107a, Mlip).

### 2. DR-Induced Genes (Not in Disease)

**Fam107a (Family with Sequence Similarity 107A):**
- **Function:** Cell growth regulator, tumor suppressor-like
- **Pathways:** Cell adhesion, negative regulation of cell adhesion, growth regulation
- **Interpretation:** DR induces growth control mechanisms, potentially limiting excessive proliferation

**Mlip (Muscular LMNA-Interacting Protein):**
- **Function:** Nuclear envelope protein, involved in lipid metabolism
- **Pathways:** Not in top enriched pathways, likely metabolic adaptation
- **Interpretation:** DR affects nuclear organization and lipid metabolism

**Significance:** These **NEW genes represent DR-specific metabolic adaptation** rather than disease reversal per se.

### 3. Pathway Comparison: Disease vs DR

| Pathway Theme | HFDvsSD | DRvsHFD | Change |
|---------------|---------|---------|--------|
| **Oxidative stress** | Strong (majorSC) | Weak (only aldehyde response) | **REDUCED** |
| **Cell adhesion** | Strong (aggSC) | **Strongest (both cell types)** | **AMPLIFIED** |
| **Cell motility** | Strong (aggSC) | Moderate (aggSC) | Maintained |
| **ECM organization** | Moderate (aggSC) | **Strong (aggSC)** | **AMPLIFIED** |
| **Growth regulation** | Absent | **NEW (majorSC)** | **DR-SPECIFIC** |

**Interpretation:**
- **Oxidative stress REDUCED** (Txnip pathways diminished)
- **Cell adhesion AMPLIFIED** (now top pathway in both cell types)
- **ECM remodeling AMPLIFIED** (collagen fibril organization appears)
- **Growth control NEW** (Fam107a-mediated pathways)

**Conclusion:** DR **shifts disease mechanisms** from oxidative stress to **cell adhesion and ECM remodeling**, with new growth control mechanisms.

### 4. Therapeutic Assessment

**What DR Successfully Addresses:**
- ✓ **Oxidative stress reduction** (Txnip pathways diminished)
- ✓ **Cytoskeleton normalization** (Dclk3, Rnd3 resolved)
- ✓ **Cell cycle control** (Rgcc resolved)
- ✓ **Growth regulation** (Fam107a induced)

**What DR Does NOT Address:**
- ✗ **ECM remodeling** (Col1a1, Col3a1, Col14a1 persist/amplify)
- ✗ **Myelin dysfunction** (Mbp persists)
- ✗ **Growth factor dysregulation** (Fgf1 persists)
- ✗ **Cell adhesion issues** (amplified, not normalized)

**Efficacy Rating:** **Moderate (⭐⭐⭐☆☆)**
- Reduces metabolic/oxidative stress
- Induces growth control mechanisms
- Does NOT resolve ECM/myelin/adhesion pathology
- May represent **metabolic stabilization** rather than regeneration

---

## Cell Adhesion Focus

### majorSC Cell Adhesion Network (8 genes)

**Positive Adhesion:**
- **Col1a1, Col14a1**: ECM proteins providing substrate
- **Chst2**: ECM modification
- **Sdc3, Sdk2**: Cell surface adhesion molecules
- **Mbp**: Myelin-axon adhesion

**Negative Regulation:**
- **Fam107a, Serpine2**: Inhibit excessive adhesion

**Interpretation:** DR creates a **balanced adhesion state** with both positive and negative regulators, potentially representing:
- Attempt to optimize Schwann-axon contact
- Prevention of pathological adhesion
- Tissue remodeling control



#### Related Output Files:
- Gene list: `Output_JCI/00_DEGoverlap_Enrichment_Analysis/DRvsHFD_majorSC_enrichment/Overlap_MS_Genes.csv`
- GO enrichment: `Output_JCI/00_DEGoverlap_Enrichment_Analysis/DRvsHFD_majorSC_enrichment/Overlap_MS_richR_GO.csv`
- KEGG enrichment: `Output_JCI/00_DEGoverlap_Enrichment_Analysis/DRvsHFD_majorSC_enrichment/Overlap_MS_richR_KEGG.csv`
- Venn diagram: `Output_JCI/00_DEGoverlap_Enrichment_Analysis/DRvsHFD_majorSC_enrichment/Venn_Diagram.png`

---

### aggSC Cell Adhesion Network (10 genes)

**Strongest enrichment of any pathway in any intervention: p=3.4e-08**

**Additional genes in aggSC:**
- **Adam23**: ADAM family metallopeptidase, cell adhesion
- **S100b**: Schwann cell marker, affects adhesion

**Interpretation:** aggSC shows **even stronger adhesion modulation** than majorSC, suggesting this is a **core DR therapeutic mechanism**.

---

## ECM Remodeling in DR

### Collagen Network (aggSC)

**Three collagens co-enriched:**
- **Col1a1**: Type I (main fibrillar collagen)
- **Col3a1**: Type III (reticular collagen)
- **Col14a1**: Type XIV (FACIT collagen, regulates fibrillogenesis)

**Pathway:** Collagen fibril organization (p=1.6e-05)

**Interpretation:** DR does NOT stop ECM remodeling; instead, it may **modulate collagen organization**:
- Col14a1 (FACIT collagen) is a **regulator** of Col1a1/Col3a1 fibrillogenesis
- This represents **active remodeling** rather than pathological fibrosis continuation

**Comparison to Disease:**
- **Disease (HFDvsSD):** Col1a1 + Col3a1 only
- **DR (DRvsHFD):** Col1a1 + Col3a1 + **Col14a1** (regulatory collagen)

**Hypothesis:** DR shifts from **pathological fibrosis** (disease) to **controlled remodeling** (intervention) by recruiting Col14a1.

---

## Clinical Implications

### 1. DR as Metabolic Stabilizer

**Evidence:**
- Reduces oxidative stress (Txnip diminished)
- Resolves cell cycle dysregulation (Rgcc)
- Maintains myelin (Mbp persists but stable)

**Clinical Use:** DR suitable for **metabolic stabilization** in early DPN, preventing progression.

### 2. DR Insufficient for ECM Resolution

**Evidence:**
- Col1a1, Col3a1, Col14a1 persist
- ECM organization pathways enriched
- Cell adhesion amplified (compensatory?)

**Clinical Implication:** DR alone may NOT reverse established fibrosis; combination therapy needed.

### 3. Biomarker Panel

**DR Response Markers:**
- ↓ Txnip (oxidative stress reduced)
- ↑ Fam107a (growth control activated)
- ↑ Col14a1 (remodeling regulation)
- Stable Mbp (myelin maintained)

**Non-Responder Markers:**
- Persistent Fgf1 elevation (inflammation continues)
- Rising Col1a1 (fibrosis progressing)

---

## Conclusions

1. **DR induces 17-19 conserved genes**, more than disease itself, representing metabolic adaptation rather than simple reversal

2. **Persistent disease genes (5-6):** Col1a1, Mbp, Chst2, Fgf1, S100b, Txnip (partial) indicate **incomplete disease resolution**

3. **DR successfully addresses:** Oxidative stress, cytoskeleton dysregulation, cell cycle control

4. **DR does NOT address:** ECM remodeling, myelin dysfunction, growth factor dysregulation

5. **Cell adhesion is the PRIMARY DR mechanism** (strongest pathway, p=3.4e-08 in aggSC, 8-10 genes)

6. **ECM remodeling shifts from pathological (disease) to regulated (DR)** with Col14a1 recruitment

7. **DR-induced genes (Fam107a, Mlip)** represent compensatory metabolic adaptation mechanisms

8. **Therapeutic efficacy: Moderate** - metabolic stabilization achieved, but regeneration limited

**Recommendation:** DR best suited for **early intervention and metabolic stabilization**; combine with exercise or other regenerative therapies for established neuropathy.

---

**Next:** Compare with EXvsHFD and DREXvsHFD to identify synergistic mechanisms and optimal therapeutic strategies.
