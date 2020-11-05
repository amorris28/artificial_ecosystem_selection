# This script intakes the flux data from script 01. It then calculates deviance
# as the difference between the positive line and the neutral line in each
# passage. The errors can either be calculated as the sum of the errors for
# each line or the standard error of difference, that is, the square root of
# the sum of the squared errors, which is slightly smaller than the sum. In
# this case, I have chosen the SED.

# input: fluxes.tsv
# output: deviance.tsv, response.rds

library(tidyverse)
library(metafor)
library(morris)
library(broom)

# Standard error of the difference function
sed <- function(p, n, na.rm = FALSE) {
  sqrt(se(p, na.rm = na.rm) ^ 2 + se(n, na.rm = na.rm)^ 2)
}


# Response to Selection

fluxes <- read_tsv('../Output/fluxes.tsv')

#####################################################################
# Okay here to deviance is how I should really be doing it
###############################################################

# 1. Plot the raw data
ratio.values <- (max(fluxes$passage)-min(fluxes$passage))/(max(fluxes$estimate)-min(fluxes$estimate))

ggplot(fluxes, aes(x = passage, y = estimate, color = treat)) +
  theme_classic() +
  geom_jitter(width = 0.1) +
  stat_smooth(method = 'lm', se = FALSE, formula = 'y ~ x') +
#  coord_fixed(ratio.values) +
  labs(x = "Passage Number", y = "Methane Oxidation Rate (-k)") +
  scale_color_manual(name = "Treatment", labels = c('Neutral', 'Positive'), values = c('gray40', 'darkorange2'))

ggsave('fluxes_raw.pdf', width = 5, height = 4)

# 2. Transform it to make it more normal

# 3. Plot the transformed data

ratio.values <- (max(fluxes$passage)-min(fluxes$passage))/(max(fluxes$estimate_log10)-min(fluxes$estimate_log10))

ggplot(fluxes, aes(x = passage, y = estimate_log10, color = treat)) +
  theme_classic() +
  geom_jitter(width = 0.1) +
  stat_smooth(method = 'lm', se = FALSE, formula = 'y ~ x') +
#  coord_fixed(ratio.values) +
  labs(x = "Passage Number", y = "log10(Methane Oxidation Rate (-k))") +
  scale_color_manual(name = "Treatment", labels = c('Neutral', 'Positive'), values = c('gray40', 'darkorange2'))

ggsave('fluxes_log.pdf', width = 5, height = 4)



# 3. Test a difference of slopes

fit <- lm(estimate_log10 ~ passage * treat, data = fluxes)
summary(fit)

fit1 <- lm(estimate_log10 ~ passage + treat, data = fluxes)
summary(fit1)
anova(
      lm(estimate_log10 ~ passage * treat, data = fluxes),
      lm(estimate_log10 ~ passage + treat, data = fluxes)
)

# 4. Plot the back-transformed slope

summary(fit)
fit$coef[[3]]
fit$coef[[4]]

ggplot(fluxes, aes(x = passage, y = estimate, color = treat)) +
  theme_classic() +
  geom_jitter() +
  geom_abline(intercept = fit$coef[[3]], slope = fit$coef[[4]]^10) +
  labs(x = "Passage Number", y = "Methane Oxidation Rate (-k)") +
  scale_color_manual(name = "Treatment", labels = c('Neutral', 'Positive'), values = c('gray40', 'darkorange2'))

####################################################################
# End the correct way to do it
################################################################

# Calculate deviance as p - n
deviance <-
  fluxes %>% 
  select(treat, passage, estimate) %>% 
  group_by(passage, treat) %>% 
  summarize(mean = mean(estimate), .groups = "drop") %>% 
  pivot_wider(names_from = treat, values_from = mean) %>% 
  mutate(deviance = p - n)

# Calculate variance of deviance as SED
deviance$se <-
  fluxes %>% 
  select(treat, passage, estimate) %>% 
  mutate(x = 1:nrow(fluxes)) %>% 
  pivot_wider(names_from = treat, values_from = estimate) %>% 
  group_by(passage) %>% 
  summarize(sed = sed(p, n, na.rm = TRUE), .groups = "drop") %>%
  pull(sed)

# Fit deviance model
fit <- rma(deviance ~ passage, se^2, method="FE", data = deviance)

plot(fit)

# Plot deviance
ggplot(deviance, aes(x = passage, y = deviance, ymin = deviance - se, ymax = deviance + se)) + 
  geom_pointrange(color = 'darkorange2') + 
  geom_abline(intercept = fit$beta[1], slope = fit$beta[2])

# Take deviance model parameters and export into a data.frame
rma_output <- data.frame(
Estimate = fit$beta,
se = fit$se,
z.value = fit$zval,
p.value = fit$pval,
upper.ci = fit$ci.lb,
lower.ci = fit$ci.ub
)

# Fit deviance model without passage 2
fit_no2 <- 
filter(deviance, passage != 2) %>% 
rma(deviance ~ passage, se^2, method="FE", data = .)

# Take deviance model withou passage 2 parameters and export into a data.frame

rma_output_no2 <- data.frame(
Estimate = fit_no2$beta,
se = fit_no2$se,
z.value = fit_no2$zval,
p.value = fit_no2$pval,
upper.ci = fit_no2$ci.lb,
lower.ci = fit_no2$ci.ub
)

# R (response to selection) for the model w/o sample 2
R_no2 <- rma_output_no2[[2, 1]]
R <- rma_output[[2, 1]]

# Plot the no2 model
filter(deviance, passage != 2) %>% 
ggplot(., aes(x = passage, y = deviance, ymin = deviance - se, ymax = deviance + se)) + 
  geom_pointrange(color = 'darkorange2') + 
  geom_abline(intercept = fit_no2$beta[1], slope = fit_no2$beta[2])

write_tsv(deviance, '../Output/deviance.tsv')
saveRDS(rma_output, '../Output/response.rds')
saveRDS(fit, '../Output/dev_fit.rds')



# Calculate deviance as percentage of p - n
deviance <-
  fluxes %>% 
  select(treat, passage, estimate) %>% 
  group_by(passage, treat) %>% 
  summarize(mean = mean(estimate), .groups = "drop") %>% 
  pivot_wider(names_from = treat, values_from = mean) %>% 
  mutate(deviance = (p - n) / n)

# Calculate variance of deviance as SED
deviance$se <-
  fluxes %>% 
  select(treat, passage, estimate) %>% 
  mutate(x = 1:nrow(fluxes)) %>% 
  pivot_wider(names_from = treat, values_from = estimate) %>% 
  group_by(passage) %>% 
  summarize(sed = sed(p, n, na.rm = TRUE), .groups = "drop") %>%
  pull(sed)

# Fit deviance model
fit <- rma(deviance ~ passage, se^2, method="FE", data = deviance)

plot(fit)

# Plot deviance
ggplot(deviance, aes(x = passage, y = deviance, ymin = deviance - se, ymax = deviance + se)) + 
  geom_pointrange(color = 'darkorange2') + 
  geom_abline(intercept = fit$beta[1], slope = fit$beta[2])

# Take deviance model parameters and export into a data.frame
rma_output <- data.frame(
Estimate = fit$beta,
se = fit$se,
z.value = fit$zval,
p.value = fit$pval,
upper.ci = fit$ci.lb,
lower.ci = fit$ci.ub
)

# Fit separte slopes for Positive and Neutral with robust M-estimator regression

library(MASS)
anova(
fit <- rlm(estimate ~ passage * treat, data = fluxes),
fit <- rlm(estimate ~ passage + treat, data = fluxes))

summary(fit)
anova(fit)
new_data <- cbind(fluxes, predict(fit, interval = 'confidence'))
colnames(new_data) 
ggplot(new_data, aes(x = passage, y = estimate, color = treat)) +
  theme_bw() +
  geom_jitter() +
  geom_line(aes(passage, fit)) +
  geom_ribbon(aes(ymin=lwr,ymax=upr), alpha=0.3)

ggplot(new_data, aes(x = passage, y = estimate)) +
  theme_bw() +
  geom_jitter(aes(color = treat)) +
  geom_line(aes(passage, fit, color = treat)) +
  geom_ribbon(aes(ymin=lwr,ymax=upr, group = treat), alpha=0.3) +
  ylim(-0.01, 0.08)
ggplot(fluxes, aes(x = passage, y = estimate, color = treat)) + 
  geom_point() + 
  stat_smooth(method='lm')
ggsave('raw_fluxes.pdf')
