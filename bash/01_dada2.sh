#!/bin/bash
#SBATCH --partition=short       ### queue to submit to
#SBATCH --job-name=dada2      ### job name
#SBATCH --output=dada2.out   ### file in which to store job stdout
#SBATCH --error=dada2.err    ### file in which to store job stderr
#SBATCH --time=1440                ### wall-clock time limit, in minutes
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=28
#SBATCH --mem=117G
#SBATCH -A crobe
#SBATCH --mail-user=andrewmorris@mailbox.org
#SBATCH --mail-type=ALL
module load miniconda
module load R/4.0.2

Rscript R/dada2.R --save

