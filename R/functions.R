
# Directory Definitions

raw_dir <- 'data/'      # Raw Data Directory
der_dir <- 'analysis/output/'    # Derived/Modified Data Directory
man_dir <- 'manuscript/'       # Manuscript directory
fig_dir <- 'analysis/figs/'      # Figures directory

# Set global ggplot theme

theme_set(theme_classic() +
            theme(panel.border = element_rect(fill = NA, linewidth = 1.0625),
                  axis.line = element_blank(),
                  ))

plot_flux <- function(fluxes, passage, estimate, ratio = NULL, log10 = FALSE) {
  p <- ggplot(fluxes, aes(x = {{passage}}, y = {{estimate}}, color = treat)) +
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




print_lm <- function(fit, term = 1, estimate = 'slope') {
  fit <- tidy(fit)
  paste0('(', estimate, ' = ', myround(fit[term, 2], 2), 
        ', SE = ', myround(fit[term, 3], 2), 
        ', t = ', myround(fit[term, 4], 2), 
        ', p = ', myround(fit[term, 5], 2), ')')
}

print_lrt <- function(fit, term = 2, test = "Likelihood ratio test") {
  paste0(test, ': df = ', round(tidy(fit)[term, 3]), 
         ', ss = ', myround(tidy(fit)[term, 4], 2), 
         ', p = ', myround(tidy(fit)[term, 5], 2))
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
    coord_fixed(5.5/43.6, clip="off") +
    scale_shape_discrete(name = "Passage") +
    scale_color_manual(name = "Treatment",
                       labels = c('Neutral', 'Positive'),
                       values = c('gray40', 'darkorange2')) +
    theme_classic() +
    theme(panel.border = element_rect(fill = NA, size = 0.5),
          axis.line = element_blank())  
  

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

randomize_asv_table <- function(x) {
  x %>%
    uncount(count) %>%
    mutate(rand_asv = sample(asv)) %>%
    dplyr::select(-asv) %>%
    count(sample, rand_asv, name="value")
}


gm <- function(x){
  
  exp(mean(log(x[x>0])))
  
}

get_breakaway <- function(x){
  
  ba <- breakaway(x)
  tibble(est= ba$estimate,
         lci=ba$interval[1], uci=ba$interval[2],
         model=ba$model)
  
}

get_chao <- function(x){
  
  sobs <- sum(x$n)
  sing <- x[x$value == 1, "n"] %>% pull(n)
  doub <- x[x$value == 2, "n"] %>% pull(n)
  
  sobs + sing^2 / (2*doub)
  
}
richness <- function(x){
  
  # r <- sum(x > 0)
  # return(r)
  
  sum(x>0)
}
shannon <- function(x){
  
  rabund <- x[x>0]/sum(x)
  -sum(rabund * log(rabund))
  
}

simpson <- function(x){
  
  n <- sum(x)
  
  # sum(x * (x-1) / (n * (n-1)))
  1 - sum((x/n)^2)
}


log_methane <- function(x) {
  log10( x + abs(min(x, na.rm = TRUE)) + 1)
}


quart <- function(x) {
  x <- sort(x)
  n <- length(x)
  m <- (n+1)/2
  if (floor(m) != m) {
    l <- m-1/2; u <- m+1/2
  } else {
    l <- m-1; u <- m+1
  }
  c(Q1=median(x[1:l]), Q3=median(x[u:n]))
}

calc_plot_ratios <- function(x, y) (max(x) - min(x)) / (max(y) - min(y))

