.PHONY: analysis
analysis: analysis.html

analysis.html: analysis.Rmd output/fluxes.tsv output/heritability.tsv output/community_data.tsv
	Rscript -e "rmarkdown::render('$<', knit_root_dir = '..')"

output/community_data.tsv: scripts/05-combine-asvs-and-fluxes.R output/fluxes.tsv output/dada2_output.RData output/barcode_master.tsv ../data/post_pcr_qubit.tsv
	Rscript -e "renv::run('$<')"

output/dada2_output.RData: scripts/04-create-asvs.R
	Rscript -e "renv::run('$<')"

output/barcode_master.tsv: scripts/03-create-barcode-key.R
	Rscript -e "renv::run('$<')"

output/heritability.tsv: scripts/02-process-herit.R
	Rscript -e "renv::run('$<')"

output/fluxes.tsv: scripts/01-calculate-flux.R
	Rscript -e "renv::run('$<')"
	
.PHONY: clean
clean:
	$(RM) output/*.tsv output/*.RData output/*.rds *.html figs/*.jpg
