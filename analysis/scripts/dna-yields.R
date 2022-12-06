library(tidyverse)
library(broom)
library(lubridate)
library(knitr)
source('R/functions.R')

qubit <- read_csv('Data/extraction_qubit.csv')
selected <- read_csv('Data/selected.csv') %>% 
  mutate(passage = as.character(passage)) %>% 
  mutate(selected = 1)

qubit <- 
  qubit %>% 
  mutate(passage = substr(sample, 2, 2)) %>% 
  mutate(treat = substr(sample, 3, 3)) %>% 
  mutate(jar = substr(sample, 3, 5)) %>% 
  left_join(selected) %>% 
  mutate(selected = as.character(if_else(is.na(selected), 0, selected))) %>% 
  mutate(sample_ugml = qubit_ngml * 200 / vol_ul)

ggplot(qubit, aes(x = selected, y = qubit_ngml)) +
  geom_boxplot() +
  geom_jitter()
ggplot(qubit, aes(x = treat, y = qubit_ngml, color = selected)) +
  geom_boxplot() +
  geom_jitter(aes(shape = passage))
qubit %>% 
  filter(treat == 'p', passage == '2') %>% 
t.test(qubit_ngml ~ selected, .)


####################

sc <- read.csv(paste0(raw_dir, 'standard_curve.csv'))
sc_dates <- read.csv(paste0(raw_dir, 'sc_dates.csv'))
time_data <- data.table::fread(paste0(raw_dir, 'time_data.csv'))
conc_data <- data.table::fread(paste0(raw_dir, 'conc_data.csv'))
selected <- read.csv(paste0(raw_dir, 'selected.csv'))

fluxes <- read_tsv(paste0(der_dir, 'fluxes.tsv'))

sc_model <- function(df) {lm(injection_ppm ~ area, data = df)}

# fit a separate model for each date
standard_curves <- 
  sc %>% 
  filter(molecule == 'co2') %>% 
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

sc_co2 <- left_join(sc_r2, sc_equation, by = c("flux_date", "sc_date"))

sc_co2 %>% 
  kable()

# These are the final slopes for each Methane~Area standard curve 
# model for each date and time point
sc_co2 <- 
  sc_co2 %>% 
  left_join(sc_dates, by = "sc_date") %>% 
  select(flux_date:sc_date, t, r.squared:slope)

conc_data <- 
  conc_data %>% 
  filter(flux_date != '2020-07-27')
time_data <- 
  time_data %>% 
  filter(flux_date != '2020-07-27')
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
conc_data <- 
  conc_data %>% 
  filter(molecule == 'co2') %>% 
  mutate(flux_date = factor(flux_date)) %>% 
  gather(t, area, t1:t5) %>% 
  left_join(sc_co2, by = c('flux_date', 't')) %>% 
  mutate(ppm = area * slope + intercept) %>% 
  select(flux_date, jar, t, ppm) %>% 
  spread(t, ppm)

lin_model <- function(dt) {
  lm(conc ~ days, data = dt)
}
co2_flux <- 
  conc_data %>% 
  pivot_longer(t1:t5, names_to = 't', values_to = 'conc') %>% 
  left_join(time_data, by = c('flux_date', 'jar', 't')) %>% 
  group_by(flux_date, jar) %>% 
  nest() %>% 
  mutate(flux = map(data, lin_model)) %>% 
  mutate(tidy = map(flux, tidy)) %>% 
  unnest(tidy) %>% 
  filter(term == 'days')

fluxes <- 
  fluxes %>% 
  mutate(jar = paste0(treat, rep)) %>% 
  select(flux_date, jar, ch4, log_ch4)

compare_fluxes <- 
  co2_flux %>% 
  select(flux_date, jar, estimate) %>% 
  mutate(flux_date = date(flux_date)) %>% 
  left_join(fluxes, by = c('flux_date', 'jar'))

compare_fluxes


compare_fluxes <- 
  compare_fluxes %>% 
  mutate(treat = substr(jar, 1, 1)) %>% 
  mutate(passage = factor(flux_date)) %>% 
  mutate(passage = as.numeric(passage))

selected$selected <- 1

compare_fluxes <- 
  compare_fluxes %>% 
  left_join(selected, by = c('passage', 'jar')) %>% 
  mutate(selected = as.character(if_else(is.na(selected), 0, selected)))
compare_fluxes %>% 
  filter(treat == 'p', passage %in% c(1,3)) %>% 
t.test(estimate ~ selected, .)
compare_fluxes %>% 
  filter(treat == 'p', passage %in% c(2)) %>% 
  t.test(estimate ~ selected, .)

ggplot(compare_fluxes, aes(x = treat, y = estimate, color = selected)) +
  geom_boxplot() +
  geom_jitter()

####################

fit <- lm(log_ch4 ~ estimate, data = compare_fluxes)

ggplot(mapping = aes(x = fitted.values(fit), y = resid(fit))) +
  geom_point()

summary(fit)

compare_fluxes %>% 
  ggplot(aes(x = passage, y = estimate, color = treat)) +
  geom_point() +
  stat_smooth(method = 'lm', formula = 'y ~ x', se = FALSE)

fit2 <- lm(estimate ~ passage * treat, data = compare_fluxes)
summary(fit2)

compare_fluxes <- 
  compare_fluxes %>% 
  mutate(selected = factor(selected))

compare_fluxes %>% 
  ggplot(aes(x = estimate, y = log_ch4, color = treat, shape = selected)) +
  geom_point()

lm(estimate ~ treat * passage, compare_fluxes) %>% 
  summary()

compare_fluxes %>% 
  ggplot(aes(x = passage, y = estimate, color = selected)) +
  geom_point() +
  facet_wrap(~ treat)