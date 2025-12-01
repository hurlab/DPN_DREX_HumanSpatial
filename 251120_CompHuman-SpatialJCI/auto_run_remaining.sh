#!/bin/bash
# Automated runner for remaining analyses after main enrichment completes

LOG_FILE="remaining_analyses_$(date +%Y%m%d_%H%M%S).log"
OUTPUT_DIR="Output_JCI_Schwann_enrichment"
MARKER_FILE="$OUTPUT_DIR/Master_Enrichment_Summary.csv"

echo "===========================================" | tee -a "$LOG_FILE"
echo "Remaining Analyses Runner" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "===========================================" | tee -a "$LOG_FILE"

# Wait for main enrichment to complete
echo "" | tee -a "$LOG_FILE"
echo "Waiting for main enrichment to complete..." | tee -a "$LOG_FILE"
echo "Looking for: $MARKER_FILE" | tee -a "$LOG_FILE"

while [ ! -f "$MARKER_FILE" ]; do
  echo "  [$(date +%H:%M:%S)] Still waiting... (checking every 60 seconds)" | tee -a "$LOG_FILE"
  sleep 60
done

echo "" | tee -a "$LOG_FILE"
echo "✓ Main enrichment complete! Master summary found." | tee -a "$LOG_FILE"
echo "Starting remaining analyses..." | tee -a "$LOG_FILE"

# Run the 5 additional analyses
analyses=(
  "analysis_01_celltype_enrichment_comparison.R"
  "analysis_02_intervention_response.R"
  "analysis_03_conservation_analysis.R"
  "analysis_04_direction_of_change.R"
  "analysis_05_leading_edge_genes.R"
)

for i in "${!analyses[@]}"; do
  script="${analyses[$i]}"
  num=$((i+1))

  echo "" | tee -a "$LOG_FILE"
  echo "===========================================" | tee -a "$LOG_FILE"
  echo "Analysis $num of ${#analyses[@]}: $script" | tee -a "$LOG_FILE"
  echo "Started: $(date)" | tee -a "$LOG_FILE"
  echo "===========================================" | tee -a "$LOG_FILE"

  Rscript "$script" 2>&1 | tee -a "$LOG_FILE"

  if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "✓ Analysis $num completed successfully" | tee -a "$LOG_FILE"
  else
    echo "✗ Analysis $num failed with error code ${PIPESTATUS[0]}" | tee -a "$LOG_FILE"
  fi
done

echo "" | tee -a "$LOG_FILE"
echo "===========================================" | tee -a "$LOG_FILE"
echo "All analyses complete!" | tee -a "$LOG_FILE"
echo "Finished: $(date)" | tee -a "$LOG_FILE"
echo "Log file: $LOG_FILE" | tee -a "$LOG_FILE"
echo "===========================================" | tee -a "$LOG_FILE"
