
# This script takes in the flux data from script 01 and the data on which jars
# were selected in each passage. It then aligns these data so that for each
# passage there is a mean flux for all parents, the selected parents, and all
# offspring.

library(tidyverse)
library(knitr)

source('R/functions.R')

# import data

selected_jars <- read_csv(paste0(raw_dir, 'selected.csv'))
fluxes <- read_tsv(paste0(der_dir, 'fluxes.tsv'))

## Organize parent/offspring values

# Pull out the selected parental jars
selected <- 
  fluxes %>% 
  filter(selected) %>% 
  select(passage, treat, log_ch4)

# Pull out all parental jars
parental <-
  fluxes %>% 
  select(passage, treat, log_ch4)

# Pull out all offspring jars
# The `passage - 1` function sets the value of generation `n + 1` 
# as the "offspring" value for generation `n`. 
offspring <- 
  fluxes %>%
  select(treat, log_ch4, passage) %>% 
  filter(passage != 1) %>% 
  mutate(passage = passage - 1)

# Calculate means within each generation for all parental jars,
# all offspring jars, and all selected parental jars
parental_mean <-
  parental %>% 
  group_by(passage, treat) %>% 
  summarize(parental = mean(log_ch4), .groups = "drop")

offspring_mean <-
  offspring %>% 
  group_by(passage, treat) %>% 
  summarize(offspring = mean(log_ch4), .groups = "drop")

selected_mean <-
  selected %>% 
  group_by(passage, treat) %>% 
  summarize(selected = mean(log_ch4), .groups = "drop")

# Combine all parent/offspring data into one data frame
heritability <- 
  parental_mean %>% 
  left_join(offspring_mean, by = c("passage", "treat")) %>% 
  left_join(selected_mean, by = c("passage", "treat")) %>% 
  #filter(treat == "p") %>% 
  filter(passage != 5) %>% # Remove passage 5, which has no offspring,
  # because it's the last generation
  ungroup()



offspring_each <- 
  offspring %>% 
  group_by(passage, treat) %>% 
  mutate(offspring = log_ch4)

heritability_each <- 
  selected_mean %>% 
  left_join(offspring_each, by = c("passage", "treat")) %>% 
  filter(passage != 5) %>% # Remove passage 5, which has no offspring
  ungroup()

write_tsv(heritability_each, paste0(der_dir, 'heritability_each.tsv'))


write_tsv(heritability, paste0(der_dir, 'heritability.tsv'))
