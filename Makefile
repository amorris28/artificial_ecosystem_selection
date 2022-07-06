.PHONY: manuscript
manuscript: Manuscript/manuscript.docx

Manuscript/manuscript.docx: Manuscript/manuscript.Rmd Manuscript/reference.docx Manuscript/bibliography.bib Manuscript/vancouver.csl Output/fluxes.tsv Output/heritability.tsv Output/response_model.RData Output/herit_model.RData Output/richness_models.RData Output/beta_model.RData Output/da_corncob.RData R/functions.R
	Rscript -e "rmarkdown::render('$<')"

Output/richness_models.RData Output/beta_model.RData Output/beta_fig.RData Output/da_fig.RData R/08-community-analysis.html: R/08-community-analysis.Rmd Output/community_data.tsv R/functions.R
	Rscript -e "rmarkdown::render('$<')"

Output/community_data.tsv R/07-process-community.html: R/07-process-community.Rmd HPC_Output/dada2_output.RData Output/barcode_master.tsv Output/fluxes.tsv Data/post_pcr_qubit.tsv R/functions.R
	Rscript -e "rmarkdown::render('$<')"

HPC_Output/dada2_output.RData: R/06-dada2.R
	sbatch bash/dada2.sbatch

Output/barcode_gc3f.tsv Output/barcode_master.tsv: R/05-create-barcode-key.R Data/sample_key.tsv Data/primer_sequence_key.tsv
	Rscript $<

Output/herit_model.RData R/04-heritability.html: R/04-heritability.Rmd Output/heritability.tsv R/functions.R
	Rscript -e "rmarkdown::render('$<')"

Output/response_model.RData R/03-response.html: R/03-response.Rmd Output/fluxes.tsv R/functions.R
	Rscript -e "rmarkdown::render('$<')"

Output/heritability.tsv R/02-process-herit.html: R/02-process-herit.Rmd Output/fluxes.tsv Data/selected.csv R/functions.R
	Rscript -e "rmarkdown::render('$<')"

Output/fluxes.tsv R/01-process-flux.html: R/01-process-flux.Rmd Data/conc_data.csv Data/sc_dates.csv Data/standard_curve.csv Data/time_data.csv Data/selected.csv R/functions.R
	Rscript -e "rmarkdown::render('$<')"

.PHONY: clean
clean:
	$(RM) Output/*.tsv Output/*.RData R/*.html Manuscript/*.jpg Manuscript/manuscript.docx Manuscript/*.tsv
