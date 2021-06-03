.PHONY: manuscript
manuscript: Manuscript/manuscript.docx

.PHONY: presentation
presentation: Presentation/presentation.html

Manuscript/manuscript.docx: Manuscript/manuscript.Rmd Manuscript/reference.docx Output/fluxes.tsv Output/heritability.tsv Output/deviance.tsv Output/dev_fit.rds Output/response.rds
	cd $(<D);Rscript -e "rmarkdown::render('$(<F)')"

Presentation/presentation.html: Presentation/presentation.Rmd Output/fluxes.tsv Output/heritability.tsv Output/deviance.tsv Output/dev_fit.rds Output/response.rds
	cd $(<D);Rscript -e "rmarkdown::render('$(<F)')"

Output/response.rds: R/03-response.R Output/fluxes.tsv
	cd $(<D);Rscript $(<F)

Output/deviance.tsv: R/03-response.R Output/fluxes.tsv
	cd $(<D);Rscript $(<F)

Output/heritability.tsv: R/02-process-herit.R Output/fluxes.tsv Data/selected.csv
	cd $(<D);Rscript $(<F)

Output/fluxes.tsv: R/01-process-flux.R Data/conc_data.csv Data/sc_dates.csv Data/standard_curve.csv Data/time_data.csv
	cd $(<D);Rscript $(<F)
	
Output/barcode_master.tsv Output/barcode_gc3f.tsv: R/create-barcode-key.R Data/sample_key.tsv Data/primer_sequence_key.tsv
	cd $(<D);Rscript $()<F)