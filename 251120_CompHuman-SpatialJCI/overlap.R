# #################################################################################
# # # Function to calculate overlap significance using permutation test
# #################################################################################
# calculate_overlap_significance <- function(gene_set1, gene_set2, background,
#                                            n_perm = 10000, seed = 123) {
#   set.seed(seed)
#   
#   if (is.data.frame(background)) {
#     all_genes <- unique(background$external_gene_name)
#   } else {
#     all_genes <- unique(background)
#   }
#   all_genes <- all_genes[all_genes != ""]
#   
#   gene_set1_bg <- intersect(gene_set1, all_genes)
#   gene_set2_bg <- intersect(gene_set2, all_genes)
#   n1 <- length(gene_set1); n2 <- length(gene_set2)
#   if (length(gene_set1_bg) == 0 || length(gene_set2_bg) == 0)
#     stop("One or both gene sets have no overlap with the background.")
#   
#   observed <- length(intersect(gene_set1, gene_set2))
#   nulls <- replicate(n_perm, {
#     r1 <- sample(all_genes, n1)
#     r2 <- sample(all_genes, n2)
#     length(intersect(r1, r2))
#   })
#   mean_null <- mean(nulls); sd_null <- sd(nulls)
#   z <- (observed - mean_null) / sd_null
#   p <- sum(nulls >= observed) / n_perm
#   
#   list(observed_overlap = observed, expected_mean = mean_null,
#        expected_sd = sd_null, z_score = z, p_value = p,
#        null_distribution = nulls)
# }
# 
# 
# #################################################################################
# 
# # Define DEG and DMG sets
# DEG_KI <- rownames(DBKIAdv.RNA)
# DEG_KA <- rownames(DBKAAdv.RNA)
# DMG_KI <- unique(DBKIAdv.RRBS.25.average.abs$external_gene_name)
# DMG_KA <- unique(DBKAAdv.RRBS.25.average.abs$external_gene_name)
# 
# # Clean up any empty strings
# DMG_KI <- DMG_KI[DMG_KI != ""]
# DMG_KA <- DMG_KA[DMG_KA != ""]
# 
# ## Significance analysis: KI vs KA DEGs
# sig_DEG_KI_KA <- calculate_overlap_significance(DEG_KI, DEG_KA, background = ensembl.gene)
# print(sig_DEG_KI_KA[c("observed_overlap", "z_score", "p_value")])
# 
# ## Significance analysis: KI vs KA DMGs
# sig_DMG_KI_KA <- calculate_overlap_significance(DMG_KI, DMG_KA, background = ensembl.gene)
# print(sig_DMG_KI_KA[c("observed_overlap", "z_score", "p_value")])
# 
# ## Significance analysis: DEG vs DMG in KI
# sig_DEGvsDMG_KI <- calculate_overlap_significance(DEG_KI, DMG_KI, background = all_protein_coding_genes)
# print(sig_DEGvsDMG_KI[c("observed_overlap", "z_score", "p_value")])
# 
# ## Significance analysis: DEG vs DMG in KA
# sig_DEGvsDMG_KA <- calculate_overlap_significance(DEG_KA, DMG_KA, background = ensembl.gene)
# print(sig_DEGvsDMG_KA[c("observed_overlap", "z_score", "p_value")])
# 
# ## Significance analysis: Shared DEGs vs Shared DMGs
# shared_DEGs <- intersect(DEG_KI, DEG_KA)
# shared_DMGs <- intersect(DMG_KI, DMG_KA)
# sig_shared_DEGvsDMG <- calculate_overlap_significance(shared_DEGs, shared_DMGs, background = ensembl.gene)
# print(sig_shared_DEGvsDMG[c("observed_overlap", "z_score", "p_value")])
# 
# 
# overlap_summary <- data.frame(
#   Comparison = c("KI vs KA DEGs", "KI vs KA DMGs", "DEG vs DMG in KI",
#                  "DEG vs DMG in KA", "Shared DEGs vs Shared DMGs"),
#   Set1_Size = c(length(DEG_KI), length(DMG_KI), length(DEG_KI),
#                 length(DEG_KA), length(shared_DEGs)),
#   Set2_Size = c(length(DEG_KA), length(DMG_KA), length(DMG_KI),
#                 length(DMG_KA), length(shared_DMGs)),
#   Overlap = c(sig_DEG_KI_KA$observed_overlap, sig_DMG_KI_KA$observed_overlap,
#               sig_DEGvsDMG_KI$observed_overlap, sig_DEGvsDMG_KA$observed_overlap,
#               sig_shared_DEGvsDMG$observed_overlap),
#   Z_score = round(c(sig_DEG_KI_KA$z_score, sig_DMG_KI_KA$z_score,
#                     sig_DEGvsDMG_KI$z_score, sig_DEGvsDMG_KA$z_score,
#                     sig_shared_DEGvsDMG$z_score), 2),
#   P_value = signif(c(sig_DEG_KI_KA$p_value, sig_DMG_KI_KA$p_value,
#                      sig_DEGvsDMG_KI$p_value, sig_DEGvsDMG_KA$p_value,
#                      sig_shared_DEGvsDMG$p_value), 3)
# )
# 
# print(overlap_summary)
# write.csv(overlap_summary, file = file.path(output_dir, "Overlap_Significance_Summary.csv"), 
#           row.names = FALSE)
# 
