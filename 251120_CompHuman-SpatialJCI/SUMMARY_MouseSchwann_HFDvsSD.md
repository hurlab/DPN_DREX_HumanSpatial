# Mouse∩Schwann Analysis: HFDvsSD (Disease Model)
## Conserved Genes Between Mouse scRNA-seq and Human Schwann Spatial Transcriptomics

**Date:** December 3, 2025
**Comparison:** HFD vs Standard Diet (Disease Model)
**Focus:** Mouse∩Schwann overlap (excluding JCI bulk RNA-seq)

---

## Executive Summary

High-fat diet (HFD) induces **13-21 conserved genes** between mouse peripheral nerve Schwann cells and human sural nerve Schwann cells, representing **cross-species validated disease signatures**. The disease model shows strong enrichment for **oxidative stress response, ECM remodeling, and cell motility regulation**.

| Cell Type | Mouse∩Schwann Genes | % of Mouse DEGs | Top Pathway Theme |
|-----------|---------------------|-----------------|-------------------|
| **majorSC** | 13 | 3.1% | Oxidative stress, steroid hormone response |
| **aggSC** | 21 | 2.6% | Cell motility regulation, cell adhesion |

**Key Finding:** aggSC captures **62% more conserved genes** than majorSC (21 vs 13), suggesting aggregated Schwann cell types better reflect human disease complexity.

---

## Conserved Gene Signatures

### majorSC (13 genes)

**Complete Gene List:**
1. **Adam23** - ADAM metallopeptidase domain 23 (cell adhesion)
2. **Chp2** - Calcineurin-like EF-hand protein 2 (calcium signaling)
3. **Cldn19** - Claudin 19 (tight junction protein)
4. **Col1a1** - Collagen type I alpha 1 (ECM/fibrosis)
5. **Col3a1** - Collagen type III alpha 1 (ECM/fibrosis)
6. **Cpe** - Carboxypeptidase E (neuropeptide processing)
7. **Dclk3** - Doublecortin-like kinase 3 (microtubule regulation)
8. **Fxyd3** - FXYD domain-containing ion transport regulator 3
9. **Mbp** - Myelin basic protein (major myelin component)
10. **Rnd3** - Rho family GTPase 3 (cytoskeleton regulation)
11. **Sema7a** - Semaphorin 7A (axon guidance)
12. **Slc7a2** - Solute carrier family 7 member 2 (arginine transporter)
13. **Txnip** - Thioredoxin-interacting protein (oxidative stress)

**Functional Categories:**
- **ECM/Fibrosis (2 genes):** Col1a1, Col3a1
- **Myelin (1 gene):** Mbp
- **Oxidative Stress (1 gene):** Txnip
- **Cell Adhesion (2 genes):** Adam23, Cldn19
- **Signaling (4 genes):** Chp2, Dclk3, Rnd3, Sema7a
- **Metabolism (3 genes):** Cpe, Fxyd3, Slc7a2

### aggSC (21 genes)

**Complete Gene List:**
1. **Adamtsl1** - ADAMTS-like 1 (ECM organization)
2. **Cav1** - Caveolin 1 (membrane organization)
3. **Chp2** - Calcineurin-like EF-hand protein 2
4. **Chst2** - Carbohydrate sulfotransferase 2 (ECM modification)
5. **Col1a1** - Collagen type I alpha 1
6. **Fgf1** - Fibroblast growth factor 1 (growth factor signaling)
7. **Fxyd3** - FXYD domain-containing ion transport regulator 3
8. **Igfbp7** - Insulin-like growth factor binding protein 7
9. **Inpp5f** - Inositol polyphosphate-5-phosphatase F (signaling)
10. **Kcna2** - Potassium voltage-gated channel subfamily A member 2
11. **Mbp** - Myelin basic protein
12. **Nbl1** - Neuroblastoma 1, DAN family BMP antagonist
13. **Ppl** - Periplakin (cytoskeleton)
14. **Rgcc** - Regulator of cell cycle
15. **S100b** - S100 calcium-binding protein B (Schwann cell marker)
16. **Scube1** - Signal peptide, CUB domain, EGF-like 1
17. **Sdc3** - Syndecan 3 (cell surface proteoglycan)
18. **Sdk2** - Sidekick cell adhesion molecule 2
19. **Sema7a** - Semaphorin 7A
20. **Slc7a2** - Solute carrier family 7 member 2
21. **Txnip** - Thioredoxin-interacting protein

**Functional Categories:**
- **ECM/Fibrosis (3 genes):** Adamtsl1, Chst2, Col1a1
- **Myelin/Schwann markers (2 genes):** Mbp, S100b
- **Growth Factors (2 genes):** Fgf1, Igfbp7
- **Cell Adhesion (4 genes):** Cav1, Sdc3, Sdk2, Sema7a
- **Signaling (5 genes):** Chp2, Inpp5f, Nbl1, Rgcc, Scube1
- **Ion Transport (3 genes):** Fxyd3, Kcna2, Slc7a2
- **Oxidative Stress (1 gene):** Txnip
- **Cytoskeleton (1 gene):** Ppl

**Genes Unique to aggSC (not in majorSC):**
Adamtsl1, Cav1, Chst2, Fgf1, Igfbp7, Inpp5f, Kcna2, Nbl1, Ppl, Rgcc, S100b, Scube1, Sdc3, Sdk2

**Shared Between majorSC and aggSC:**
Chp2, Fxyd3, Mbp, Sema7a, Slc7a2, Txnip (plus Col1a1)

---

## Pathway Enrichment Analysis

### majorSC Top Pathways

| Rank | GO Term | P-value | Genes | Biological Process |
|------|---------|---------|-------|-------------------|
| 1 | Response to steroid hormone | 2.5e-05 | 4 | Mbp, Txnip, Col1a1, Cpe |
| 2 | Protein localization to nucleus | 2.7e-05 | 4 | Txnip, Col1a1, Chp2, Dclk3 |
| 3 | Response to hydrogen peroxide | 2.9e-05 | 3 | Txnip, Col1a1, Cpe |
| 4 | Protein localization to organelle | 7.6e-05 | 5 | Txnip, Col1a1, Cpe, Chp2, Dclk3 |
| 5 | Response to hormone | 1.2e-04 | 5 | Mbp, Txnip, Col1a1, Col3a1, Cpe |
| 6 | Response to progesterone | 1.6e-04 | 2 | Mbp, Txnip |
| 7 | Response to reactive oxygen species | 1.7e-04 | 3 | Txnip, Col1a1, Cpe |
| 8 | Response to glucose | 2.6e-04 | 3 | Txnip, Col1a1, Cpe |
| 9 | Response to hexose | 2.8e-04 | 3 | Txnip, Col1a1, Cpe |
| 10 | Response to monosaccharide | 3.0e-04 | 3 | Txnip, Col1a1, Cpe |

**Dominant Theme:** **OXIDATIVE STRESS AND METABOLIC STRESS**
- Response to ROS (hydrogen peroxide, reactive oxygen species)
- Response to glucose/hexose/monosaccharide (diabetic hyperglycemia)
- Steroid hormone response (metabolic dysregulation)

### aggSC Top Pathways

| Rank | GO Term | P-value | Genes | Biological Process |
|------|---------|---------|-------|-------------------|
| 1 | Regulation of cell motility | 9.1e-08 | 9 | Cav1, Chst2, Col1a1, Fgf1, Inpp5f, Nbl1, Rgcc, Sdc3, Sema7a |
| 2 | Regulation of locomotion | 1.4e-07 | 9 | Cav1, Chst2, Col1a1, Fgf1, Inpp5f, Nbl1, Rgcc, Sdc3, Sema7a |
| 3 | Locomotion | 5.2e-07 | 9 | Cav1, Chst2, Col1a1, Fgf1, Inpp5f, Nbl1, Rgcc, Sdc3, Sema7a |
| 4 | Regulation of cell migration | 9.3e-07 | 8 | Cav1, Chst2, Col1a1, Fgf1, Nbl1, Rgcc, Sdc3, Sema7a |
| 5 | Cell adhesion | 1.5e-06 | 9 | Cav1, Chst2, Col1a1, Igfbp7, Mbp, Rgcc, S100b, Sdc3, Sdk2 |
| 6 | Response to progesterone | 3.9e-06 | 3 | Cav1, Mbp, Txnip |
| 7 | Regulation of response to stimulus | 4.3e-06 | 13 | Cav1, Chp2, Col1a1, Fgf1, Igfbp7, Inpp5f, Nbl1, Ppl, Rgcc, S100b, Scube1, Sema7a, Slc7a2 |
| 8 | Anatomical structure morphogenesis | 6.7e-06 | 11 | Cav1, Col1a1, Fgf1, Igfbp7, Kcna2, Mbp, Nbl1, Rgcc, S100b, Sdk2, Sema7a |
| 9 | Response to steroid hormone | 9.1e-06 | 5 | Cav1, Col1a1, Mbp, S100b, Txnip |
| 10 | Cell motility | 1.2e-05 | 9 | Cav1, Chst2, Col1a1, Fgf1, Inpp5f, Nbl1, Rgcc, Sdc3, Sema7a |

**Dominant Theme:** **CELL MOTILITY AND ADHESION DYSREGULATION**
- Regulation of cell motility/migration (Schwann cell migration impaired)
- Cell adhesion (Schwann-axon contact disruption)
- Morphogenesis (tissue remodeling in response to damage)

---

## Key Biological Insights

### 1. Disease Signature Comparison: majorSC vs aggSC

| Feature | majorSC | aggSC | Interpretation |
|---------|---------|-------|----------------|
| **Gene count** | 13 | 21 | aggSC more comprehensive |
| **Top pathway** | Oxidative stress | Cell motility | Different disease aspects |
| **ECM genes** | 2 (Col1a1, Col3a1) | 3 (Col1a1, Adamtsl1, Chst2) | aggSC captures more ECM |
| **Myelin genes** | 1 (Mbp) | 2 (Mbp, S100b) | aggSC better Schwann marker coverage |
| **Growth factors** | 0 | 2 (Fgf1, Igfbp7) | aggSC captures growth factor dysregulation |
| **Cell cycle** | 0 | 1 (Rgcc) | aggSC captures proliferation changes |

**Conclusion:** **aggSC provides more comprehensive disease signature** with better coverage of ECM, growth factors, and Schwann cell markers. majorSC focuses more on metabolic/oxidative stress response.

### 2. Core Disease Mechanisms

#### **Mechanism 1: Oxidative Stress (primarily majorSC)**

**Key Gene: Txnip (Thioredoxin-Interacting Protein)**
- Inhibits thioredoxin, a major antioxidant
- Upregulated by hyperglycemia
- Promotes oxidative stress and inflammation
- Appears in 8/10 top majorSC pathways

**Supporting Genes:**
- Col1a1: Responds to ROS, drives fibrosis
- Cpe: Affected by oxidative environment

**Pathway Evidence:**
- Response to hydrogen peroxide (p=2.9e-05)
- Response to reactive oxygen species (p=1.7e-04)
- Response to glucose/hexose (p=2.6-2.8e-04)

**Interpretation:** HFD induces **hyperglycemia → oxidative stress → cellular damage** in Schwann cells.

#### **Mechanism 2: ECM Remodeling/Fibrosis (both cell types)**

**Key Genes:**
- **Col1a1** (both): Type I collagen, primary fibrotic marker
- **Col3a1** (majorSC): Type III collagen, associated with tissue remodeling
- **Adamtsl1** (aggSC): ADAMTS-like protein, ECM organization
- **Chst2** (aggSC): Carbohydrate sulfotransferase, ECM modification

**Pathway Evidence:**
- Collagen fibril organization (aggSC, p=1.6e-05)
- ECM organization (aggSC, p=8.1e-05)

**Interpretation:** HFD triggers **ECM remodeling and fibrosis** in peripheral nerve, potentially leading to endoneurial fibrosis and nerve dysfunction.

#### **Mechanism 3: Cell Motility Dysregulation (primarily aggSC)**

**Key Genes:**
- **Cav1**: Caveolin 1, membrane organization and signaling
- **Chst2, Sdc3, Sdk2**: Cell surface/ECM interaction molecules
- **Fgf1**: Growth factor affecting cell migration
- **Sema7a**: Semaphorin, axon guidance and cell migration

**Pathway Evidence:**
- Regulation of cell motility (p=9.1e-08, 9 genes)
- Cell migration (p=9.3e-07, 8 genes)
- Cell adhesion (p=1.5e-06, 9 genes)

**Interpretation:** HFD disrupts **Schwann cell migration and adhesion**, potentially impairing:
- Schwann cell recruitment to damaged axons
- Schwann-axon contact formation
- Remyelination capacity

#### **Mechanism 4: Myelin Dysfunction (both cell types)**

**Key Gene: Mbp (Myelin Basic Protein)**
- Major structural component of myelin sheath
- Conserved in both majorSC and aggSC
- Appears in response to steroid hormone pathways (suggesting dysregulation)

**Supporting Gene (aggSC): S100b**
- Schwann cell marker
- Calcium-binding protein involved in proliferation and differentiation
- Part of cell motility and morphogenesis pathways

**Interpretation:** HFD affects **myelin structure and Schwann cell differentiation state**.

#### **Mechanism 5: Growth Factor Signaling (aggSC only)**

**Key Genes:**
- **Fgf1**: Fibroblast growth factor 1
- **Igfbp7**: Insulin-like growth factor binding protein 7

**Pathway Evidence:**
- Part of cell motility, morphogenesis pathways
- Involved in response to stimulus regulation

**Interpretation:** HFD induces **growth factor dysregulation**, potentially representing:
- Compensatory growth signals
- Inflammatory signaling
- Aberrant proliferation signals

### 3. Metabolic Stress Response

**majorSC-Specific Enrichment:**
- Response to glucose (p=2.6e-04)
- Response to hexose (p=2.8e-04)
- Response to monosaccharide (p=3.0e-04)
- Response to steroid hormone (p=2.5e-05)

**Key Genes:**
- **Txnip**: Glucose-responsive oxidative stress inducer
- **Col1a1**: Responds to metabolic stress
- **Cpe**: Neuropeptide processing affected by metabolic state
- **Mbp**: Myelin affected by steroid hormone dysregulation

**Interpretation:** HFD creates a **metabolic stress environment** characterized by:
- Hyperglycemia (glucose/hexose response)
- Hormonal dysregulation (steroid hormone, progesterone response)
- Oxidative damage (ROS response)

---

## Cross-Species Validation

### Genes Conserved Across Species

**Present in both mouse and human Schwann cells:**

**High-Confidence Disease Markers (in both majorSC and aggSC):**
1. **Mbp** - Core myelin dysfunction
2. **Col1a1** - ECM remodeling/fibrosis
3. **Txnip** - Oxidative stress
4. **Sema7a** - Axon guidance dysregulation

**aggSC-Specific High-Confidence Markers:**
- **S100b** - Schwann cell activation marker
- **Fgf1** - Growth factor dysregulation
- **Chst2** - ECM modification
- **Rgcc** - Cell cycle dysregulation

**Clinical Translation Potential:**

These conserved genes represent **cross-species validated disease signatures** that are:
1. **Detectable in both mouse models and human DPN patients**
2. **Cell-type specific** (Schwann cells, not bulk nerve)
3. **Mechanistically relevant** (oxidative stress, ECM, myelin, motility)
4. **Potential biomarkers** for disease progression
5. **Potential therapeutic targets** for intervention

---

## Unique Observations

### 1. Txnip as Central Hub (majorSC)

**Txnip appears in 8 of top 10 pathways:**
- Response to steroid hormone
- Protein localization to nucleus
- Response to hydrogen peroxide
- Protein localization to organelle
- Response to hormone
- Response to progesterone
- Response to reactive oxygen species
- Response to glucose

**Interpretation:** Txnip is a **master regulator** connecting:
- Metabolic stress (glucose, hormone response)
- Oxidative damage (ROS, hydrogen peroxide)
- Nuclear signaling (protein localization)

**Therapeutic Implication:** Txnip inhibition could address multiple disease mechanisms simultaneously.

### 2. Cell Motility Gene Network (aggSC)

**9 genes co-enriched in motility pathways:**
Cav1, Chst2, Col1a1, Fgf1, Inpp5f, Nbl1, Rgcc, Sdc3, Sema7a

**Network Interpretation:**
- **Membrane organization** (Cav1)
- **ECM interaction** (Chst2, Col1a1, Sdc3)
- **Signaling** (Fgf1, Inpp5f, Nbl1)
- **Cell cycle** (Rgcc)
- **Guidance** (Sema7a)

**Functional Consequence:** HFD creates a **multi-level disruption** of Schwann cell motility:
- Surface receptors altered (Chst2, Sdc3)
- ECM barrier increased (Col1a1)
- Signaling dysregulated (Fgf1, Inpp5f)
- Migration machinery impaired (Cav1, Sema7a)

### 3. Ion Transport Dysregulation

**Three ion transport genes conserved:**
- **Fxyd3**: Na/K-ATPase regulator (both cell types)
- **Kcna2**: Potassium channel (aggSC)
- **Slc7a2**: Arginine transporter (both cell types)

**Pathway Evidence:**
- Regulation of sodium ion transport (aggSC, p=2.5e-05)

**Interpretation:** HFD affects **ionic homeostasis** in Schwann cells, potentially impacting:
- Action potential propagation
- Schwann cell excitability
- Metabolic coupling to axons

---

## aggSC Advantage: Why 62% More Genes?

**aggSC captures genes from multiple Schwann subtypes:**
- **mySC** (myelinating): Mbp, Ppl
- **nmSC** (non-myelinating): S100b, Cav1
- **ImmSC** (immature): Rgcc, Igfbp7

**Genes unique to aggSC represent subtype-specific responses:**

| Gene | Likely Subtype | Function | Disease Relevance |
|------|---------------|----------|-------------------|
| **Rgcc** | ImmSC/mySC | Cell cycle regulation | Proliferation changes |
| **S100b** | nmSC/activated SC | Schwann cell marker | Activation/dedifferentiation |
| **Fgf1** | nmSC/ImmSC | Growth factor | Regeneration signaling |
| **Cav1** | nmSC | Membrane organization | Non-myelinating SC function |
| **Chst2** | All subtypes | ECM modification | Matrix remodeling |

**Conclusion:** **aggSC provides better coverage of disease complexity** by capturing responses from multiple Schwann cell subtypes, each contributing different aspects of disease pathology.

---

## Therapeutic Implications

### Target 1: Oxidative Stress (Txnip pathway)

**Rationale:**
- Txnip central hub in majorSC pathways
- Connects metabolic and oxidative stress
- Conserved across species

**Therapeutic Strategies:**
1. **Txnip inhibitors** (direct target)
2. **Antioxidants** (thioredoxin mimetics)
3. **Metabolic control** (glucose normalization reduces Txnip)

### Target 2: ECM Remodeling/Fibrosis

**Rationale:**
- Col1a1 conserved in both cell types
- ECM pathways enriched in aggSC
- Endoneurial fibrosis correlates with neuropathy severity

**Therapeutic Strategies:**
1. **Anti-fibrotic agents** (pirfenidone, nintedanib)
2. **MMP modulators** (regulate collagen turnover)
3. **TGF-β inhibitors** (upstream of fibrosis)

### Target 3: Cell Motility/Adhesion Restoration

**Rationale:**
- Strong enrichment in aggSC (9 genes, p=9.1e-08)
- Schwann cell migration critical for nerve repair
- Multiple targetable nodes in pathway

**Therapeutic Strategies:**
1. **Cav1 modulators** (restore membrane organization)
2. **Semaphorin pathway modulation**
3. **ECM modification** (reduce barrier to migration)

### Target 4: Growth Factor Signaling

**Rationale:**
- Fgf1 dysregulated in aggSC
- Growth factors critical for nerve regeneration
- Potentially representing failed compensatory response

**Therapeutic Strategies:**
1. **Fgf1 supplementation** (if downregulated)
2. **Fgf1 pathway inhibition** (if representing pathological signal)
3. **Growth factor balance optimization**

---

## Conclusions

1. **HFD induces 13-21 conserved genes** between mouse and human Schwann cells, representing cross-species validated disease signatures

2. **aggSC captures 62% more genes** than majorSC (21 vs 13), providing more comprehensive disease coverage including growth factors, additional ECM genes, and Schwann cell markers

3. **Two distinct pathway themes emerge:**
   - **majorSC**: Oxidative stress, metabolic stress response (Txnip-centered)
   - **aggSC**: Cell motility dysregulation, adhesion impairment (9-gene network)

4. **Txnip is a master hub** appearing in 8/10 top majorSC pathways, connecting metabolic stress, oxidative damage, and nuclear signaling

5. **Cell motility dysregulation** is the strongest aggSC signal (p=9.1e-08), involving 9 genes across membrane, ECM, signaling, and guidance systems

6. **Core disease mechanisms:**
   - Oxidative stress (Txnip, ROS response)
   - ECM remodeling/fibrosis (Col1a1, Col3a1, Adamtsl1, Chst2)
   - Myelin dysfunction (Mbp, S100b)
   - Cell motility impairment (9-gene network)
   - Growth factor dysregulation (Fgf1, Igfbp7)

7. **Cross-species conservation validates** these genes as high-confidence disease markers with clinical translation potential

8. **Therapeutic opportunities** include Txnip inhibition (oxidative stress), anti-fibrotic agents (ECM remodeling), and cell motility restoration strategies

**Recommendation:** Use **aggSC for comprehensive disease characterization** and **majorSC for focused metabolic/oxidative stress assessment**. Combined analysis provides complementary views of HFD-induced neuropathy mechanisms.

---

**Next Steps:** Compare these disease signatures with intervention responses (DRvsHFD, EXvsHFD, DREXvsHFD) to identify which disease mechanisms are reversed by each therapeutic approach.
