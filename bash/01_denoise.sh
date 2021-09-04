#!/bin/bash
#SBATCH --partition=short       ### queue to submit to
#SBATCH --job-name=denoise-paired      ### job name
#SBATCH --output=denoise-paired.out   ### file in which to store job stdout
#SBATCH --error=denoise-paired.err    ### file in which to store job stderr
#SBATCH --time=120                ### wall-clock time limit, in minutes
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH -A crobe
#SBATCH --mail-user=amorris28@gmail.com
#SBATCH --mail-type=ALL
module load miniconda
conda activate qiime2-2019.10
qiime dada2 denoise-paired \
	--i-demultiplexed-seqs gabon-demux.qza \
	--p-trim-left-f 0 \
	--p-trim-left-r 6 \
	--p-trunc-len-f 275 \
	--p-trunc-len-r 116 \
	--o-table paired-table.qza \
	--o-representative-sequences paired-rep-seqs.qza \
	--o-denoising-stats paired-denoising-stats.qza \
	--p-n-threads 4
