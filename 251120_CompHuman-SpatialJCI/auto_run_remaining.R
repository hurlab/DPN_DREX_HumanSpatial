#!/usr/bin/env Rscript
################################################################################
# Automatic Sequential Analysis Runner
# Waits for main enrichment to complete, then runs analyses 1-5
################################################################################

# Set working directory
setwd(dirname(sys.frame(1)$ofile))

# R executable path
rscript_path <- "C:/Program Files/R/R-4.5.2/bin/Rscript.exe"

# List of analyses to run (in order)
analyses <- c(
  "analysis_01_celltype_enrichment_comparison.R",
  "analysis_02_intervention_response.R",
  "analysis_03_conservation_analysis.R",
  "analysis_04_direction_of_change.R",
  "analysis_05_leading_edge_genes.R"
)

analysis_names <- c(
  "Cell Type Enrichment Comparison",
  "Intervention Response Analysis",
  "Conservation Analysis",
  "Direction of Change Analysis",
  "Leading Edge Gene Analysis"
)

# Function to run an R script
run_analysis <- function(script_path, name, number, total) {
  cat("\n")
  cat("========================================\n")
  cat(sprintf("[%d/%d] %s\n", number, total, name))
  cat("========================================\n")
  cat("Script:", script_path, "\n")
  cat("Started at:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")

  start_time <- Sys.time()

  # Run the script
  result <- tryCatch({
    system2(rscript_path, args = script_path, stdout = TRUE, stderr = TRUE)
    TRUE
  }, error = function(e) {
    cat("ERROR:", e$message, "\n")
    FALSE
  })

  end_time <- Sys.time()
  elapsed <- difftime(end_time, start_time, units = "mins")

  cat("\nCompleted at:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
  cat(sprintf("Time elapsed: %.1f minutes\n", as.numeric(elapsed)))

  if (!result) {
    cat("WARNING: Analysis may have encountered errors. Check output above.\n")
  }

  cat("========================================\n\n")

  return(list(success = result, time = elapsed))
}

# Main execution
cat("\n")
cat("========================================\n")
cat("AUTOMATIC ANALYSIS RUNNER\n")
cat("========================================\n")
cat("This script will run analyses 1-5 in sequence\n")
cat("Total analyses to run:", length(analyses), "\n")
cat("Started at:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("========================================\n\n")

overall_start <- Sys.time()
results <- list()

# Run each analysis
for (i in seq_along(analyses)) {
  results[[i]] <- run_analysis(analyses[i], analysis_names[i], i, length(analyses))

  # Small delay between analyses
  Sys.sleep(2)
}

overall_end <- Sys.time()
overall_elapsed <- difftime(overall_end, overall_start, units = "mins")

# Summary
cat("\n")
cat("========================================\n")
cat("ALL ANALYSES COMPLETE\n")
cat("========================================\n")
cat(sprintf("Total time: %.1f minutes\n", as.numeric(overall_elapsed)))
cat("\nSummary:\n")
for (i in seq_along(analyses)) {
  status <- if (results[[i]]$success) "✓" else "✗"
  cat(sprintf("  %s [%d/%d] %s (%.1f min)\n",
              status, i, length(analyses),
              analysis_names[i],
              as.numeric(results[[i]]$time)))
}

cat("\nOutput location: Output_JCI_Schwann_enrichment/\n")
cat("\nCheck subdirectories for results:\n")
cat("  - CellType_Comparison/\n")
cat("  - Intervention_Response/\n")
cat("  - Conservation_Analysis/\n")
cat("  - Direction_Analysis/\n")
cat("  - Leading_Edge_Analysis/\n")
cat("========================================\n")
