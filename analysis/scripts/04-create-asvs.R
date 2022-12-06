library(dada2); packageVersion("dada2")
library(tidyverse)

multithread = 28

path <- "raw_seqs" # CHANGE ME to the directory containing the fastq files after unzipping.
#list.files(path)

# Forward and reverse fastq filenames have format: SAMPLENAME_R1_001.fastq and SAMPLENAME_R2_001.fastq
fnFs <- sort(list.files(path, pattern="_R1_001.fastq.gz", full.names = TRUE))
fnRs <- sort(list.files(path, pattern="_R2_001.fastq.gz", full.names = TRUE))
# Extract sample names, assuming filenames have format: SAMPLENAME_XXX.fastq
# fnFs <- fnFs[grepl('am', fnFs)]
# fnRs <- fnRs[grepl('am', fnRs)]

sample.names <- sapply(strsplit(basename(fnFs), "_"), `[`, 1)

# sample.names[grepl('am', sample.names)]
# sample.names <- sapply(strsplit(basename(fnFs), "_"), `[`, 1)
# sample.names <- sapply(strsplit(basename(fnFs), "_"), function(x) {paste(x[1:4], collapse = '')})
# sample.names[grepl('am', sample.names)] <- substr(sample.names[grepl('am', sample.names)], 1, 4)

#plotQualityProfile(fnFs[1:2])

#plotQualityProfile(fnRs[1:2])

# Place filtered files in filtered/ subdirectory
filtFs <- file.path("filtered_seqs", paste0(sample.names, "_F_filt.fastq.gz"))
filtRs <- file.path("filtered_seqs", paste0(sample.names, "_R_filt.fastq.gz"))
names(filtFs) <- sample.names
names(filtRs) <- sample.names

out <- filterAndTrim(fnFs, filtFs, fnRs, filtRs, truncLen=c(140,140),
              maxN=0, maxEE=c(2,2), truncQ=2, rm.phix=TRUE,
              compress=TRUE, multithread=multithread) # On Windows set multithread=FALSE
head(out)

# Function to fix error rates for NovaSeq data
fix_NS_error_rates <- function(error_rates) {
  err_mon <- error_rates
  
  err_out <- getErrors(error_rates) %>%
    data.frame() %>%
    mutate_all(funs(case_when(. < X40 ~ X40,
                              . >= X40 ~ .))) %>% as.matrix()
  rownames(err_out) <- rownames(getErrors(error_rates))
  colnames(err_out) <- colnames(getErrors(error_rates))
  err_mon$err_out <- err_out
  return(err_mon)
}

# Learn forward error rates
errF <- learnErrors(filtFs, nbases=1e8, multithread=multithread)

#plotErrors(errF, nominalQ=TRUE)

errF_fixed <- fix_NS_error_rates(errF)

#plotErrors(errF_fixed, nominalQ=TRUE)

# Learn reverse error rates
errR <- learnErrors(filtRs, nbases=1e8, multithread=multithread)

#plotErrors(errR, nominalQ=TRUE)

errR_fixed <- fix_NS_error_rates(errR)

#plotErrors(errR_fixed, nominalQ=TRUE)

# Sample Inference

dadaFs <- dada(filtFs, err=errF_fixed, pool = "pseudo", multithread=multithread, verbose = 1)

dadaRs <- dada(filtRs, err=errR_fixed, pool = "pseudo", multithread=multithread, verbose = 1)

# Merge paired reads

mergers <- mergePairs(dadaFs, filtFs, dadaRs, filtRs, verbose=TRUE)
head(mergers[[1]])

# Construct sequence table

seqtab <- makeSequenceTable(mergers)
dim(seqtab)

# Inspect distribution of sequence lengths
table(nchar(getSequences(seqtab)))

# Remove reads outside the expected length

seqtab2 <- seqtab[,nchar(colnames(seqtab)) %in% 250:257]

table(nchar(getSequences(seqtab2)))


# Remove chimeras

seqtab.nochim <- removeBimeraDenovo(seqtab2, method="consensus", multithread=multithread, verbose=TRUE)
dim(seqtab.nochim)

sum(seqtab.nochim)/sum(seqtab)

# Track reads through the pipeline

getN <- function(x) sum(getUniques(x))
track <- cbind(out, sapply(dadaFs, getN), sapply(dadaRs, getN), sapply(mergers, getN), rowSums(seqtab.nochim))
colnames(track) <- c("input", "filtered", "denoisedF", "denoisedR", "merged", "nochim")
rownames(track) <- sample.names
head(track)

# Assign taxonomy

taxa <- assignTaxonomy(seqtab.nochim, "tax/silva_nr99_v138.1_train_set.fa.gz", multithread=multithread)

taxa <- addSpecies(taxa, "tax/silva_species_assignment_v138.1.fa.gz")

taxa.print <- taxa # Removing sequence rownames for display only
rownames(taxa.print) <- NULL
head(taxa.print)

save(seqtab.nochim, taxa, file = "output/dada2_output.RData")

