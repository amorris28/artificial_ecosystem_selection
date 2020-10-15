# input: fluxes.tsv
# output: deviance.tsv, deviance figure

library(tidyverse)
library(metafor)

# Response to Selection

fluxes <- read_tsv('../Output/fluxes.tsv')

# Calculate deviance as p - n
deviance <-
  fluxes %>% 
  select(treat, passage, estimate) %>% 
  group_by(passage, treat) %>% 
  summarize(mean = mean(estimate), .groups = "drop") %>% 
  pivot_wider(names_from = treat, values_from = mean) %>% 
  mutate(deviance = p - n)

# Create se function that can handle NAs
se <- function(x, na.rm = FALSE){
  sqrt(var(if (is.vector(x) || is.factor(x)) x else as.double(x), 
    na.rm = na.rm)) / sqrt(length(if (na.rm == TRUE) na.omit(x) else x))
}

# Standard error of the difference function
sed <- function(p, n, na.rm = FALSE) {
  sqrt(se(p, na.rm = na.rm) ^ 2 + se(n, na.rm = na.rm)^ 2)
}

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
