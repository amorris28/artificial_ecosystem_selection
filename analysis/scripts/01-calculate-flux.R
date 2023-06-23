
# This script processes the standard curve data from the gas chromatograph on
# each sample date. It then converts area-under-the-curve to methane
# concentration using the standard curves for every sample. Finally, it computes
# fluxes (change in concentration over time) as a first-order exponential decay
# function.

library(tidyverse)
library(broom)
library(lubridate)
source('R/functions.R')

# import_data
sc <- read.csv(paste0(raw_dir, 'standard_curve.csv'))
sc_dates <- read.csv(paste0(raw_dir, 'sc_dates.csv'))
time_data <- data.table::fread(paste0(raw_dir, 'time_data.csv'))
conc_data <- data.table::fread(paste0(raw_dir, 'conc_data.csv'))
selected <- read.csv(paste0(raw_dir, 'selected.csv'))

## Standard Curves

# This step first imports the values for the standard curves then calculates the slope of Methane on Area for each sample date. On one flux date, a new standard curve was established on the second day of measurement due to drift in the check standards so t1 and t2 had a different standard curve than t3-t5. `flux_date` indicates the main sample data while `sc_date` indicates which standard curve was used on that day.

# fit a separate model for each date
sc <- 
    sc %>% 
    select(flux_date, molecule, injection_ppm, area) %>% 
    group_by(flux_date, molecule) %>% 
    nest() %>% 
    mutate(model = map(data, function(df) lm(injection_ppm ~ area, df))) %>% 
    mutate(glance = map(model, glance)) %>% 
    mutate(tidy = map(model, tidy)) %>% 
    unnest(glance) %>% 
    select(flux_date, molecule, r.squared, tidy) %>% 
    unnest(tidy) %>% 
    select(flux_date, molecule, r.squared, term, estimate) %>% 
    spread(term, estimate) %>% 
    rename(intercept = `(Intercept)`, slope = area)

## Compute Fluxes

# Converts raw data and time time interval in units `days`. The first time point, t0 is when the jars were capped and is ignored because t1 is the first sample injected into the gas chromatograph and so is the first time point with concentrations. Decay constants are calculated between t1 and t5.

# Standardize time format
time_data[, c('t0', 't1', 't2', 't3', 't4', 't5')] <- 
  lapply(time_data[, c('t0', 't1', 't2', 't3', 't4', 't5')], ymd_hms)

# Convert time to 'days'
as.days <- function(start, end) {as.numeric(interval(start, end))/60/60/24}

time_data[, c('t1', 't2', 't3', 't4', 't5')] <- 
  lapply(time_data[, c('t1', 't2', 't3', 't4', 't5')],
         function(x) as.days(time_data$t1, x))

time_data <- 
 time_data %>% 
  select(-t0) %>% 
  gather(t, days, t1:t5) %>% 
  mutate(flux_date = factor(flux_date))

# This step takes the raw gas chromatograph area data and calculates methane concentration for each time point in units of ppm using the standard curves calculated above.

ch4_conc_data <- 
  conc_data %>% 
  filter(molecule == 'ch4') %>% 
  mutate(flux_date = factor(flux_date)) %>% 
  gather(t, area, t1:t5) %>% 
  left_join(sc, by = c('flux_date', 'molecule')) %>% 
  mutate(ppm = area * slope + intercept) %>% 
  select(flux_date, jar, t, ppm) %>% 
  spread(t, ppm)

ch4_conc_data %>% 
    summarize(mean = mean(t1), sd = sd(t1))

# Finally, this step takes the time intervals and ch4 concentrations and fits a
# first-order exponential decay function to compute methane flux as `k` which is
# the rate-constant for the first-order exponential decay function. Here, I
# calculate `k` as the slope of ln(t0/tn) over time. I use t0/tn rather than
# tn/t0 so that the sign of the slope is reversed. That way a larger `k` means a
# faster oxidation rate.

ch4_conc_data[, c('t1', 't2', 't3', 't4', 't5')] <- 
  lapply(ch4_conc_data[, c('t1', 't2', 't3', 't4', 't5')],
         function(x) log(ch4_conc_data$t1/x))

ch4_flux_data <-
  ch4_conc_data %>% 
  gather(t, ppm, t1:t5) %>% 
  left_join(time_data, by = c('flux_date', 'jar', 't')) %>% 
  mutate(flux_date = factor(ymd(flux_date)), 
         jar = factor(jar),
         t = factor(t)) %>% 
  mutate(rep = factor(substr(jar, 2, 3)),
         treat = factor(substr(jar, 1, 1)))

nested <- 
  ch4_flux_data %>% 
  group_by(flux_date, jar, treat, rep) %>% 
  nest() %>% 
  mutate(model = map(data, function(df) {lm(ppm ~ days, data = df)}))

ch4_fluxes <-
  nested %>% 
  mutate(tidy = map(model, tidy)) %>% 
  unnest(tidy) %>% 
  filter(term == 'days') %>% 
  group_by(flux_date) %>% 
  arrange(estimate, .by_group = TRUE) %>% 
  select(-data, -model, -term) %>% 
  ungroup() %>% 
  mutate(passage = as.numeric(flux_date)) %>% 
  mutate(ch4 = estimate,
         rank_ch4 = rank(ch4),
         log_ch4 = log10(ch4 + abs(min(ch4)) + 0.001)) %>% 
  select(-std.error, -statistic, -p.value, -estimate)

# Identify the selected jars in the fluxes data frame
selected$selected <- TRUE
ch4_fluxes <- 
  ch4_fluxes %>% 
  left_join(selected, by = c('passage', 'jar')) %>% 
  mutate(selected = !is.na(selected)) %>% 
  select(-jar) %>% 
  select(flux_date, passage, treat, rep, ch4:selected)

# Export CH4 flux data

write_tsv(ch4_fluxes, paste0(der_dir, 'fluxes.tsv'))

# Calculate CO2 flux on the three days for which we have these data

co2_conc_data <- 
  conc_data %>% 
  filter(molecule == 'co2') %>% 
  mutate(flux_date = factor(flux_date)) %>% 
  gather(t, area, t1:t5) %>% 
  left_join(sc, by = c('flux_date', 'molecule')) %>% 
  mutate(ppm = area * slope + intercept) %>% 
  select(flux_date, jar, t, ppm) %>% 
  spread(t, ppm)

co2_fluxes <- 
    co2_conc_data %>% 
  pivot_longer(t1:t5, names_to = 't', values_to = 'ppm') %>% 
  left_join(time_data, by = c('flux_date', 'jar', 't')) %>% 
  group_by(flux_date, jar) %>% 
  nest() %>% 
  mutate(flux = map(data, function(df) lm(ppm ~ days, df))) %>% 
  mutate(tidy = map(flux, tidy)) %>% 
  unnest(tidy) %>% 
  filter(term == 'days') %>% 
    select(flux_date, jar, flux_ppmday = estimate)
 