# This script imports the heritability data, which includes, for each passage,
# the mean for all parents, the selected parents, and the offspring (of the
# selected parents). It then calculates S, the selection differential, as the
# mean difference between the selected parents and all parents. Because passage
# 2 was accidentaly selected for the lowest methane oxidation rate, I take the
# absolute value of this difference, i.e. |S|. 
#
# Next, it imports the deviance data and calculates R, the respones to
# selection, as the slope of mean difference in flux (positive - neutral) over
# time. 
# 
# An alternative approach would be to calculate R directly instead of
# approximating it using the slope as in the equation offspring - parent. In
# this case, I would not be using the deviance, but instead the raw fluxes. I
# can do that with the heritability dataset.
# 
# Once I have R through one of the above approaches, 
# 
# Inpot: selected.csv, fluxes.tsv, heritability.tsv
# Output: ???

library(tidyverse)
library(morris)
library(broom)

heritability <- read_tsv('../Output/heritability.tsv')
fluxes <- read_tsv('../Output/fluxes.tsv')

# Function for the Breeder's equation

breeders <- function(R, S) {
  R / S
}

# Matt's approach: h2 for each generation
h2_per_gen  <- 
heritability %>% 
  mutate(R = offspring - parental) %>% 
  mutate(S = selected - parental) %>% 
  mutate(h2 = breeders(R, S))

write_tsv(h2_per_gen, '../Output/h2_per_gen.tsv')

ggplot(h2_per_gen, aes(x = passage, color = treat, y = R)) +
  geom_point()

# Calculate R using regression of deviance over time.
# Calculate S using math.

dev_fit <- readRDS('../Output/dev_fit.rds')
R <- dev_fit$beta[2]

S <-
  heritability %>%
  filter(treat == "p") %>%
  mutate(S = abs(selected - parental)) %>%
  summarize(S = mean(S))  %>% 
  pull()

h2_reg_dev <- breeders(R, S)

lm_fit <- 
  fluxes %>% 
  filter(treat == 'p') %>% 
  select(treat, passage, estimate) %>% 
  lm(estimate ~ passage, data = .) 

R_not_dev <- pull(tidy(lm_fit)[2, 2])
h2_reg_abs <- breeders(R_not_dev, S)

# Calculate R as regression of offspring on parents

ggplot(heritability, aes(x = parental, y = offspring)) +
  geom_point() + 
  stat_smooth(method = 'lm', se = FALSE)
summary(lm(offspring ~ parental, data = heritability, subset = treat == 'p'))
# Calculate h2 (heritability) using math, not regression
# For each generation and then calculate the mean/se
h2_calc_method <-
  heritability %>%
  filter(treat == "p") %>%
  mutate(S = abs(selected - parental)) %>%
  mutate(R = offspring - parental) %>%
  mutate(h2 = breeders(R, S)) %>%
  summarize(S = mean(S),
            R = mean(R),
            se = se(h2),
            h2 = mean(h2))

h2_calc_method_no_2 <-
  heritability %>%
  filter(treat == "p") %>%  
  filter(passage != 2) %>%
  mutate(S = abs(selected - parental)) %>%
  mutate(R = offspring - parental) %>%
  mutate(h2 = breeders(R, S)) %>%
  summarize(S = mean(S),
            R = mean(R),
            se = se(h2),
            h2 = mean(h2))

h2 <- 
  h2_calc_method %>% 
  mutate(method = "calc p")

h2_no2 <- 
  h2_calc_method_no_2 %>% 
  mutate(method = "calc p no 2")


h2 <- rbind(h2, h2_no2)

# Cumulative response to selection

parent <- heritability[[1, 3]]
offspr <- heritability[[8, 4]]
select <- heritability[[8, 5]]
R = offspr - parent
S = select - parent
h2 = breeders(R, S)

heritability[,'cum_res'] <- NA
heritability$cum_sel <- NA
herit_p <- filter(heritability, treat == 'p')
for (i in seq(nrow(herit_p))) {
  off <- sum(herit_p$offspring[1:i])
  par <- sum(herit_p$parental[1:i])
  sel <- sum(herit_p$selected[1:i])
  herit_p$cum_res[i] <- off - par
  herit_p$cum_sel[i] <- sel - par
}
herit_p$cum_h2 <- herit_p$cum_res / herit_p$cum_sel

ggplot(herit_p, aes(x = cum_sel, y = cum_res)) + 
  theme_classic() +
  labs(x = 'Cumulative selection differential',
       y = 'Cumulative response to selection') +
  geom_point() + 
  stat_smooth(method = 'lm', se = FALSE)
summary(lm(cum_res ~ cum_sel, data = herit_p))

# Regression of offspring on mid-parent

selected_jars <- read_csv('../Data/selected.csv')
fluxes <- read_tsv('../Output/fluxes.tsv')

# Pull out the selected parental jars
selected <- 
  fluxes[paste0(fluxes$passage, fluxes$jar) %in% paste0(selected_jars$passage, selected_jars$jar), ] %>%
  select(treat, estimate, passage) %>% 
  group_by(treat, passage) %>% 
  summarize(parental = mean(estimate), .groups = 'drop')

offspring <- 
  fluxes %>% 
  select(passage, treat, estimate) %>% 
  filter(passage != 1) %>% 
  mutate(passage = passage - 1) %>% 
  rename(offspring = estimate)

heritability <- 
  offspring %>% 
  left_join(selected, by = c('passage', 'treat'))

heritability

ggplot(heritability, aes(parental, offspring)) +
  theme_classic() +
  geom_point() + 
  stat_smooth(method = 'lm', se = FALSE)

summary(lm(offspring ~ parental, data = heritability))

ggplot(heritability, aes(parental, offspring, color = treat)) +
  theme_classic() +
  geom_point() + 
  stat_smooth(method = 'lm', se = FALSE)
summary(lm(offspring ~ parental * treat, data = heritability))
