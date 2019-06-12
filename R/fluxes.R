## Todo list
## 1. plot transfers in the same figure
## 2. calculate heritability
## 3. plot mid-parent against offspring (this might make more sense if
##     I actually crossed specific pairs of jars rather than homogenizing them all

library(tidyverse)
library(lubridate)
library(broom)

top_jars_gen1 <- c(2, 3, 13, 16)

temp <- list.files(path="../Data", pattern="FluxData*", full.names = TRUE)
conc <- sapply(temp, read.csv, stringsAsFactors = FALSE,
                 simplify = FALSE, USE.NAMES = TRUE)
names(conc) <- substr(names(conc), 18, 25)
conc <- bind_rows(conc, .id = "Date")

# Code transfers
conc$transfer <- as.character(match(conc$Date, unique(conc$Date)))


# Jar broke so remove # 9 from gen 1
conc <- conc[!(conc$JAR == 9 & conc$Date == "20190527"), ]

# Jar # 1 and 2 from gen 2 had impossible ch4 values so remove
conc <- conc[!(conc$JAR == 1 & conc$Date == "20190607"), ]
conc <- conc[!(conc$JAR == 2 & conc$Date == "20190607"), ]

# Convert clock time to days and set t0 to 0 days
conc <- 
  conc  %>% 
  mutate(days = period_to_seconds(hms(paste0(conc$TIME, ':00'))) / 60 / 60) %>% 
  group_by(Date, JAR) %>% 
  mutate(days = days - min(days))

# Convert ppm to umol
conc$ch4_umol <- conc$CH4_CONC * 0.965 / ((0.08206 * (293)))

# Calculate fluxes from lm slopes
flux <- 
  conc %>% 
  group_by(transfer, JAR) %>%
  do(tidy(lm(ch4_umol ~ days, data = .))) %>% 
  filter(term == 'days')  %>% 
  select(transfer, JAR, flux_umold = estimate)

# Identify the jars that were used for selection
flux$selected[flux$JAR %in% top_jars_gen1 & flux$transfer == '1'] <- T
flux$selected[!(flux$JAR %in% top_jars_gen1) | flux$transfer != '1'] <- F

all_par <- flux$flux_umold[flux$transfer == '1']
offspr <- flux$flux_umold[flux$transfer == '2']
sel_par <- flux$flux_umold[flux$transfer == '1' & flux$selected == T]
# Plot fluxes

ggplot(flux, aes(x = flux_umold, fill = selected)) +
  geom_histogram(aes(fill = interaction(transfer, selected))) +
  facet_grid(transfer ~ .) +
  scale_fill_manual(values = c('black', 'blue', 'red')) +
  geom_vline(xintercept = mean(all_par)) +
  geom_vline(xintercept = mean(offspr), color = 'blue') +
  geom_vline(xintercept = mean(sel_par), color = 'red') 

ggplot(flux, aes(x = transfer, y = flux_umold)) +
  geom_boxplot(outlier.shape = NA) +
  geom_jitter(aes(color = selected)) +
  scale_color_manual(values = c('black', 'red')) + 
  geom_hline(yintercept = mean(all_par)) +
  geom_hline(yintercept = mean(offspr), color = 'blue') +
  geom_hline(yintercept = mean(sel_par), color = 'red') 

# Calculate heritability 

ns_heritability <- function(all_par, offspr, sel_par) {
  R <- mean(all_par) - mean(offspr)
  S <- mean(all_par) - mean(sel_par)
  h2 <- R / S
  h2
  # Where:
  # h2 is the narrow-sense heritability
  # R is the realized average difference between the parent generation
  #     and the next generation
  # S is the average difference between the parent generation and the selected
  #     parents
}

ns_heritability(all_par, offspr, sel_par) 
                
  R <- mean(all_par) - mean(offspr)
  S <- mean(all_par) - mean(sel_par)
  h2 <- R / S
  h2


flux %>% 
  group_by(transfer) %>% 
  top_n(-4, flux_umold)
