Session summary (richR/clusterProfiler enrichment)
==================================================

- Date/time: current run generated enrichment outputs under `251120_CompHuman-SpatialJCI/Output_JCI_Schwann_enrichment/manual/`.
- Script change: updated `251120_CompHuman-SpatialJCI/analysis_enrichment_JCI_Schwann_mouse.R` to:
  - Use `richR::buildAnnot` + `richGO`/`richKEGG` when available.
  - Fall back to `clusterProfiler::enrichGO` (GO:BP, SYMBOL) and `enrichKEGG` (KEGG, Entrez) for every set.
- Manual targeted enrichments produced (both richR_* and clusterProfiler_* where successful):
  - `EXvsHFD_majorSC_Overlap_MJ_*`
  - `EXvsHFD_majorSC_Overlap_MS_*`
  - `EXvsHFD_majorSC_Overlap_All3_*`
  - `DREXvsHFD_mySC_Overlap_MJ_*`
  - `DREXvsHFD_mySC_Overlap_MS_*`
- Pending: `DREXvsHFD_mySC_Overlap_All3_*` enrichment not completed (timeout; richR mapping issues). Re-run single set later if needed.
- To rerun full pipeline after reboot (may take time): `cd 251120_CompHuman-SpatialJCI && Rscript analysis_enrichment_JCI_Schwann_mouse.R`

Follow-up note (pending work)
-----------------------------
- Still pending: `DREXvsHFD_mySC_Overlap_All3_*` enrichment (timeout/mapping); rerun that set later if needed.
- To regenerate everything later: `cd 251120_CompHuman-SpatialJCI && Rscript analysis_enrichment_JCI_Schwann_mouse.R` (may need a longer timeout).
