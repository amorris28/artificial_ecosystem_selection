.PHONY: analysis
analysis: analysis.html

analysis.html: analysis.Rmd output/fluxes.tsv
	Rscript -e "rmarkdown::render('$<', knit_root_dir = '..')"

output/fluxes.tsv: scripts/01-calculate-flux.R
	Rscript -e "renv::run('$<')"
	
output/heritability.tsv: scripts/02-process-herit.R
	Rscript $<

.PHONY: clean
clean:
	$(RM) output/*.tsv output/*.RData output/*.rds *.html figs/*.jpg
