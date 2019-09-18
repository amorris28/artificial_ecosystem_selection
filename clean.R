library(tidyverse)
library(lubridate)

time <- read.csv('eg_time_data.csv')

data_t0 <-
  data.frame(flux_date = unique(time$flux_date),
             t0 = c('2019-05-27 11:51:00', '2019-06-07 10:41:00', '2019-06-14 14:33:00'))

as.days <- function(start, end) {as.numeric(interval(start, end))/60/60/24}
time_data  <- 
time %>% 
  spread(t, time) %>% 
  left_join(data_t0, by = 'flux_date') %>% 
  select(flux_date:jar, t0, t1:t4)

conc <- read.csv('eg_conc_data.csv')
conc %>% 
  select(-co2_area) %>% 
  spread(t, ch4_area)
