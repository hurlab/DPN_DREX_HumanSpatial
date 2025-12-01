@echo off
REM Batch script to run all analyses in sequence
REM Using standalone R installation (not conda)

SET RSCRIPT="C:\Program Files\R\R-4.5.2\bin\Rscript.exe"

echo ========================================
echo Starting All Analyses
echo ========================================
echo.
echo Current directory: %CD%
echo R version:
%RSCRIPT% --version
echo.

echo ========================================
echo [1/6] Running Main Enrichment Analysis
echo Expected time: 10-25 minutes
echo ========================================
%RSCRIPT% analysis_enrichment_JCI_Schwann_mouse.R
IF %ERRORLEVEL% NEQ 0 (
    echo ERROR: Main enrichment analysis failed!
    echo Check the error messages above.
    pause
    exit /b 1
)
echo Main enrichment completed successfully!
echo.

echo ========================================
echo [2/6] Running Cell Type Enrichment Comparison
echo Expected time: 2-5 minutes
echo ========================================
%RSCRIPT% analysis_01_celltype_enrichment_comparison.R
IF %ERRORLEVEL% NEQ 0 (
    echo WARNING: Cell type comparison failed - continuing...
)
echo.

echo ========================================
echo [3/6] Running Intervention Response Analysis
echo Expected time: 1-3 minutes
echo ========================================
%RSCRIPT% analysis_02_intervention_response.R
IF %ERRORLEVEL% NEQ 0 (
    echo WARNING: Intervention response analysis failed - continuing...
)
echo.

echo ========================================
echo [4/6] Running Conservation Analysis
echo Expected time: 1-3 minutes
echo ========================================
%RSCRIPT% analysis_03_conservation_analysis.R
IF %ERRORLEVEL% NEQ 0 (
    echo WARNING: Conservation analysis failed - continuing...
)
echo.

echo ========================================
echo [5/6] Running Direction of Change Analysis
echo Expected time: 3-5 minutes
echo ========================================
%RSCRIPT% analysis_04_direction_of_change.R
IF %ERRORLEVEL% NEQ 0 (
    echo WARNING: Direction analysis failed - continuing...
)
echo.

echo ========================================
echo [6/6] Running Leading Edge Gene Analysis
echo Expected time: 2-4 minutes
echo ========================================
%RSCRIPT% analysis_05_leading_edge_genes.R
IF %ERRORLEVEL% NEQ 0 (
    echo WARNING: Leading edge analysis failed - continuing...
)
echo.

echo ========================================
echo All Analyses Complete!
echo ========================================
echo.
echo Results are in: Output_JCI_Schwann_enrichment\
echo.
echo Summary of outputs:
dir /B Output_JCI_Schwann_enrichment
echo.
pause
