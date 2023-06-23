library(vegan)
library(breakaway)
library(magrittr)
library(zCompositions)
library(tidyverse)
source('R/functions.R')

set.seed(19760620)

aes_data <- read_tsv('analysis/output/community_data.tsv')

# Look at distribution of sequencing depths
aes_data %>% 
  group_by(sample) %>% 
  summarize(total = sum(count)) %>% 
  ggplot(aes(x = total)) +
  geom_histogram()


seq_range <- 
  aes_data %>%
  group_by(sample) %>% 
  summarize(total = sum(count)) %>% 
  summarize(seq_range = range(total)) %$%
  seq_range

# Generate a null dataset

rand_aes <- randomize_asv_table(aes_data)

#######################
# Alpha diversity
#####################


analysis <- 
  rand_aes %>%
  count(sample, value) %>%
  nest(data = -sample) %>%
  mutate(n_seqs = map_dbl(data, ~sum(.x$value * .x$n)),
         sobs = map_dbl(data, ~sum(.x$n)),
         rare = map_dbl(data, ~rarefy(rep(.x$value, .x$n), sample=seq_range[1])),
         chao = map_dbl(data, ~get_chao(.x)),
         ba = map(data, ~get_breakaway(.x))) %>%
  dplyr::select(-data) %>%
  unnest(ba)


analysis %>%
  dplyr::select(sample, n_seqs, sobs, chao, rare, est) %>%
  pivot_longer(-c(sample, n_seqs)) %>%
  ggplot(aes(x=n_seqs, y=value, color=name)) +
  geom_point() +
  geom_smooth(se=FALSE) +
  coord_cartesian(ylim=c(0, 40000)) +
  theme_classic() +
  labs(title = "AES", x = "Sequencing Depth", y = "Alpha Diversity")

analysis %>%
  dplyr::select(sample, n_seqs, sobs, chao, rare, est) %>%
  pivot_longer(-c(sample, n_seqs)) %>%
  ggplot(aes(x=n_seqs, y=value, color=name)) +
  geom_point() +
  geom_smooth(se=FALSE) +
  coord_cartesian(ylim=c(0, 10000)) +
  theme_classic() +
  labs(title = "AES", x = "Sequencing Depth", y = "Alpha Diversity")

##### Evenness

rand_aes %>%
  group_by(sample) %>%
  summarize(sobs = richness(value),
            shannon = shannon(value),
            simpson = simpson(value),
            invsimpson = 1/simpson,
            n = sum(value)) %>%
  pivot_longer(cols=c(sobs, shannon, invsimpson, simpson),
               names_to="metric") %>%
  ggplot(aes(x=n, y=value)) +
  geom_point() +
  geom_smooth() +
  facet_wrap(~metric, nrow=4, scales="free_y") +
  labs(title = "AES", x = "Sequencing Depth", y = "Evenness")

########################
# Beta Diversity
########################


sample_count_aes <- rand_aes %>%
  group_by(sample) %>%
  summarize(n_seqs = sum(value))

# Computer distance matrices for rare and non-rare data

rand_aes_df <- rand_aes %>%
  pivot_wider(names_from=rand_asv, values_from=value, values_fill = 0) %>%
  as.data.frame()

rownames(rand_aes_df) <- rand_aes_df$sample
rand_aes_df <- rand_aes_df[,-1]

norare_aes_dist <- vegdist(rand_aes_df, method="euclidean")
rare_aes_dist <- avgdist(rand_aes_df, dmethod="euclidean", sample=min(sample_count_aes$n_seqs))

norare_aes_dtbl <- norare_aes_dist %>%
  as.matrix %>%
  as_tibble(rownames = "sample") %>%
  pivot_longer(cols=-sample) %>%
  filter(name < sample)

rare_aes_dtbl <- rare_aes_dist %>%
  as.matrix %>%
  as_tibble(rownames = "sample") %>%
  pivot_longer(cols=-sample) %>%
  filter(name < sample)


## Now for the CLR transformed data (robust CLR)

rclr_aes_df <- rand_aes %>%
  group_by(sample) %>%
  mutate(rclr = log(value/gm(value))) %>%
  View()
  ungroup() %>%
  dplyr::select(-value) %>%
  pivot_wider(names_from=rand_asv, values_from=rclr, values_fill=0) %>%
  as.data.frame()

rownames(rclr_aes_df) <- rclr_aes_df$sample
rclr_aes_df <- rclr_aes_df[,-1]

rclr_aes_dist <- vegdist(rclr_aes_df, method="euclidean")

zclr_aes_df <- cmultRepl(rand_aes_df, method="CZM", output="p-count") %>%
  as_tibble(rownames = "sample") %>%
  pivot_longer(-sample) %>%
  group_by(sample) %>%
  mutate(zclr = log(value/gm(value))) %>%
  ungroup() %>%
  dplyr::select(-value) %>%
  pivot_wider(names_from=name, values_from=zclr, values_fill=0) %>%
  column_to_rownames("sample")


zclr_aes_dist <- vegdist(zclr_aes_df, method="euclidean")

rclr_aes_dtbl <- rclr_aes_dist %>%
  as.matrix %>%
  as_tibble(rownames = "sample") %>%
  pivot_longer(cols=-sample) %>%
  filter(name < sample)

zclr_aes_dtbl <- zclr_aes_dist %>%
  as.matrix %>%
  as_tibble(rownames = "sample") %>%
  pivot_longer(cols=-sample) %>%
  filter(name < sample)



# Plot everything

inner_join(norare_aes_dtbl, rare_aes_dtbl, by=c("sample", "name")) %>%
  inner_join(., rclr_aes_dtbl, by=c("sample", "name")) %>%
  inner_join(., zclr_aes_dtbl, by=c("sample", "name")) %>%
  inner_join(., sample_count_aes, by=c("sample" = "sample")) %>%
  inner_join(., sample_count_aes, by=c("name" = "sample")) %>%
  mutate(diffs = abs(n_seqs.x - n_seqs.y)) %>%
  dplyr::select(sample, name, norare=value.x, rare=value.y, rclr=value.x.x, zclr=value.y.y, diffs) %>%
  pivot_longer(cols=c(norare, rare, rclr, zclr), names_to="method", values_to="dist") %>%  
  ggplot(aes(x=diffs, y=dist)) +
  geom_point() +
  facet_wrap(~method, nrow=4, scales="free_y") +
  geom_smooth() +
  labs(title = "AES", x = "Difference in Sequence Depth", y = "Dissimilarity (Euclidean)")

