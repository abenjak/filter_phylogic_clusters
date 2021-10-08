#!/usr/bin/env Rscript

# Filter PhylogicNDT clusters based on their size. Will fetch variants that make up small clusters. These can be used as a blacklist for a new Cluster run.

suppressPackageStartupMessages(library("optparse"))

if (!interactive()) {
    options(warn = -1, error = quote({ traceback(); q('no', status = 1) }))
}

optList <- list(
	make_option("--min_clust_size", default = 5, type = 'integer', help = "min acceptable cluster size [%default]"),
	make_option("--cancer_genes", default = NULL, type = 'character', help = "cancer gene list, no header [%default]"),
	make_option("--old_blacklist", default = NULL, type = 'character', help = "prevous blacklist file to merge with the output [%default]"),
	make_option("--outdir", default = ".", type = 'character', help = "output folder [%default]"))

parser <- OptionParser(usage = "%prog [options] [input .mut_ccfs.txt file]", option_list = optList)

arguments <- parse_args(parser, positional_arguments = T)
opt <- arguments$options


if (length(arguments$args) < 1) {
    cat("Need input .mut_ccfs.txt file\n")
    print_help(parser)
    stop()
} else {
    mutFile <- arguments$args[1]
}

paste("mut file:", mutFile)
paste("min clust size:", opt$min_clust_size)
paste("cancer genes:", opt$cancer_genes)
paste("old_blacklist:", opt$old_blacklist)
paste("output folder:", opt$outdir)



muts <- read.delim(mutFile, as.is = T)

muts <- unique(muts[c("Hugo_Symbol", "Chromosome", "Start_position", "Reference_Allele", "Tumor_Seq_Allele", "Cluster_Assignment")])

filt <- muts[which(muts$Cluster_Assignment %in% names(which(table(muts$Cluster_Assignment) < opt$min_clust_size))),]

cancer_genes <- read.delim(opt$cancer_genes, header = F, as.is = T)$V1

# exclude cancer genes from filt
filt <- filt[!(filt$Hugo_Symbol %in% cancer_genes),]
filt <- filt[c("Chromosome", "Start_position", "Reference_Allele", "Tumor_Seq_Allele")]

cat("Sample", "Variants_filtered", sep="\t")
cat("\n")
cat(sub(".mut_ccfs.txt", "", basename(mutFile)), as.character(length(row.names(filt))), sep="\t")
cat("\n")

if (is.null(opt$old_blacklist)) {
	print("no blacklist provided, skipping merging")
} else {
	old_blacklist <- read.delim(opt$old_blacklist, colClasses = c("numeric", "numeric", "character", "character")) #if whole column has "T", read.delim will convert to TRUE.
	print(paste("prepending", length(row.names(old_blacklist)), "variants from the old blacklist to the current filtered variants"))
	filt <- rbind(old_blacklist,filt)
}

# make output folder
if(dir.exists(opt$outdir)==FALSE){dir.create(opt$outdir)}

write.table(filt, file = paste0(opt$outdir,"/",sub(".mut_ccfs.txt", ".blacklist.txt", basename(mutFile))), sep = "\t", row.names = F, quote = F)
