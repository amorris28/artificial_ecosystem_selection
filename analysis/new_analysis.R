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
fitdata <- fitted(model3)
fitdata4 <- fitted(model4)
ggplot(rh, 
       aes(x = cumulative_sd, 
           y = divergence)) +
    stat_smooth(method = 'lm', 
                se = TRUE, 
                formula = 'y ~ x',
                color = "red",
                linetype = 2,
                linewidth = 0.5) +
    geom_point() + 
    labs(x = "Cumulative Selection Differential", 
         y = expression(atop("Divergence", log[10] ~ CH[4] ~ "(-k)"))) +
    coord_fixed(ratio_rh) +
    geom_line(aes(y = fitdata), linetype = 2) +
    geom_abline(intercept = 0, slope = 1, linetype = 3) +
    geom_abline(intercept = 0, slope = 0, linetype = 3) +
    
    xlim(-1, 2) +
    ylim(-1, 2)

anova(model3, model4)
summary(model4)


############################

library(glmmTMB)
aes_data %>% 
    filter(!is.na(ch4)) ->
    aes_data_nona
aes_data_nona %>% 
    select(asv, sample, count) %>% 
    pivot_wider(names_from = asv, values_from = count, values_fill = 0) %>% 
    as.data.frame() ->
    aes_com_df
rownames(aes_com_df) <- aes_com_df[, 1]
aes_com_df <- aes_com_df[, -1]
rowSums(aes_com_df) %>% 
    min() ->
    min_seqs
beta_dis <- avgdist(aes_com_df, iterations = 1, sample = min_seqs)
beta_dis %>% 
    as.matrix() ->
    beta_dis_mat
beta_dis_mat %>% 
    as_tibble(rownames = 'sample1') %>% 
    pivot_longer(-sample1, names_to = 'sample2', values_to = 'beta') %>% 
    mutate(samples = paste(sample1, sample2, sep = "-")) ->
    beta_df
aes_data_nona %>% 
    select(sample, passage, treat, ch4) %>% 
    distinct() ->
    model_df

model_df %>% 
    select(sample, ch4) %>% 
    as.data.frame() ->
    ch4_mat
rownames(ch4_mat) <- ch4_mat[, 1]
ch4_mat <- ch4_mat[, -1]


model1 <- glmmTMB(ch4 ~ passage + treat + (1 | sample), data = model_df)

# Example
n <- 6                                              ## Number of time points
x <- MASS::mvrnorm(mu = rep(0,n),
             Sigma = .7 ^ as.matrix(dist(1:n)) )    ## Simulate the process using the MASS package
y <- x + rnorm(n)                                   ## Add measurement noise
times <- factor(1:n, levels=1:n)
levels(times)
group <- factor(rep(1,n))
dat0 <- data.frame(y,times,group)
fit1 <- glmmTMB(y ~ ar1(times + 0 | group), data=dat0)
