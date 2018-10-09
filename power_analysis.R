## Power Analysis
## Andrew Morris
## 10/8/18

library(tidyverse)
library(pwr)

ss <- NULL
es <- .10
sig <- 0.05
pow = 0.80


pwr.t.test(power = pow, sig.level = sig, d = 0.5, n = NULL, type = "two.sample")


qplot(rlnorm(1000, meanlog = 1.6))


