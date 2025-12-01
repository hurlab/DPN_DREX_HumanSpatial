@echo off
REM This script monitors the main enrichment analysis and automatically runs remaining analyses
REM It checks every 2 minutes for completion

SET RSCRIPT="C:\Program Files\R\R-4.5.2\bin\Rscript.exe"
SET OUTPUT_FILE=Output_JCI_Schwann_enrichment\Master_Enrichment_Summary.csv
SET LOG_FILE=analysis_progress.log

echo ======================================== >> %LOG_FILE%
echo Monitor started: %DATE% %TIME% >> %LOG_FILE%
echo ======================================== >> %LOG_FILE%
echo.

echo Monitoring main enrichment analysis...
echo Checking every 2 minutes for completion...
echo Log file: %LOG_FILE%
echo.

:WAIT_LOOP
REM Check if the output file exists (indicates main analysis completed)
if exist "%OUTPUT_FILE%" (
    echo Main enrichment completed! >> %LOG_FILE%
    echo Detected at: %DATE% %TIME% >> %LOG_FILE%
    goto RUN_REMAINING
)

REM Wait 2 minutes before checking again
echo Waiting... %TIME% >> %LOG_FILE%
timeout /t 120 /nobreak >nul
goto WAIT_LOOP

:RUN_REMAINING
echo.
echo ========================================
echo Main Enrichment Analysis Complete!
echo Starting remaining analyses...
echo ========================================
echo.

echo ======================================== >> %LOG_FILE%
echo Running remaining analyses: %DATE% %TIME% >> %LOG_FILE%
echo ======================================== >> %LOG_FILE%

REM Run the automatic runner script
%RSCRIPT% auto_run_remaining.R 2>&1 | tee -a %LOG_FILE%

echo.
echo ========================================
echo All Analyses Complete!
echo ========================================
echo.
echo Check %LOG_FILE% for full details
echo Results are in: Output_JCI_Schwann_enrichment\
echo.
