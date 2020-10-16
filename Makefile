.PHONY: manuscript
manuscript: Manuscript/manuscript.docx

Manuscript/manuscript.docx: Manuscript/manuscript.Rmd Manuscript/reference.docx Output/fluxes.tsv Output/heritability.tsv Output/deviance.tsv Output/dev_fit.rds Output/response.rds
	cd $(<D);Rscript -e "rmarkdown::render('$(<F)')"

Output/deviance.tsv: R/03-response.R Output/fluxes.tsv
	cd $(<D);Rscript $(<F)

Output/heritability.tsv: R/02-process-herit.R Output/fluxes.tsv Data/selected.csv
	cd $(<D);Rscript $(<F)

Output/fluxes.tsv: R/01-process-flux.R Data/conc_data.csv Data/sc_dates.csv Data/standard_curve.csv Data/time_data.csv
	cd $(<D);Rscript $(<F)

clean:
	\rm -f *.pdf *.html *.docx Output/*
