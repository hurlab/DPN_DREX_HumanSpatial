if (!require("BiocManager", quietly = TRUE)) install.packages("BiocManager", quiet=TRUE)
if (!require("reactome.db", quietly = TRUE)) BiocManager::install("reactome.db", dependencies = TRUE, ask = FALSE)
if (!require("org.Hs.eg.db", quietly = TRUE)) BiocManager::install("org.Hs.eg.db", dependencies = TRUE, ask = FALSE)
if (!require("igraph", quietly = TRUE)) install.packages("igraph")
if (!require("ggplot2", quietly = TRUE)) install.packages("ggplot2")
if (!require("devtools", quietly = TRUE)) install.packages("devtools")
if (!require("richR", quietly = TRUE)) devtools::install_github("guokai8/richR")

# ---------------------------------------------------
# Step #1: set some parameters
# ---------------------------------------------------


outputdir = "output/"        # directory to save output files
dir.create(paste(dirname(current_path),outputdir,sep="/"), showWarnings = FALSE)
filebase  = "RegenDegen"     # base file name
top       = 25               # number of top significant terms to be included in the output


## Gene ontology using GO.db
hsa_go <- buildAnnot(species="human", keytype="SYMBOL", anntype = "GO")

## KEGG pathway using KEGG.db (public version; depricated)
hsa_ko <- buildAnnot(species="human", keytype="SYMBOL", anntype = "KEGG", builtin = FALSE)

## Reactome pathway database
hsa_ro <- buildAnnot(species="human", keytype="SYMBOL", anntype = "Reactome")


# Load the example data
dat <- read.table ("../allResultRegen.Degen.txt", header=T, sep="\t")
colnames(dat)[1] <- "gene"
dat.sig <- dat[which(dat$padj<0.05),]
head(dat.sig)

# ----------------------------------------------------
# Gene Ontology analysis
# ----------------------------------------------------

## minimal paraters
GO.res <- richGO(dat.sig$gene, godata=hsa_go, ontology ="BP")
head(GO.res)

## additional parameters
GO.res <- richGO(dat.sig$gene, godata=hsa_go, ontology ="BP", 
              pvalue = 0.05, padj = 0.10, minSize = 2, maxSize = 500, 
              keepRich = TRUE, filename=paste0(outputdir,filebase,".GO.out"), 
              padj.method="BH", sep=", ")

GO.sig <- filter(GO.res, Padj<0.05)
write.csv (GO.sig, file=paste0(outputdir, filebase, "_GO.csv"))

# Bar plot of top enrichment terms

## minimal parameter
ggbar(GO.sig, top = 20, usePadj = T)
ggbar(GO.sig, top = 20, usePadj = T, horiz=F) + ylab("% in genome") + ggtitle("Enrichment analysis")

## This part may not work in Rmarkdown
## if it doesn't, try to open a device first before creating the image
## pdf(paste0(outputdir,filebase,"_GO-bar_Top20.pdf")) and 
## then dev.off() once graph is created.
dev.copy(pdf, paste0(outputdir,filebase,"_GO-bar_Top20.pdf"))
dev.off()

## alternative use ggsave
ggsave(paste0(outputdir,filebase,"_GO-bar_Top20.pdf"))

## additional parameters
ggbar(GO.sig, top = top, order = FALSE, fontsize.x = 10, fontsize.y = 10, usePadj = TRUE, 
      filename = paste0(outputdir,filebase,"_GO-bar_Top",top,".pdf"), width=10, height=8) 
## PDF file is automatically created and saved  


# dot plot of top enrichment terms
## minimal parameter
ggdot(GO.sig, top = 20, usePadj = T)
dev.copy(pdf, paste0(outputdir,filebase,"_GO-dot_Top20.pdf"))
dev.off()

## additional parameters
ggdot(GO.sig, top = top, pvalue = 0.05, 
      order = FALSE, fontsize.x = 10, fontsize.y = 10, usePadj = TRUE, 
      filename = paste0(outputdir,filebase,"_GO-dot_Top",top,".pdf"),
            width=10, height=8) 
## PDF file is automatically created and saved  


# ----------------------------------------------------
# KEGG analysis
# ----------------------------------------------------
# Same as the above GO analysis



## minimal paraters
## Note that you use builtin=FALSE here as well
KEGG.res <- richKEGG(dat.sig$gene, kodata=hsa_ko, pvalue=0.05, builtin = FALSE)
head(KEGG.res)

KEGG.sig <- filter(KEGG.res, Padj < 0.05)
write.csv (KEGG.sig, file=paste0(outputdir, filebase, "_KEGG.csv"))

ggdot(KEGG.sig,top=10,usePadj = F)
ggbar(KEGG.sig,top=10,usePadj = F)


