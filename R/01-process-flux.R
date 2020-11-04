# This scripts imports the raw methane oxidation rate data as manually entered.
# This includes the date of each standard curve and the measures Areas for each
# Concentration of the standard curve. It then calculates the slope of the
# relationship Methane ~ Area for each date a standard curve was taken.
#
# Next, this script imports the time point data and concentration (Area) data
# for each jar in each passage. It then computes an exponential decay function
#
# and extracts the exponential decay rate (k).
# Input: standard_curve.csv, sc_dates.csv, time_data.csv, conc_data.csv, selected.csv
# Output: fluxes.tsv

library(tidyverse)
library(broom)
library(lubridate)

# Standard Curves

sc <- read.csv('../Data/standard_curve.csv')
sc_dates <- read.csv('../Data/sc_dates.csv')

sc_model <- function(df) {lm(injection_ppm ~ area, data = df)}
standard_curves <- 
  sc %>% 
  filter(molecule == 'ch4') %>% 
  group_by(flux_date, sc_date) %>% 
  nest() %>% 
  mutate(model = map(data, sc_model),
         glance = map(model, glance),
         tidy = map(model, tidy)) 
sc_r2 <- 
  standard_curves %>% 
  unnest(glance) %>% 
  select(flux_date, sc_date, r.squared)
sc_equation <- 
  standard_curves %>% 
  unnest(tidy) %>%
  select(flux_date, sc_date, term, estimate) %>% 
  spread(term, estimate) %>% 
  rename(intercept = `(Intercept)`, slope = area)
sc_ch4 <- left_join(sc_r2, sc_equation, by = c("flux_date", "sc_date"))

sc_ch4 <- 
  sc_ch4 %>% 
  left_join(sc_dates, by = "sc_date") %>% 
  select(flux_date:sc_date, t, r.squared:slope)


# Fluxes

time_data <- data.table::fread('../Data/time_data.csv')

time_data[, c('t0', 't1', 't2', 't3', 't4', 't5')] <- 
  lapply(time_data[, c('t0', 't1', 't2', 't3', 't4', 't5')],
         ymd_hms)

as.days <- function(start, end) {as.numeric(interval(start, end))/60/60/24}

time_data[, c('t1', 't2', 't3', 't4', 't5')] <- 
  lapply(time_data[, c('t1', 't2', 't3', 't4', 't5')],
         function(x) as.days(time_data$t1, x))
time_data <- 
 time_data %>% 
  select(-t0) %>% 
  gather(t, days, t1:t5) %>% 
  mutate(flux_date = factor(flux_date))

conc_data <- data.table::fread('../Data/conc_data.csv')

conc_data <- 
  conc_data %>% 
  filter(molecule == 'ch4') %>% 
  mutate(flux_date = factor(flux_date)) %>% 
  gather(t, area, t1:t5) %>% 
  left_join(sc_ch4, by = c('flux_date', 't')) %>% 
  mutate(ppm = area * slope + intercept) %>% 
  select(flux_date, jar, t, ppm) %>% 
  spread(t, ppm)

ln_ch0_chn <- function(t0, tn) {
  log(t0/tn)
}

conc_data[, c('t1', 't2', 't3', 't4', 't5')] <- 
  lapply(conc_data[, c('t1', 't2', 't3', 't4', 't5')],
         function(x) ln_ch0_chn(conc_data$t1, x))

flux_data <-
  conc_data %>% 
  gather(t, ppm, t1:t5) %>% 
  left_join(time_data, by = c('flux_date', 'jar', 't'))

flux_data <- 
  flux_data %>% 
  mutate(flux_date = factor(ymd(flux_date)), 
         jar = factor(jar),
         t = factor(t)) %>% 
  mutate(rep = factor(substr(jar, 2, 3)),
         treat = factor(substr(jar, 1, 1)))

#flux_data %>% 
#  ggplot(aes(days, ppm)) + 
#  facet_grid(flux_date + treat ~ rep, scales = "free") +
#  geom_point() + 
#  stat_smooth(method = 'lm', formula = y ~ x)

lin_model <- function(dt) {
  lm(ppm ~ days, data = dt)
}

nested <- 
  flux_data %>% 
  group_by(flux_date, jar, treat, rep) %>% 
  nest() %>% 
  mutate(model = map(data, lin_model))

fluxes <-
  nested %>% 
  mutate(tidy = map(model, tidy)) %>% 
  unnest(tidy) %>% 
  filter(term == 'days') %>% 
  group_by(flux_date) %>% 
  arrange(estimate, .by_group = TRUE) %>% 
  select(-data, -model, -term) %>% 
  ungroup() %>% 
  mutate(passage = as.numeric(flux_date)) %>% 
  mutate(estimate_rank = rank(estimate)) %>% 
  filter(passage != 6) %>% 
  select(-std.error, -statistic, -p.value)
write_tsv(fluxes, '../Output/fluxes.tsv')
