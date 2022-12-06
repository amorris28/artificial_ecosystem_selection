# Response to selection
0.1779718
# Standard Error
0.0643900
ratio_log10 <- calc_plot_ratios(fluxes$passage, fluxes$log_ch4)

ggplot(fluxes, aes(x = passage, y = log_ch4, color = treat)) +
    stat_smooth(method = 'lm', se = FALSE, formula = 'y ~ x') +
    scale_color_manual(
        name = "Treatment", 
        labels = c('Neutral', 'Positive'), 
        values = c('gray40', 'darkorange2')) +
    geom_jitter(#aes(alpha = selected), 
        width = 0.1) + 
    labs(x = "Passage Number", 
         y = expression(log[10] ~ CH[4] ~ "(-k)")) +
    coord_fixed(1) +
    scale_x_continuous(labels = 1:5)

model1 <- lm(log_ch4 ~ passage * treat, data = fluxes)
summary(model1)

divergence <-
    fluxes %>% 
    select(passage, treat, log_ch4) %>% 
    group_by(passage, treat) %>% 
    summarize(mean = mean(log_ch4), .groups = "drop") %>% 
    mutate(treat = factor(treat)) %>% 
    pivot_wider(names_from = "treat", values_from = "mean") %>% 
    mutate(divergence = p - n)

ratio_div <- calc_plot_ratios(divergence$passage, divergence$divergence)

ggplot(divergence, 
       aes(x = passage, 
           y = divergence)) +
    stat_smooth(method = 'lm', 
                se = FALSE, 
                formula = 'y ~ x',
                color = "black",
                linewidth = 0.5) +
    geom_point() + 
    labs(x = "Passage Number", 
         y = expression(atop("Divergence", log[10] ~ CH[4] ~ "(-k)"))) +
    coord_fixed(ratio_div) +
    scale_x_continuous(labels = 1:5)

model2 <- lm(divergence ~ passage, data = divergence)
summary(model2)

sd <- 
    heritability %>% 
    mutate(sd = selected - parental) %>% 
    select(passage, treat, sd) %>% 
    pivot_wider(names_from = 'treat', values_from = 'sd') %>% 
    mutate(sd = p - n) %>% 
    select(-n, -p)

sd$cumulative_sd <- 
    c(sum(sd[1:1, 2]),
      sum(sd[1:2, 2]),
      sum(sd[1:3, 2]),
      sum(sd[1:4, 2])
      )


rh <-
    divergence %>% 
    left_join(sd, by = "passage") %>% 
    filter(passage != 0 )

ratio_rh <- calc_plot_ratios(rh$cumulative_sd, rh$divergence)

ggplot(rh, 
       aes(x = cumulative_sd, 
           y = divergence)) +
    stat_smooth(method = 'lm', 
                se = FALSE, 
                formula = 'y ~ x',
                color = "black",
                linewidth = 0.5) +
    geom_point() + 
    labs(x = "Cumulative Selection Differential", 
         y = expression(atop("Divergence", log[10] ~ CH[4] ~ "(-k)"))) +
    coord_fixed(ratio_rh)

model3 <- lm(divergence ~ 1, rh)
model4 <- lm(divergence ~ cumulative_sd, rh)
anova(model3, model4)
summary(model4)
