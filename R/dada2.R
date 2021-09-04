library(dada2); packageVersion("dada2")

path <- "~/MiSeq_SOP" # CHANGE ME to the directory containing the fastq files after unzipping.
list.files(path)

# Forward and reverse fastq filenames have format: SAMPLENAME_R1_001.fastq and SAMPLENAME_R2_001.fastq
fnFs <- sort(list.files(path, pattern="_R1_001.fastq", full.names = TRUE))
fnRs <- sort(list.files(path, pattern="_R2_001.fastq", full.names = TRUE))
# Extract sample names, assuming filenames have format: SAMPLENAME_XXX.fastq
sample.names <- sapply(strsplit(basename(fnFs), "_"), `[`, 1)

plotQualityProfile(fnFs[1:2])

plotQualityProfile(fnRs[1:2])

# Place filtered files in filtered/ subdirectory
filtFs <- file.path(path, "filtered", paste0(sample.names, "_F_filt.fastq.gz"))
filtRs <- file.path(path, "filtered", paste0(sample.names, "_R_filt.fastq.gz"))
names(filtFs) <- sample.names
names(filtRs) <- sample.names

out <- filterAndTrim(fnFs, filtFs, fnRs, filtRs, truncLen=c(240,160),
              maxN=0, maxEE=c(2,2), truncQ=2, rm.phix=TRUE,
              compress=TRUE, multithread=TRUE) # On Windows set multithread=FALSE
head(out)

# Learn forward error rates
errF <- learnErrors(filtFs, nbases=1e8, multithread=TRUE)

NSerrF <- learnErrors(NSfiltFs, nbases=1e8, multithread=TRUE)

NSerrF_mon <- NSerrF
NSnew_errF_out <- matrix(rep(getErrors(NSerrF_mon)[,40], length.out = 40*16), ncol = 40)

# Learn reverse error rates
errR <- learnErrors(filtRs, nbases=1e8, multithread=TRUE)
NSerrR <- learnErrors(NSfiltRs, nbases=1e8, multithread=TRUE)
NSerrR_mon <- NSerrR

# assign any value lower than the Q40 probablity to be the Q40 value
NSnew_errR_out <- getErrors(NSerrR_mon) %>%
  data.frame() %>%
  mutate_all(funs(case_when(. < X40 ~ X40,
                            . >= X40 ~ .))) %>% as.matrix()
rownames(NSnew_errR_out) <- rownames(getErrors(NSerrR_mon))
colnames(NSnew_errR_out) <- colnames(getErrors(NSerrR_mon))
NSerrR_mon$err_out <- NSnew_errR_out



#' #### Plot Error Rates

errF_plot <- plotErrors(errF, nominalQ=TRUE)
NSerrF_plot <- plotErrors(NSerrF, nominalQ=TRUE)
NSerrF_mon_plot

errF_plot
NSerrF_plot

errR_plot <- plotErrors(errR, nominalQ=TRUE)
NSerrR_plot <- plotErrors(NSerrR, nominalQ=TRUE)
NSerrR_mon_plot <- plotErrors(NSerrR_mon, nominalQ = TRUE)

errR_plot
NSerrR_plot

