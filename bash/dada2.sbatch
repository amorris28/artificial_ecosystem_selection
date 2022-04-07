#!/bin/bash
#SBATCH --partition=short  
#SBATCH --job-name=dada2   
#SBATCH --output=dada2.out 
#SBATCH --error=dada2.err  
#SBATCH --time=1440        
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=28
#SBATCH --mem=117G

module load miniconda
module load R/4.0.2

Rscript R/dada2.R --save

