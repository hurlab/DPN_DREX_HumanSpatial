# Re-run Failed Analyses
# This script waits for main enrichment to complete, then re-runs analyses that failed

$RSCRIPT = "C:\Program Files\R\R-4.5.2\bin\Rscript.exe"
$LOG_FILE = "rerun_failed_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$COMPLETION_MARKER = "Output_JCI_Schwann_enrichment\DREXvsDR_mySC_enrichment"  # More specific marker

function Write-Log {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage
    Add-Content -Path $LOG_FILE -Value $logMessage
}

Write-Log "========================================="
Write-Log "RE-RUN FAILED ANALYSES"
Write-Log "========================================="
Write-Log "Waiting for main enrichment to process multiple files..."
Write-Log "Will check every 15 minutes for completion of at least 5 Schwann files"
Write-Log ""

# Wait for at least 5 enrichment folders to exist (indicating substantial progress)
$checkCount = 0
$maxChecks = 40  # Max 10 hours

while ($checkCount -lt $maxChecks) {
    $checkCount++

    # Count enrichment folders
    $enrichmentFolders = Get-ChildItem -Path "Output_JCI_Schwann_enrichment" -Directory -Filter "*_enrichment" -ErrorAction SilentlyContinue
    $folderCount = ($enrichmentFolders | Measure-Object).Count

    if ($folderCount -ge 10) {
        Write-Log "SUCCESS: Found $folderCount enrichment folders. Main enrichment is progressing well."
        break
    }

    Write-Log "Check #$checkCount - Found $folderCount enrichment folders. Waiting for 10+ folders... ($(Get-Date -Format 'HH:mm:ss'))"

    # Wait 15 minutes
    Start-Sleep -Seconds 900
}

Write-Log ""
Write-Log "Main enrichment has created enough data. Re-running failed analyses..."
Write-Log ""

# Re-run analysis 1
Write-Log "========================================="
Write-Log "Re-running: Cell Type Enrichment Comparison"
Write-Log "========================================="
try {
    & $RSCRIPT "analysis_01_celltype_enrichment_comparison.R" 2>&1 | Tee-Object -Append -FilePath $LOG_FILE
    Write-Log "Analysis 1 completed with exit code: $LASTEXITCODE"
} catch {
    Write-Log "ERROR in Analysis 1: $_"
}

Write-Log ""

# Re-run analysis 5
Write-Log "========================================="
Write-Log "Re-running: Leading Edge Gene Analysis"
Write-Log "========================================="
try {
    & $RSCRIPT "analysis_05_leading_edge_genes.R" 2>&1 | Tee-Object -Append -FilePath $LOG_FILE
    Write-Log "Analysis 5 completed with exit code: $LASTEXITCODE"
} catch {
    Write-Log "ERROR in Analysis 5: $_"
}

Write-Log ""
Write-Log "========================================="
Write-Log "RE-RUN COMPLETE"
Write-Log "========================================="
Write-Log "Check the output directories for updated results"
Write-Log "Log saved to: $LOG_FILE"
