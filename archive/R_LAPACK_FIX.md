# R LAPACK Error Fix

## Problem
Your R installation is showing this error:
```
Error in La_library() : LAPACK routines cannot be loaded
LoadLibrary failure: The specified procedure could not be found.
```

This prevents R scripts from running.

## Solution Options

### Option 1: Reinstall R in Conda (Recommended)
```bash
# Remove the current R installation
conda remove -n openai r-base r-essentials --all

# Reinstall R with all dependencies
conda install -n openai -c conda-forge r-base r-essentials

# Or create a fresh R environment
conda create -n r_env -c conda-forge r-base r-essentials
conda activate r_env
```

### Option 2: Install Standalone R (Most Reliable)
1. Download R from CRAN: https://cran.r-project.org/bin/windows/base/
2. Install R to `C:\Program Files\R\R-4.4.x\`
3. Add to system PATH: `C:\Program Files\R\R-4.4.x\bin\x64`
4. Restart your terminal
5. Test: `Rscript --version`

### Option 3: Fix Conda R LAPACK
```bash
# Try reinstalling the MKL library
conda install -n openai -c conda-forge mkl

# Or use openblas instead
conda install -n openai -c conda-forge openblas
```

### Option 4: Use RStudio
If you have RStudio installed, you can run the scripts directly from RStudio instead of the command line.

## After Fixing R

Once R is working, run the scripts in this order:

```bash
cd "C:\JHCloud\OneDrive - North Dakota University System\Desktop\GitHub\DPN_DREX_HumanSpatial\251120_CompHuman-SpatialJCI"

# 1. Main enrichment analysis (this will take 10-25 minutes with 24 cores)
Rscript analysis_enrichment_JCI_Schwann_mouse.R

# 2. Cell type-specific enrichment comparison
Rscript analysis_01_celltype_enrichment_comparison.R

# 3. Intervention response analysis
Rscript analysis_02_intervention_response.R

# 4. Conservation analysis
Rscript analysis_03_conservation_analysis.R

# 5. Direction-of-change analysis
Rscript analysis_04_direction_of_change.R

# 6. Leading edge gene analysis
Rscript analysis_05_leading_edge_genes.R
```

**Note**: Scripts 2-6 depend on script 1 completing first, as they analyze the enrichment results.

## Test R Installation

Run this to check if R is working:
```bash
Rscript -e "print('R is working'); sessionInfo()"
```

You should see R version info without any LAPACK errors.
