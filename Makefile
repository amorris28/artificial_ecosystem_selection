
Manuscript/manuscript.docx: Manuscript/manuscript.Rmd Manuscript/reference.docx Output/fluxes.tsv Output/heritability.tsv Output/deviance.tsv
	cd $(<D);Rscript -e "rmarkdown::render('$(<F)')"

Output/heritability.tsv: R/04-heritability.R
	cd $(<D);Rscript $

R/id_taxa.R: output/lowk_fits%.rds

output/lowk_fits%.rds: R/gab_lm_model.R output/gab_adj%.tsv
	cd $(<D);R CMD BATCH $(R_OPTS) $(<F)

output/gab_adj%.tsv: R/PC_correction.R output/gab_all%.csv
	cd $(<D);R CMD BATCH $(R_OPTS) $(<F)

output/gab_all%.csv: R/gab_combine_data.R output/geodist.tsv output/gab_rare_asv_table.csv output/gab_gen_attr_table.csv output/gab_troph_attr_table.csv
	cd $(<D);R CMD BATCH $(R_OPTS) $(<F)

output/geodist.tsv: R/geodist_processing.R
	cd $(<D);R CMD BATCH $(R_OPTS) $(<F)

output/gab_troph_attr_table.csv output/gab_gen_attr_table.csv: R/gab_cleaning.R
	cd $(<D);R CMD BATCH $(R_OPTS) $(<F)

output/gab_rare_asv_table.csv: R/rarefy_asv_table.R output/gab_asv_table.csv
	cd $(<D);R CMD BATCH $(R_OPTS) $(<F)

output/gab_asv_table.csv: R/gab_clean_asvs.R
	cd $(<D);R CMD BATCH $(R_OPTS) $(<F)

clean: 
	\rm -f *.aux *.bbl *.blg *.log *.bak *.Rout */*.Rout */*.aux */*.log

cleanall:
	\rm  -f *.aux *.bbl *.blg *.log *.bak *.Rout */*.Rout */*.aux */*.log *.pdf Figures/*.pdf

clean-latex:
	cd manuscript; latexmk -C

-include *.deps
