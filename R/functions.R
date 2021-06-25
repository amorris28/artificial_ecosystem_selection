library(tidyverse)
library(broman)

raw_dir <- '../Data/' # Raw Data Directory
der_dir <- '../Output/' # Derived/Modified Data Directory


plot_flux <- function(fluxes, passage, estimate, ratio = NULL, log10 = FALSE) {
  p <- ggplot(fluxes, aes(x = {{passage}}, y = {{estimate}}, color = treat)) +
    theme_classic() +
    stat_smooth(method = 'lm', se = FALSE, formula = 'y ~ x') +
    scale_color_manual(name = "Treatment", labels = c('Neutral', 'Positive'), values = c('gray40', 'darkorange2')) +
    geom_jitter(aes(alpha = selected), width = 0.1) +
    scale_alpha_manual(name = "Selected", labels = c('Not', 'Selected'), values = c(0.3, 1))
  if (log10 == FALSE) {
    p <- p + labs(x = "Passage Number", y = "Methane Oxidation Rate (-k)")
  } 
  else if (log10 == TRUE) {
    p <- p + labs(x = "Passage Number", y = expression(log[10] * "(Methane Consumption Rate (-k))"))
  } 
  
  if (!is.null(ratio)) {
    p <- p + coord_fixed(ratio)
  }
  
  return(p)
}

calc_plot_ratios <- function(x, y) {
  (max(x)-min(x))/(max(y)-min(y))
}


print_model <- function(fit, term = 1) {
  paste0('(slope = ', myround(tidy(fit)[term, 2], 2), 
        ', SE = ', myround(tidy(fit)[term, 3], 2), 
        ', t = ', myround(tidy(fit)[term, 4], 2), 
        ', p = ', myround(tidy(fit)[term, 5], 2), ')')
}


plot_herit <- function(heritability, ratio) {
  ratio <- calc_plot_ratios(heritability$selected, heritability$offspring)
  ggplot(heritability, aes(selected, offspring, color = treat)) +
    theme_classic() +
    geom_jitter(width = 0.01) + 
    stat_smooth(method = 'lm', se = FALSE, formula = 'y ~ x') +
    labs(x = "Mid-parent (mean(log10(Flux (-k))))", 
         y = "Offspring (log10(Flux (-k)))") +
    scale_color_manual(name = "Treatment", 
                       labels = c('Neutral', 'Positive'), 
                       values = c('gray40', 'darkorange2')) +
    coord_fixed(ratio)
}