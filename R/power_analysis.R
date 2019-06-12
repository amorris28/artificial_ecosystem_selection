## Power Analysis
## Andrew Morris
## 10/8/18

library(tidyverse)
library(pwr)

sam_siz <- NULL
eff_siz <- .10
sig <- 0.05
pow = 0.80


pwr.t2n.test(n1 = 8, n2 = 8*3, power = 0.8, sig.level = 0.05, d = NULL)
# d = 1.2

pwr.t2n.test(n1 = 8, n2 = 8, power = 0.8, sig.level = 0.05, d = NULL)
# d = 1.5

pwr.t.test(n = NULL, power = 0.8, sig.level = 0.05, d = 0.5)

pwr.anova.test(k = 4, n = 8, f = NULL, sig.level = 0.05, power = 0.8)

pwr.t.test(n = 8, d = NULL, sig.level = 0.05, power = 0.8)

qplot(rlnorm(1000, meanlog = 1.6))

(2.25-(2.25*1.75))/ 1.11
(20-19)/10
20-(1.5*10)