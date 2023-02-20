# Artificial ecosystem selection reveals relationships between microbiome composition and ecosystem function

## Citation

Morris, Andrew H, Bohannan, Brendan JM. 2023. Artificial ecosystem selection reveals relationships between microbiome composition and ecosystem function. 

## Overview

This is the project directory for the manuscript entitled "Artificial
ecosystem selection reveals relationships between microbiome composition and
ecosystem function" that is currently in preparation. See the [Directories](#directories) section for an
explanation of what files are contained in each directory. See the Data
Dictionary at  `data/data_dictionary.tsv` for an explanation of the variables
in each data file.

All intermediate files needed to recreate the manuscript are included in the repository. To recreate the manuscript simply run:

```
make manuscript
```

To re-run the analyses from scratch simply run:

```
make clean
make manuscript
```

All scripts to rerun the analysis are in the `analysis` directory. Knitting the
`analysis.Rmd` will recreate the analyses in the paper. This file depends on
the scripts in `analysis/scripts`. These are numbered and can be run in order
to recreate the intermediate data files. Most scripts should be able to run on
a standard laptop/desktop computer with the exception of the script
`04-dada2.R` which should be run on a computing cluster. An example slurm batch
script to run this file is at `analysis/scripts/dada2.sbatch`, which may need
to be modified for your computing environment. The `dada2` scripts expect a
machine with 28 cores and 117 GB of ram.

If you would like to use the exact same versions of `R` packages as I have
used, there is an `renv` directory containing the lockfile. You can run
`renv::restore` to install these package versions into your local `renv`
library for this project. Depending on your machine, you may have to install a
lot of dependencies. If you're not familiar with the `renv` package, an
overview can be found [here](https://rstudio.github.io/renv/).

## Data

All metadata are included in the `data/` directory of this repository.

The 16S rRNA sequencing data generated during the current study are available in the NCBI Sequence Read Archive (SRA) under BioProject accession number PRJNA832314, https://www.ncbi.nlm.nih.gov/sra/PRJNA832314.

The Silva taxonomic database version that we used to assign taxonomy with DADA2 can be downloaded from Zenodo [here](https://zenodo.org/record/4587955).

Or you can download it from the command line by using `curl`:

```
curl https://zenodo.org/record/4587955/files/silva_species_assignment_v138.1.fa.gz --output tax/silva_species_assignment_v138.1.fa.gz
curl https://zenodo.org/record/4587955/files/silva_nr99_v138.1_train_set.fa.gz --output tax/silva_nr99_v138.1_train_set.fa.gzj
```

## Directories

|Directory|Description|
|-|-|
|data/|Contains raw data. Should never be modified.|
|analysis/|Contains analysis files and derived data.|
|analysis/output/|Derived data that has been modified by scripts.|
|analysis/scripts/|R and Bash scripts that run.|
|analysis/hpc_output/|Output from DADA2. Preserved in a separate folder so it will not be deleted by `make clean`.|
|R/|Contains custom R functions.|
|manuscript/|Contains .Rmd source code for the manuscript, a reference.docx containing formatting, references in a .bib, and the vancouver CSL citation style file.|
|renv/|Directory containing renv lockfile with the R version and package versions used in the analysis.|




 - data/ - Contains raw data. Should never be modified.
 - analysis/ - Contains analysis files and derived data.
 - analysis/output/ - Derived data that has been modified by scripts.
 - analysis/scripts/ - R and Bash scripts that run.
 - analysis/hpc_output/ - Output from DADA2. Preserved in a separate folder so it will not be deleted by `make clean`.
 - R/ - Contains custom R functions.
 - manuscript/ - Contains .Rmd source code for the manuscript, a reference.docx containing formatting, references in a .bib, and the vancouver CSL citation style file.
 - renv/ - Directory containing renv lockfile with the R version and package versions used in the analysis.
