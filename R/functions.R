
raw_dir <- '../Data/' # Raw Data Directory
der_dir <- '../Output/' # Derived/Modified Data Directory

# theme_set(theme_tufte()+
#             theme(axis.title.y = element_text(angle = 0, vjust = 0.5)))
theme_set(theme_classic() +
            theme(panel.border = element_rect(fill = NA, size = 1.0625),
                  axis.line = element_blank()))

plot_flux <- function(fluxes, passage, estimate, ratio = NULL, log10 = FALSE) {
  p <- ggplot(fluxes, aes(x = {{passage}}, y = {{estimate}}, color = treat)) +
    # theme_classic() +
    # geom_rangeframe(color = 'black') +
    stat_smooth(method = 'lm', se = FALSE, formula = 'y ~ x') +
    scale_color_manual(
      name = "Treatment", 
      labels = c('Neutral', 'Positive'), 
      values = c('gray40', 'darkorange2')) +
    geom_jitter(#aes(alpha = selected), 
      width = 0.1) #+
#    scale_alpha_manual(name = "Selected", labels = c('Not', 'Selected'), values = c(0.3, 1))
  if (log10 == FALSE) {
    p <- p + labs(x = "Passage Number", 
                  y = "Methane Oxidation Rate (-k)")
  } 
  else if (log10 == TRUE) {
    p <- p + labs(x = "Passage Number", 
                  y = expression(log[10] ~ CH[4] ~ "(-k)"))
  } 
  
  if (!is.null(ratio)) {
    p <- p + coord_fixed(ratio)
  }
  
  return(p)
}

calc_plot_ratios <- function(x, y) {
  (max(x)-min(x))/(max(y)-min(y))
}


print_lm <- function(fit, term = 1, estimate = 'slope') {
  paste0('(', estimate, ' = ', myround(tidy(fit)[term, 2], 2), 
        ', SE = ', myround(tidy(fit)[term, 3], 2), 
        ', t = ', myround(tidy(fit)[term, 4], 2), 
        ', p = ', myround(tidy(fit)[term, 5], 2), ')')
}

print_lrt <- function(fit, term = 2, test = "Likelihood ratio test") {
  paste0('(', test, ': df = ', round(tidy(fit)[term, 3]), 
         ', ss = ', myround(tidy(fit)[term, 4], 2), 
         ', p = ', myround(tidy(fit)[term, 5], 2), ')')
}


plot_herit <- function(heritability, ratio) {
  ratio <- calc_plot_ratios(heritability$selected, heritability$offspring)
  ggplot(heritability, aes(selected, offspring, color = treat)) +
    # theme_classic() +
    # geom_rangeframe(color = 'black') +
    geom_jitter(width = 0.01) + 
    stat_smooth(method = 'lm', se = FALSE, formula = 'y ~ x') +
    labs(x = expression(Parental ~ log[10] ~ CH[4] ~ "(-k)"), 
         y = expression(atop(Offspring, log[10] ~ CH[4] ~ "(-k)"))) +
    scale_color_manual(name = "Treatment", 
                       labels = c('Neutral', 'Positive'), 
                       values = c('gray40', 'darkorange2')) +
    coord_fixed(ratio)
}

percent_less <- function(initial, final) {
  round(-100 * (final - initial)/abs(initial))
}


plot_beta <- function(ps) {
  
  ord_calc_aitch <-
    ps %>%
    tax_transform(trans = 'clr') %>%
    ord_calc(method = "PCA")
  ord_calc_aitch %>%
    ord_plot(color = "treat",
             shape = "passage",
             auto_caption = NA) +
    # theme_tufte() +
    # geom_rangeframe(color = 'black') +
    coord_fixed(5.5/43.6, clip="off") +
    scale_shape_discrete(name = "Passage") +
    scale_color_manual(name = "Treatment",
                       labels = c('Neutral', 'Positive'),
                       values = c('gray40', 'darkorange2')) +
    theme_classic() +
    theme(panel.border = element_rect(fill = NA, size = 0.5),
          axis.line = element_blank())  
  # theme_tufte() +
  #   theme(axis.title.y = element_text(angle = 0, vjust = 0.5))
  

  # ps.prop <- transform_sample_counts(ps, function(otu) otu/sum(otu))
  # ord.nmds.bray <- ordinate(ps.prop, method="NMDS", distance="bray")
  # bray <- plot_ordination(ps.prop,
  #                         ord.nmds.bray,
  #                         color='treat',
  #                         shape = 'passage'
  #                         ) +
  #   coord_fixed() +
  #   scale_color_manual(name = "Treatment",
  #                        labels = c('Neutral', 'Positive'),
  #                        values = c('gray40', 'darkorange2'))
  # 
  # 
  # ord.nmds.jacc <- ordinate(ps, method="NMDS", distance="jaccard", binary = TRUE)
  # jacc <- plot_ordination(ps,
  #                         ord.nmds.jacc,
  #                         color='treat',
  #                         shape = 'passage'
  #                         ) +
  #   # coord_fixed() +
  #   scale_color_manual(name = "Treatment",
  #                        labels = c('Neutral', 'Positive'),
  #                        values = c('gray40', 'darkorange2'))
  # 
  # ggarrange(bray, jacc, common.legend = TRUE, labels = c("A", "B"))
}

print_adonis <- function(fit, term = 1, test = "PERMANOVA") {
  paste0('(', test, ': df = ', round(tidy(fit)[term, 2]), 
         ', ss = ', myround(tidy(fit)[term, 3], 2), 
         ', R2 = ', myround(tidy(fit)[term, 4], 2), 
         ', p = ', myround(tidy(fit)[term, 5], 2), ')')
}
reorder_within <- function(x, by, within, fun = mean, sep = "___", ...) {
  new_x <- paste(x, within, sep = sep)
  stats::reorder(new_x, by, FUN = fun)
}


scale_x_reordered <- function(..., sep = "___") {
  reg <- paste0(sep, ".+$")
  ggplot2::scale_x_discrete(labels = function(x) gsub(reg, "", x), ...)
}

scale_y_reordered <- function(..., sep = "___") {
  reg <- paste0(sep, ".+$")
  ggplot2::scale_y_discrete(labels = function(x) gsub(reg, "", x), ...)
}

dt_plot <- function(dt_data) {
  ggplot(dt_data, aes(x = x, xmin = xmin, xmax = xmax, y = reorder(taxa, x))) +
    geom_pointrange() +
    geom_vline(xintercept = 0) +
    labs(x = NULL, y = "Taxa (family)") +
    coord_cartesian(clip="off") +
    theme(panel.border = element_blank())
}
