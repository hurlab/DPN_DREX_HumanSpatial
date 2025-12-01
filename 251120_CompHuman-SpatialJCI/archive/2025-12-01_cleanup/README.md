# Archive: December 1, 2025 Cleanup

This folder contains files archived during the December 1, 2025 project reorganization.

## Contents

### Test Run Logs
- `test_run.log` - Initial test run of script 00 (main enrichment)
- `run_01.log` - Script 01 test run (Cell type enrichment comparison)
- `run_02.log` - Script 02 test run (Intervention response analysis)
- `run_03.log` - Script 03 test run (Conservation analysis)
- `run_04.log` - Script 04 test run (Direction of change analysis)
- `run_05.log` - Script 05 test run (Leading edge genes analysis)
- `run_06.log` - Script 06 initial test run (Bioenergetic focus)
- `run_06_updated.log` - Script 06 rerun after path update

## Changes Made on This Date

1. **Script Renaming**: Renamed all analysis scripts to numbered format (00-06)
2. **Path Updates**: Changed all output paths from `Output_JCI_Schwann_enrichment` to `Output_JCI`
3. **Filters Applied**:
   - Cell types: Removed SC3, kept only mySC, nmSC, ImmSC, majorSC
   - Comparisons: Limited to HFDvsSD, DRvsHFD, EXvsHFD, DREXvsHFD
4. **Dataset Names**: Updated Venn diagrams to use Mouse, JCI_SC, JCI_Bulk
5. **Enrichment**: Switched to richR only (removed clusterProfiler)
6. **Directory Structure**: Created Enrichment_Analysis subdirectory within Output_JCI
7. **Bioenergetic Output**: Moved from independent directory to Output_JCI/Bioenergetic_Focus

## Results

All scripts (00-06) completed successfully with the new configuration.
