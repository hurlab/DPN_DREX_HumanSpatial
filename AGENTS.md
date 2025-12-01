# Repository Guidelines

## Project Structure & Module Organization
- Root contains the current pipeline `2025-08-21_DREX-Comp-HumanSural_v3.R`; prior versions and reference inputs live in `251120_CompHuman-SpatialJCI/`.
- Mouse DEG inputs sit in `DEG/` and `DEG_Major/`; human reference tables live in `251120_CompHuman-SpatialJCI/HSuralRNASeq_Human/`.
- Script outputs are written under `Output_DEG_vsHuman/` and `Output_DEG_Major_vsHuman/` (mirrored inside `251120_CompHuman-SpatialJCI/` for historical runs).
- Keep new data files in the existing folder families to preserve relative paths inside the R scripts.

## Build, Test, and Development Commands
- Install dependencies once inside R: `if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman"); pacman::p_load(dplyr, tidyr, ggplot2, ggVennDiagram, readxl, homologene, pheatmap, openxlsx, AnnotationDbi, org.Mm.eg.db, org.Hs.eg.db)`.
- Run the full pipeline from the script directory so relative paths resolve: `cd 251120_CompHuman-SpatialJCI && Rscript 2025-08-21_DREX-Comp-HumanSural_v3.R`.
- For ad-hoc checks, drop into R with `R -q` and source the script: `source("2025-08-21_DREX-Comp-HumanSural_v3.R")`.

## Coding Style & Naming Conventions
- Use tidyverse style: pipe-friendly verbs, snake_case object names, and 2-space indentation.
- Prefer explicit column renaming and defensive checks (e.g., verifying required columns) as in the current helpers.
- Load packages via `pacman::p_load(...)` to auto-install and keep scripts self-bootstrapping.
- Keep outputs reproducible: sanitize filenames with `safe_base()` and persist via `save_df()`/`save_plot()` patterns already in the script.

## Testing Guidelines
- No automated tests exist; validate by running the pipeline and confirming fresh artifacts in `Output_DEG_vsHuman/` and `Output_DEG_Major_vsHuman/`.
- Spot-check key CSVs for expected filters (e.g., `padj < 0.05` for human sets; `padj < 0.001` and `|log2FC| > 1` for Schwann/JCI) using quick `dplyr::count()` or `summary()` calls.
- Re-run sections after adding new input files to ensure mappings (`human2mouse`) complete without NAs.

## Commit & Pull Request Guidelines
- Use descriptive commits highlighting dataset and threshold changes (e.g., “Update Schwann padj cutoff to 0.001 and regenerate outputs”).
- In PRs, include: purpose, key commands run, inputs added/updated, and a short note on outputs produced (counts or example file paths). Attach a representative plot (e.g., a Venn PNG) when visuals change.
- Avoid committing large intermediates unless they are final outputs meant for sharing; prefer regenerating from source data.
