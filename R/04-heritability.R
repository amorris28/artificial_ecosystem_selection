# Inpot: selected.csv, fluxes.tsv
# Output: heritability, heritability plot???


# Heritability

```{r create_heritability_data, message=FALSE, warning=FALSE}
selected_jars <- read_csv('../Data/selected.csv')

# Pull out the selected parental jars
selected <- 
  fluxes[paste0(fluxes$passage, fluxes$jar) %in% paste0(selected_jars$passage, selected_jars$jar), ] %>%
  select(treat, estimate, passage)

# Pull out all parental jars
parental <-
  fluxes %>% 
  select(passage, treat, estimate)

# Pull out all offspring jars
offspring <- 
  fluxes %>%
  select(treat, estimate, passage) %>% 
  filter(passage != 1) %>% 
  mutate(passage = passage - 1)
```


```{r heritability_mean}

# Calculate means for east generation
parental_mean <-
  parental %>% 
  group_by(passage, treat) %>% 
  summarize(parental = mean(estimate), .groups = "drop")

offspring_mean <-
  offspring %>% 
  group_by(passage, treat) %>% 
  summarize(offspring = mean(estimate), .groups = "drop")

selected_mean <-
  selected %>% 
  group_by(passage, treat) %>% 
  summarize(selected = mean(estimate), .groups = "drop")

# Combine all parent/offspring data into one data frame
heritability <- 
  parental_mean %>% 
  left_join(offspring_mean, by = c("passage", "treat")) %>% 
  left_join(selected_mean, by = c("passage", "treat")) %>% 
  #filter(treat == "p") %>% 
  filter(passage != 5) %>% # Remove passage 5, which has no offspring
  ungroup()


write_tsv(heritability, '../Output/heritability.tsv')

```


``` {r generation_h2}


######################################################################
# This is where you stopped
# Figure out why h2 is different from h2_calc_method
# Finish writing your email to brendan about heritability
######################################################################

# Function for the Breeder's equation

breeders <- function(R, S) {
  R / S
}

# Calculate h2 (heritability) using math, not regression
# For each generation and then calculate the mean/se
h2_calc_method <-
  heritability %>%
  filter(treat == "p") %>%
  mutate(S = selected - parental) %>%
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
  mutate(S = selected - parental) %>%
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
```

```{r h2_slope_method}

# Calculate S (selection differential) with/without passage 2

S <-
  heritability %>%
  filter(treat == "p") %>%
  mutate(S = abs(selected - parental)) %>%
  summarize(S = mean(S)) %>% 
  pull()
S_no2 <-
  heritability %>%
  filter(treat == "p") %>%
  filter(passage != 2) %>% 
  mutate(S = abs(selected - parental)) %>%
  summarize(S = mean(S)) %>% 
  pull()

# For the equivalent plot of Falconer and MacKay
# Scale and center all fluxes
heritability_scaled <-
  heritability %>% 
  pivot_longer(parental:selected) %>% 
  mutate(value = scale(value)) %>% 
  pivot_wider(names_from = "name", values_from = "value")

# Calculate R and S 
R_and_S <-
  heritability_scaled %>% 
  filter(treat == "p") %>% 
  summarize(R = mean(offspring),
            S = mean(selected))

# Calculate scaled h2
R <- R_and_S[[1, 'R']]
S <- R_and_S[[1, 'S']]
h2 <- breeders(R, S)

# Plot scaled h2
ggplot(data = heritability_scaled, aes(x = selected, y = offspring)) +
  geom_point(aes(shape = treat)) +
  scale_shape_manual(values = c(1,19), name = "Treatment", labels = c('Neutral', 'Positive')) +
  stat_smooth(se = FALSE, method = "lm", formula = y ~ x, color = 'black') +
  labs(x = "Selected Parents", y = "Offspring") +
  geom_segment(aes(x = 0, y = R, xend = S, yend = R), linetype = 3) +
  geom_segment(aes(x = S, y = 0, xend = S, yend = R), linetype = 3) +
  geom_hline(yintercept = 0) +
  geom_vline(xintercept = 0) +
  geom_text(label = "R", x = -0.1, y = R) +
    geom_text(label = "S", x = S, y = -0.2)


```

```{r}
heritability %>% 
  ggplot(aes(parental, offspring, color = treat)) +
  geom_point() +
  labs(x = "Parental", y = "Offspring") +
  theme_bw() +
  scale_color_discrete(name = "Treatment", labels = c('Neutral', 'Positive'))

summary(lm(offspring ~ parental, data = heritability))
```
```{r}
heritability %>% 
  ggplot(aes(selected, offspring, color = treat)) +
  geom_point() +
  labs(x = "Selected", y = "Offspring") +
  theme_bw() +
  scale_color_discrete(name = "Treatment", labels = c('Neutral', 'Positive'))
```

