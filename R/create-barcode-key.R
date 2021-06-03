# Script to create sample ID/barcode sequence pairs to submit to GC3F

# Takes one .tsv with Sample IDs and primer plate well positions for their
# respective primers (in the form A1, A2, ... A12)
# Takes a second table with barcode sequences and well row or column id for that
# primer (e.g., TATGGCAC  A, ATAACGCC B, ..., CTTCACTG	12)

# Outputs a "master" barcode table with the gc3f ids, my sample ids,
# and all of the barcodes and well positions
# Also outputs a table for gC3f with just the gc3f ids and the barcode
# sequences with the appropriate column headers

library(tidyverse)

sample_key <- read_tsv('../Data/sample_key.tsv')
primer_key <- read_tsv('../Data/primer_sequence_key.tsv')

sample_key %>% 
  separate(primer_well, c('row', 'col'), 1) %>%  
  left_join(primer_key, by = c('col' = 'key')) %>%
  rename(r_barcode = sequence) %>% 
  left_join(primer_key, by = c('row' = 'key')) %>% 
  rename(f_barcode = sequence) %>%
  write_tsv('../Output/barcode_master.tsv')

read_tsv('../Output/barcode_master.tsv') %>% 
  select(`Library Name / ID` = gc3f_id, 
         `Index 1 (i7) sequence` = r_barcode, 
         `Index 2 (i5) sequence` = f_barcode) %>% 
  write_tsv('../Output/barcode_gc3f.tsv')
  