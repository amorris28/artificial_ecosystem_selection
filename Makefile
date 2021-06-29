.PHONY: manuscript
manuscript: Manuscript/manuscript.docx

.PHONY: presentation
presentation: Presentation/presentation.html

Manuscript/manuscript.docx: Manuscript/manuscript.Rmd Manuscript/reference.docx Output/fluxes.tsv Output/heritability.tsv Output/herit_model.Rdata Output/response_model.Rdata R/functions.R
	cd $(<D);Rscript -e "rmarkdown::render('$(<F)')"

Presentation/presentation.html: Presentation/presentation.Rmd Output/fluxes.tsv Output/heritability.tsv Output/herit_model.Rdata Output/response_model.Rdata
	cd $(<D);Rscript -e "rmarkdown::render('$(<F)')"

Output/herit_model.Rdata R/04-heritability.html: R/04-heritability.Rmd Output/heritability.tsv R/functions.R
	cd $(<D);Rscript -e "rmarkdown::render('$(<F)')"

Output/response_model.Rdata R/03-response.html: R/03-response.Rmd Output/fluxes.tsv R/functions.R
	cd $(<D);Rscript -e "rmarkdown::render('$(<F)')"

Output/heritability.tsv R/02-process-herit.html: R/02-process-herit.Rmd Output/fluxes.tsv Data/selected.csv R/functions.R
	cd $(<D);Rscript -e "rmarkdown::render('$(<F)')"

Output/fluxes.tsv R/01-process-flux.html: R/01-process-flux.Rmd Data/conc_data.csv Data/sc_dates.csv Data/standard_curve.csv Data/time_data.csv Data/selected.csv R/functions.R
	cd $(<D);Rscript -e "rmarkdown::render('$(<F)')"
	
Output/barcode_master.tsv Output/barcode_gc3f.tsv: R/create-barcode-key.R Data/sample_key.tsv Data/primer_sequence_key.tsv
	cd $(<D);Rscript $(<F)
