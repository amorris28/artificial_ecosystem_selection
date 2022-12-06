library(devtools)

# Install specific commit/version from github
install_github("amorris28/morris", dependencies = FALSE)
install_github("kbroman/broman", dependencies = FALSE)
install_github("FrederickHuangLin/ANCOMBC", dependencies = FALSE)

# if (!requireNamespace("BiocManager", quietly = TRUE))
#   install.packages("BiocManager")

renv::install("bioc::ALDEx2")
renv::install("bioc::phyloseq")
renv::install("bioc::ANCOMBC")
renv::install("bioc::dada2")
renv::install("bioc::decontam")

