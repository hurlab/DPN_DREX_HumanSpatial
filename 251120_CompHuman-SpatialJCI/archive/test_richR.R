#!/usr/bin/env Rscript
# Quick test to verify richR works in WSL2 environment

message("Testing richR installation...")

# Load required packages
if (!requireNamespace("richR", quietly = TRUE)) {
  stop("richR is not installed!")
}

message("✓ richR is installed")

# Test building annotations
message("\nTesting GO annotation building...")
go_annot <- NULL
tryCatch({
  go_annot <- richR::buildAnnot(species = "mouse", keytype = "SYMBOL", anntype = "GO")
  message("✓ GO annotations built successfully (", nrow(go_annot), " rows)")
}, error = function(e) {
  message("✗ Failed to build GO annotations: ", e$message)
})

message("\nTesting KEGG annotation building...")
kegg_annot <- NULL
tryCatch({
  kegg_annot <- richR::buildAnnot(species = "mouse", keytype = "SYMBOL", anntype = "KEGG", builtin = FALSE)
  message("✓ KEGG annotations built successfully (", nrow(kegg_annot), " rows)")
}, error = function(e) {
  message("✗ Failed to build KEGG annotations: ", e$message)
})

# Test enrichment with a small gene set
if (!is.null(go_annot)) {
  message("\nTesting GO enrichment with sample genes...")
  test_genes <- c("Apoe", "Ttr", "Clu", "Mbp", "Mpz", "Pmp22", "Prx", "Egr2", "Sox10", "Plp1")

  tryCatch({
    go_res <- richR::richGO(test_genes, godata = go_annot, organism = "mouse", keytype = "SYMBOL")
    if (nrow(go_res) > 0) {
      message("✓ GO enrichment successful (", nrow(go_res), " terms found)")
      message("  Top term: ", go_res$Term[1])
    } else {
      message("⚠ GO enrichment returned no results")
    }
  }, error = function(e) {
    message("✗ Failed GO enrichment: ", e$message)
  })
}

if (!is.null(kegg_annot)) {
  message("\nTesting KEGG enrichment with sample genes...")
  test_genes <- c("Apoe", "Ttr", "Clu", "Mbp", "Mpz", "Pmp22", "Prx", "Egr2", "Sox10", "Plp1")

  tryCatch({
    kegg_res <- richR::richKEGG(test_genes, kodata = kegg_annot, organism = "mouse", keytype = "SYMBOL")
    if (nrow(kegg_res) > 0) {
      message("✓ KEGG enrichment successful (", nrow(kegg_res), " pathways found)")
      message("  Top pathway: ", kegg_res$Term[1])
    } else {
      message("⚠ KEGG enrichment returned no results")
    }
  }, error = function(e) {
    message("✗ Failed KEGG enrichment: ", e$message)
  })
}

message("\n===================")
message("richR test complete!")
message("===================")
