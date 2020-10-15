# input: fluxes.tsv, selected.csv
# output: heritability.tsv

library(tidyverse)

selected_jars <- read_csv('../Data/selected.csv')
fluxes <- read_tsv('../Output/fluxes.tsv')

# Pull out the selected parental jars
selected <- 
  fluxes[paste0(fluxes$passage, fluxes$jar) %in% paste0(selected_jars$passage, selected_jars$jar), ] %>%
  select(treat, estimate, passage)

# Pull out all parental jars
parental <-
  fluxes %>% 
  select(passage, treat, estimate)

# Pull out all offspring jars
offspring <- 
  fluxes %>%
  select(treat, estimate, passage) %>% 
  filter(passage != 1) %>% 
  mutate(passage = passage - 1)

# Calculate means for east generation
parental_mean <-
  parental %>% 
  group_by(passage, treat) %>% 
  summarize(parental = mean(estimate), .groups = "drop")

offspring_mean <-
  offspring %>% 
  group_by(passage, treat) %>% 
  summarize(offspring = mean(estimate), .groups = "drop")

selected_mean <-
  selected %>% 
  group_by(passage, treat) %>% 
  summarize(selected = mean(estimate), .groups = "drop")

# Combine all parent/offspring data into one data frame
heritability <- 
  parental_mean %>% 
  left_join(offspring_mean, by = c("passage", "treat")) %>% 
  left_join(selected_mean, by = c("passage", "treat")) %>% 
  #filter(treat == "p") %>% 
  filter(passage != 5) %>% # Remove passage 5, which has no offspring
  ungroup()


write_tsv(heritability, '../Output/heritability.tsv')
