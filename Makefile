
.PHONY: manuscript
manuscript: manuscript/manuscript.docx

.PHONY: analysis
analysis: analysis/analysis.html

manuscript/manuscript.docx: manuscript/manuscript.Rmd manuscript/reference.docx manuscript/bibliography.bib manuscript/vancouver.csl analysis/output/models.RData R/functions.R
	Rscript -e "rmarkdown::render('$<')"

analysis/output/models.RData analysis/analysis.html: analysis/analysis.Rmd analysis/output/community_data.tsv R/functions.R
	Rscript -e "rmarkdown::render('$<')"

analysis/output/community_data.tsv: analysis/scripts/05-combine-asvs-and-fluxes.R analysis/hpc_output/dada2_output.RData analysis/output/barcode_master.tsv analysis/output/fluxes.tsv data/post_pcr_qubit.tsv R/functions.R
	Rscript $<

## Only run on high-performance computing cluster
#analysis/hpc_output/dada2_output.RData: analysis/scripts/04-dada2.R
#	sbatch analysis/scripts/dada2.sbatch

analysis/output/barcode_gc3f.tsv analysis/output/barcode_master.tsv: analysis/scripts/03-create-barcode-key.R data/sample_key.tsv data/primer_sequence_key.tsv
	Rscript $<

analysis/output/heritability.tsv: analysis/scripts/02-process-herit.R analysis/output/fluxes.tsv data/selected.csv R/functions.R
	Rscript $<

analysis/output/fluxes.tsv: analysis/scripts/01-calculate-flux.R data/conc_data.csv data/sc_dates.csv data/standard_curve.csv data/time_data.csv data/selected.csv R/functions.R
	Rscript $<

.PHONY: clean
clean:
	$(RM) analysis/output/*.tsv analysis/output/*.RData analysis/output/*.rds analysis/analysis.html manuscript/manuscript.docx
