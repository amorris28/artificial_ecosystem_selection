## Power Analysis
## Andrew Morris
## 10/8/18

library(pwr)

ss <- NULL
es <- .10
sig <- 0.05
pow = 0.80


pwr.t.test(power = pow, sig.level = sig, d = 0.5, n = NULL, type = "two.sample")


power_function <- function(ES, beta, n, sigma, alpha) {
  if(beta == NULL) 
    (ES * alpha * sqrt(n)) / sigma
  if(ES == NULL)
}