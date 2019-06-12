
##### load packages
library(tidyverse)
library(lubridate)
library(stringr)
library(broom)

#### import and cleaning data
prod <- read_tsv('data/production.tsv') # import data
prod <- prod[complete.cases(prod), ] # remove missing data

prod <- 
	prod %>% 
	mutate(rate = factor(substr(vial, 1, 1))) %>% 
	mutate(date = factor(date)) %>% 
	mutate(rep = str_sub(vial, start=-1)) %>% 
	mutate(seconds = period_to_seconds(hms(time))) %>% 
	mutate(days = seconds / 60 / 60 / 24) %>% 
  mutate(days = days - min(days)) %>%  
	filter(vial != 'check_std')

levels(prod$date) <- c('Day 9', 'Day 21')

ggplot(prod, aes(x = days, y = conc, group = vial, color = rate)) +
  geom_point() +
  facet_wrap(~ date) +
  stat_smooth(method = 'lm', se = F)

fluxes <- prod %>% 
  group_by(vial, date) %>%
  do(fit = lm(conc ~ days, .)) %>% 
  tidy(fit) %>% 
  select(vial, date, term, estimate) %>% 
  filter(term == 'days')

flux_sum <- fluxes %>% 
  mutate(size = substr(vial, 1, 1)) %>% 
  group_by(size, date) %>% 
  summarize_at(vars(estimate), funs(mean, sd))

ggplot(flux_sum, aes(y = mean, ymax = mean + sd, 
                     ymin = mean - sd, x = size, color = size)) +
	geom_pointrange() +
	facet_wrap(~ date) +
	theme_classic() +
  labs(y = expression('Methane Flux' ~ (mu* L ~ L ^ -1 ~ day ^ -1))) +
  scale_color_discrete(name = 'Inoculum\nSize (%)', labels = c('0.1', '1.0', '5.0')) +
  scale_x_discrete(name = 'Inoculum Size (%)', labels = c('0.1', '1.0', '5.0'))
ggsave(file = 'inoculum_size.pdf', width = 5, height = 4)
fluxes <- fluxes %>% 
  mutate(size = substr(vial, 1, 1))
ggplot(fluxes, aes(y = estimate, x = size)) +
  geom_boxplot() +
	geom_point() +
	facet_wrap(~ date) +
	theme_classic() 

prod[, ]

filter(prod, date == "Day 9" & rep == "a" & rate == 5,
             date == "Day 9" & rep == "b" & rate == 5)
