library(tidyverse)
library(broom)

t = 1:100
y1 = 22 + (53 - 22) * exp(-0.02 * t) %>% jitter(10)
y2 = 24 + (60 - 22) * exp(-0.01 * t) %>% jitter(10)


df <- data.frame(t = t, y = y1, sensor = 'sensor1') %>% 
  rbind(. , data.frame(t = t, y = y2, sensor = 'sensor2'))
sensor1 <- df %>% filter(sensor == 'sensor1')


qplot(t, y, data = df, colour = sensor)
nls(y ~ yf + (y0 - yf) * exp(-alpha * t), 
    data = sensor1,
    start = list(y0 = 54, yf = 25, alpha = 1))
fit <- nls(y ~ SSasymp(t, yf, y0, log_alpha), data = sensor1)
fit
qplot(t, y, data = augment(fit)) + geom_line(aes(y = .fitted))
df %>% 
  group_by(sensor) %>% 
  do(fit = nls(y ~ SSasymp(t, yf, y0, log_alpha), data = .)) %>% 
  tidy(fit) %>% 
  select(sensor, term, estimate) %>% 
  spread(term, estimate) %>% 
  mutate(alpha = exp(log_alpha))
