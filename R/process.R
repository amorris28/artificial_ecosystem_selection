
library(tidyverse)
library(knitr)
library(kableExtra)
library(broom)
library(modelr)
library(lubridate)
library(morris)
library(magrittr)
library(metafor)


# Standard Curves

# Standard curves for each sc_date. (Some flux_dates have multiple standard curves if the instrument drifted from day to day as indicated by check standards.)

sc <- read.csv('Data/standard_curve.csv')
sc_dates <- read.csv('Data/sc_dates.csv')

sc %>% 
  filter(molecule == 'ch4') %>% 
  ggplot(mapping = aes(area, injection_ppm)) +
  facet_wrap(~ sc_date + molecule, scales = "free") + 
  geom_point() +
  stat_smooth(formula = y ~ x, method = 'lm', se = FALSE)

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
sc_ch4 %>% 
  kable() %>% 
  kable_styling()

sc_ch4 <- 
  sc_ch4 %>% 
  left_join(sc_dates, by = "sc_date") %>% 
  select(flux_date:sc_date, t, r.squared:slope)

# Fluxes

## Each column is jar by number (the jar numbers are arbitrary - there is no relationship between the communities of jar 01, passage 1 and jar 01, passage 2). Rows are each selection treatment (positive = p, neutral = n) within each passage (indicated by the date flux was measured). Lines are proportion of ppm CH4 consumed per day.

time_data <- data.table::fread('Data/time_data.csv')

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


conc_data <- data.table::fread('Data/conc_data.csv')


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


flux_data %>% 
  ggplot(aes(days, ppm)) + 
  facet_grid(flux_date + treat ~ rep, scales = "free") +
  geom_point() + 
  stat_smooth(method = 'lm', formula = y ~ x)


flux_data[flux_data$flux_date == "2020-07-27", ] %>% 
  ggplot(mapping = aes(days, ppm)) +
  facet_wrap(~ treat + jar, scales = "free") +
  geom_point()



## Histograms and boxplots of flux estimates for each jar within each treatment. The numbered points give an indication of which jars were the greatest methane consumers

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
  mutate(estimate_rank = rank(estimate))

write_tsv(fluxes, 'Output/fluxes.tsv')


ggplot(fluxes, aes(x = estimate, fill = treat)) +
  facet_wrap(~ flux_date, scales = "free") +
  geom_histogram(position = 'identity', alpha = 0.5, bins = 20)

ggplot(fluxes, aes(y = estimate, x = treat, color = treat)) +
  facet_wrap(~ flux_date, scales = "free") +
  geom_boxplot(outlier.shape = NA) +
  geom_label(aes(label = rep))


# Response to Selection

fluxes$passage <- as.numeric(fluxes$flux_date)

# Deviance from mean

deviance_se <- 
  fluxes %>% 
  select(treat, passage, estimate) %>% 
  group_by(passage, treat) %>% 
  summarize(se = se(estimate), .groups = "drop") %>% 
  pivot_wider(names_from = treat, values_from = se) %>% 
  mutate(deviance_se = p + n) %>% 
  pull(deviance_se)


deviance <-
  fluxes %>% 
  select(treat, passage, estimate) %>% 
  group_by(passage, treat) %>% 
  summarize(mean = mean(estimate), .groups = "drop") %>% 
  pivot_wider(names_from = treat, values_from = mean) %>% 
  mutate(deviance = p - n)

deviance$se <- deviance_se



fit <- rma(deviance~passage,se^2,method="FE",data = deviance)

ggplot(deviance, aes(x = passage, y = deviance, ymin = deviance - se, ymax = deviance + se)) + 
  geom_pointrange(color = 'darkorange2') + 
  geom_abline(intercept = fit$beta[1], slope = fit$beta[2], color = 'blue')

rma_output <- data.frame(
  Estimate = fit$beta,
  se = fit$se,
  z.value = fit$zval,
  p.value = fit$pval,
  upper.ci = fit$ci.lb,
  lower.ci = fit$ci.ub
)
rma_output %>% 
  kable() %>% 
  kable_styling()


# Heritability

selected_jars <- read_csv('Data/selected.csv')

parental <- 
  fluxes[paste0(fluxes$passage, fluxes$jar) %in% paste0(selected_jars$passage, selected_jars$jar), ] %>% 
  ungroup() %>% 
  select(treat, rep, estimate, passage)

parental <-
  parental %>% 
  group_by(passage, treat) %>% 
  summarize(parental = mean(estimate), .groups = "drop")

offspring <- 
  fluxes %>% 
  ungroup() %>%
  select(treat, rep, estimate, passage)

ggplot(offspring, aes(x = estimate, fill = factor(passage))) +
  geom_histogram(position = "identity", alpha = 0.5)

offspring <-
  offspring %>% 
  group_by(passage, treat) %>%
  summarize(offspring = mean(estimate), .groups = "drop") %>%
  # mutate(offspring = estimate) %>%
  filter(passage != 1) %>% 
  mutate(passage = passage - 1)


# offspring <-
#   fluxes %>%
#   ungroup() %>%
#   select(estimate, passage, treat) %>%
#   mutate(offspring = rank(estimate))

heritability <- left_join(parental, offspring, by = c("passage", "treat"))
heritability$passage <- factor(heritability$passage)
heritability$treat <- factor(heritability$treat)
# heritability$parental <- rank(heritability$parental)

write_tsv(heritability, 'Output/heritability.tsv')

ggplot(heritability, aes(x = parental, y = offspring)) +
  geom_point(aes(color = treat)) +
  stat_smooth(method = 'lm') + 
  labs(x = "Parental Median Flux (-k)", y = "Offspring Flux (-k)") +
  scale_color_discrete(name = "Selection\nTreatment", labels = c('Neutral', 'Positive')) +
  theme_bw()

ggsave('heritability.pdf', width = 4, height = 3)
ggsave('heritability.png', width = 4, height = 3)


heritability$parental_sq <- heritability$parental^2
fit <- lm(sqrt(offspring) ~ parental, data = heritability)

summary(fit)
tidy(fit) %>% 
  kable() %>% 
  kable_styling()
glance(fit) %>% 
  kable() %>% 
  kable_styling()
ggplot(mapping = aes(fit$residuals, fit$fitted.values)) +
  geom_point()
ggplot(mapping = aes(fit$residuals, heritability$parental)) +
  geom_point()


ggplot(heritability, aes(x = parental, y = offspring)) +
  geom_point()


ggplot(heritability, aes(x = offspring)) +
  geom_histogram(position = 'identity', alpha = 0.5)

ggplot(heritability, aes(x = parental)) +
  geom_histogram(position = 'identity', alpha = 0.5)


