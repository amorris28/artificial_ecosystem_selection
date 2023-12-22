#!/bin/bash

picrust2_pipeline.py -s analysis/output/refseqs.fna -i analysis/output/asv.biom -o analysis/output/picrust2_out_pipeline -p 3
add_descriptions.py -i analysis/output/picrust2_out_pipeline/pathways_out/path_abun_unstrat.tsv.gz -m METACYC \
                    -o analysis/output/picrust2_out_pipeline/pathways_out/path_abun_unstrat_descrip.tsv.gz