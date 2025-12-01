#!/bin/bash
################################################################################
# Sequential Analysis Runner
# Runs analyses 1-5 after main enrichment completes
################################################################################

RSCRIPT="C:/Program Files/R/R-4.5.2/bin/Rscript.exe"
LOG_FILE="analysis_log_$(date +%Y%m%d_%H%M%S).txt"

echo "========================================"
echo "Running Additional Analyses"
echo "Started: $(date)"
echo "========================================"
echo ""

# Analysis 1
echo "========================================"
echo "[1/5] Cell Type Enrichment Comparison"
echo "========================================"
"$RSCRIPT" analysis_01_celltype_enrichment_comparison.R 2>&1 | tee -a "$LOG_FILE"
echo "Completed: $(date)"
echo ""

# Analysis 2
echo "========================================"
echo "[2/5] Intervention Response Analysis"
echo "========================================"
"$RSCRIPT" analysis_02_intervention_response.R 2>&1 | tee -a "$LOG_FILE"
echo "Completed: $(date)"
echo ""

# Analysis 3
echo "========================================"
echo "[3/5] Conservation Analysis"
echo "========================================"
"$RSCRIPT" analysis_03_conservation_analysis.R 2>&1 | tee -a "$LOG_FILE"
echo "Completed: $(date)"
echo ""

# Analysis 4
echo "========================================"
echo "[4/5] Direction of Change Analysis"
echo "========================================"
"$RSCRIPT" analysis_04_direction_of_change.R 2>&1 | tee -a "$LOG_FILE"
echo "Completed: $(date)"
echo ""

# Analysis 5
echo "========================================"
echo "[5/5] Leading Edge Gene Analysis"
echo "========================================"
"$RSCRIPT" analysis_05_leading_edge_genes.R 2>&1 | tee -a "$LOG_FILE"
echo "Completed: $(date)"
echo ""

echo "========================================"
echo "All Additional Analyses Complete!"
echo "Finished: $(date)"
echo "========================================"
echo ""
echo "Log file: $LOG_FILE"
echo "Results directory: Output_JCI_Schwann_enrichment/"
