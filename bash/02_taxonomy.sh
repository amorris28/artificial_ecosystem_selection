#!/bin/bash
#SBATCH --partition=short       ### queue to submit to
#SBATCH --job-name=tax      ### job name
#SBATCH --output=tax.out   ### file in which to store job stdout
#SBATCH --error=tax.err    ### file in which to store job stderr
#SBATCH --time=180                ### wall-clock time limit, in minutes
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=128G
#SBATCH -A crobe
#SBATCH --mail-user=amorris28@gmail.com
#SBATCH --mail-type=ALL
cd projects/Phylo_Cons_Traits/Gabon
module load miniconda
conda activate qiime2-2019.10

qiime feature-classifier classify-sklearn \
  --i-classifier silva-132-99-515-806-nb-classifier.qza \
  --i-reads rep-seqs-dn-70.qza \
  --o-classification taxonomy-dn-70.qza \
  --p-n-jobs 4
