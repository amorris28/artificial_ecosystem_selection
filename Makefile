.PHONY: manuscript
manuscript: Manuscript/manuscript.docx

Manuscript/manuscript.docx: Manuscript/manuscript.Rmd Manuscript/reference.docx Manuscript/vancouver.csl Output/fluxes.tsv Output/heritability.tsv Output/herit_model.Rdata Output/response_model.Rdata R/functions.R
	Rscript -e "rmarkdown::render('$(<F)')"

Output/richness_model_passage.Rdata Output/richness_model_treat5.Rdata Output/richness_model_ch4.Rdata R/Output/beta_model.Rdata Output/da_corncob.Rdata Output/dt_data.Rdata R/08-community.html: R/08-community.Rmd Output/phyloseq.RData R/functions.R
	Rscript -e "rmarkdown::render('$<')"

Output/phyloseq.RData R/07-generate-physeq.html: R/07-generate-physeq.Rmd Output/dada2_output.RData Output/barcode_master.tsv Output/fluxes.tsv Data/post_pcr_qubit.tsv R/functions.R
	Rscript -e "rmarkdown::render('$<')"

Output/dada2_output.RData: R/06-dada2.R
	sbatch bash/dada2.sbatch

Output/barcode_gc3f.tsv Output/barcode_master.tsv: R/05-create-barcode-key.R Data/sample_key.tsv Data/primer_sequence_key.tsv
	cd $(<D);Rscript $(<F)

Output/herit_model.Rdata R/04-heritability.html: R/04-heritability.Rmd Output/heritability.tsv R/functions.R
	Rscript -e "rmarkdown::render('$<')"

Output/response_model.Rdata R/03-response.html: R/03-response.Rmd Output/fluxes.tsv R/functions.R
	Rscript -e "rmarkdown::render('$<')"

Output/heritability.tsv R/02-process-herit.html: R/02-process-herit.Rmd Output/fluxes.tsv Data/selected.csv R/functions.R
	Rscript -e "rmarkdown::render('$<')"

Output/fluxes.tsv R/01-process-flux.html: R/01-process-flux.Rmd Data/conc_data.csv Data/sc_dates.csv Data/standard_curve.csv Data/time_data.csv Data/selected.csv R/functions.R
	Rscript -e "rmarkdown::render('$<')"

