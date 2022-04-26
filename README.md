# Artificial ecosystem selection reveals relationships between microbiome composition and ecosystem function

## Citation

Morris, Andrew H, Bohannan, Brendan JM. 2022. Artificial ecosystem selection reveals relationships between microbiome composition and ecosystem function. 

## Overview

This is the project directory for the manuscript entitled "Artificial
ecosystem selection reveals relationships between microbiome composition and
ecosystem function" that is currently in preparation. See the [Directories](#directories) section for an
explanation of what files are contained in each directory. See the Data
Dictionary at  `Data/data_dictionary.tsv` for an explanation of the variables
in each data file.

Simply running `make` in the root directory will produce the final manuscript
in `docx` format in the `Manuscript/` directory. By default, the manuscript and
all of the derived data files are preserved so this should not run anything. If
you choose to rerun the analysis, the scripts in `R/` are numbered and can be
run in order as outlined in the Makefile. Most scripts should be able to run on
a standard laptop/desktop computer with the exception of the script
`R/06-dada2.R` which should be run on a computing cluster. An example slurm
batch script to run this file is at `bash/dada2.sbatch`, which may need to be
modified for your computing environment. The `dada2` scripts expect a machine
with 28 cores and 117 GB of ram.

If you would like to use the exact same versions of `R` packages as I have
used, there is an `renv` directory containing the lockfile. You can run
`renv::restore` to install these package versions into your local `renv`
library for this project. Depending on your machine, you may have to install a
lot of dependencies. If you're not familiar with the `renv` package, an
overview can be found [here](https://rstudio.github.io/renv/).

Use the following commands to download the specific version of the Silva database that we used in the manuscript to assign taxonomy with DADA2.

```
curl https://zenodo.org/record/4587955/files/silva_species_assignment_v138.1.fa.gz --output tax/silva_species_assignment_v138.1.fa.gz

curl https://zenodo.org/record/4587955/files/silva_nr99_v138.1_train_set.fa.gz --output tax/silva_nr99_v138.1_train_set.fa.gzj
```

## Directories

 - Data/ - Contains raw data. Should never be modified.
 - Output/ - Derived data that has been modified by scripts.
 - HPC_Output/ - Derived data from high-performing computing cluster. (Just the DADA2 output.)
 - bash/ - Bash scripts that run.
 - R/ - R scripts that run and a file with custom functions.
 - Manuscript/ - Contains .Rmd source code for the manuscript, a reference.docx containing formatting, references in a .bib, and the vancouver CSL citation style file.
 - renv/ - Directory containing renv lockfile with the R version and package versions used in the analysis.
