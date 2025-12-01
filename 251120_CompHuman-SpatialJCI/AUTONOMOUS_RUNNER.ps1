# Autonomous Analysis Runner
# This script monitors the main enrichment and automatically runs remaining analyses when complete

$RSCRIPT = "C:\Program Files\R\R-4.5.2\bin\Rscript.exe"
$LOG_FILE = "autonomous_run_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$COMPLETION_MARKER = "Output_JCI_Schwann_enrichment\Master_Enrichment_Summary.csv"

function Write-Log {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage
    Add-Content -Path $LOG_FILE -Value $logMessage
}

function Run-Analysis {
    param(
        [string]$ScriptPath,
        [string]$Name,
        [int]$Number,
        [int]$Total
    )

    Write-Log ""
    Write-Log "========================================"
    Write-Log "[$Number/$Total] $Name"
    Write-Log "========================================"
    Write-Log "Script: $ScriptPath"

    $startTime = Get-Date

    try {
        & $RSCRIPT $ScriptPath 2>&1 | Tee-Object -Append -FilePath $LOG_FILE
        $exitCode = $LASTEXITCODE
    } catch {
        Write-Log "ERROR: $_"
        $exitCode = 1
    }

    $endTime = Get-Date
    $duration = $endTime - $startTime

    Write-Log "Completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Log "Duration: $($duration.TotalMinutes.ToString('F1')) minutes"
    Write-Log "Exit code: $exitCode"

    if ($exitCode -ne 0) {
        Write-Log "WARNING: Analysis may have encountered errors"
    }

    Write-Log "========================================"

    return @{
        Success = ($exitCode -eq 0)
        Duration = $duration
    }
}

# Start monitoring
Write-Log "========================================"
Write-Log "AUTONOMOUS ANALYSIS RUNNER"
Write-Log "========================================"
Write-Log "Starting autonomous monitoring and execution"
Write-Log "Working directory: $(Get-Location)"
Write-Log "Log file: $LOG_FILE"
Write-Log "========================================"
Write-Log ""

# Monitor main enrichment
Write-Log "Monitoring main enrichment analysis..."
Write-Log "Checking for completion marker: $COMPLETION_MARKER"
Write-Log "Will check every 10 minutes..."
Write-Log ""

$checkCount = 0
$maxChecks = 60  # Max 10 hours (60 * 10 minutes)

while ($checkCount -lt $maxChecks) {
    $checkCount++

    if (Test-Path $COMPLETION_MARKER) {
        Write-Log "SUCCESS: Main enrichment analysis completed!"
        Write-Log "Detected completion marker at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        break
    }

    Write-Log "Check #$checkCount - Main enrichment still running... ($(Get-Date -Format 'HH:mm:ss'))"

    if ($checkCount -ge $maxChecks) {
        Write-Log "ERROR: Maximum wait time exceeded (10 hours)"
        Write-Log "Main enrichment may have stalled. Check manually."
        exit 1
    }

    # Wait 10 minutes
    Start-Sleep -Seconds 600
}

# Run additional analyses
Write-Log ""
Write-Log "========================================"
Write-Log "STARTING ADDITIONAL ANALYSES"
Write-Log "========================================"
Write-Log ""

$overallStart = Get-Date

$analyses = @(
    @{Script="analysis_01_celltype_enrichment_comparison.R"; Name="Cell Type Enrichment Comparison"},
    @{Script="analysis_02_intervention_response.R"; Name="Intervention Response Analysis"},
    @{Script="analysis_03_conservation_analysis.R"; Name="Conservation Analysis"},
    @{Script="analysis_04_direction_of_change.R"; Name="Direction of Change Analysis"},
    @{Script="analysis_05_leading_edge_genes.R"; Name="Leading Edge Gene Analysis"}
)

$results = @()

for ($i = 0; $i -lt $analyses.Count; $i++) {
    $analysis = $analyses[$i]
    $result = Run-Analysis -ScriptPath $analysis.Script -Name $analysis.Name -Number ($i+1) -Total $analyses.Count
    $results += @{
        Name = $analysis.Name
        Success = $result.Success
        Duration = $result.Duration
    }

    # Small delay between analyses
    Start-Sleep -Seconds 5
}

$overallEnd = Get-Date
$overallDuration = $overallEnd - $overallStart

# Summary
Write-Log ""
Write-Log "========================================"
Write-Log "ALL ANALYSES COMPLETE"
Write-Log "========================================"
Write-Log "Total time for additional analyses: $($overallDuration.TotalMinutes.ToString('F1')) minutes"
Write-Log ""
Write-Log "Summary:"

foreach ($result in $results) {
    $status = if ($result.Success) { "[SUCCESS]" } else { "[FAILED]" }
    $minutes = $result.Duration.TotalMinutes.ToString('F1')
    Write-Log "  $status - $($result.Name) ($minutes min)"
}

Write-Log ""
Write-Log "Output directory: Output_JCI_Schwann_enrichment\"
Write-Log "Check subdirectories for results:"
Write-Log "  - CellType_Comparison\"
Write-Log "  - Intervention_Response\"
Write-Log "  - Conservation_Analysis\"
Write-Log "  - Direction_Analysis\"
Write-Log "  - Leading_Edge_Analysis\"
Write-Log "========================================"
Write-Log ""
Write-Log "All tasks completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Log "Full log saved to: $LOG_FILE"
