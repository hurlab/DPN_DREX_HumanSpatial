#!/usr/bin/env Rscript
# Install missing dependencies for richR

if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}

# Install required Bioconductor packages
BiocManager::install(c("GO.db", "KEGG.db", "reactome.db"), ask = FALSE, update = FALSE)

message("Dependencies installed successfully!")
