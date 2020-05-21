library(rstan)
library(tidyverse)

data <- read_tsv('./Output/fluxes.tsv')
rank_fit <- lm(estimate_rank ~ treat * passage, data = data)

sel_sum <- tidy(summary(rank_fit))
sel_aov <- tidy(anova(rank_fit))

ggplot(data, aes(y = estimate, x = passage, color = treat)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE)

srr_block <- "
data { 
    int<lower=1> N;               // Number of observations
    int<lower=1> nX;               // Number of predictors
    matrix [N,nX] X;
    vector[N] y;                  // Methane flux values
}
parameters {
    vector[nX] beta;
    real<lower=0> sigma;
}
transformed parameters {
  vector[N] mu;

  mu = X*beta;
  }
model {
    y ~ cauchy(mu, sigma);
    sigma ~ normal(0, 10);
}"

Xmat <- model.matrix(~treat * passage, data)
data.list <- with(data, list(y = estimate, X = Xmat, nX = ncol(Xmat), N = nrow(data)))

data.rstan <- stan(model_code = srr_block,
                            data = data.list, 
                            iter=1e3)

print(data.rstan, par = c("beta", "sigma"))

stan_trace(data.rstan)

mcmc = as.data.frame(data.rstan) %>% dplyr:::select(contains("beta"),
                                                    sigma) %>% as.matrix
# generate a model matrix
newdata = data
Xmat = model.matrix(~treat * passage, newdata)
## get median parameter estimates
coefs = apply(mcmc[, 1:4], 2, median)
fit = as.vector(coefs %*% t(Xmat))
resid = data$estimate - fit
ggplot() + geom_point(data = NULL, aes(y = resid, x = fit))


mcmc = as.data.frame(data.rstan) %>% dplyr:::select(contains("beta"),
                                                    sigma) %>% as.matrix
# generate a model matrix
newdata = newdata
Xmat = model.matrix(~treat * passage, newdata)
## get median parameter estimates
coefs = apply(mcmc[, 1:4], 2, median)
fit = as.vector(coefs %*% t(Xmat))
resid = data$estimate - fit
newdata = newdata %>% cbind(fit, resid)
ggplot(newdata) + geom_point(aes(y = resid, x = treat))
ggplot(newdata) + geom_point(aes(y = resid, x = passage))
ggplot(newdata) + geom_point(aes(y = resid, x = interaction(passage, treat)))


print(data.rstan, pars = c("beta", "sigma"))

library(broom)
tidyMCMC(data.rstan, conf.int = TRUE, conf.method = "HPDinterval", pars = c("beta", "sigma"))


mcmc = as.matrix(data.rstan)
## Calculate the fitted values
newdata = rbind(data.frame(treat = levels(as.factor(data$treat))))
Xmat = model.matrix(~treat, newdata)
coefs = mcmc[, c("beta[1]", "beta[2]", "beta[3]", "beta[4]")]
fit = coefs %*% t(Xmat)
 newdata = newdata %>% cbind(tidyMCMC(fit, conf.int = TRUE, conf.method = "HPDinterval"))

ggplot(newdata, aes(y = estimate, x = x)) + geom_linerange(aes(ymin = conf.low,
                                                               ymax = conf.high)) + geom_point() + scale_y_continuous("Y") + scale_x_discrete("X") +
  theme_classic()

fdata = rdata = data
fMat = rMat = model.matrix(~x, fdata)
fit = as.vector(apply(coefs, 2, median) %*% t(fMat))
resid = as.vector(data$y - apply(coefs, 2, median) %*% t(rMat))
rdata = rdata %>% mutate(partial.resid = resid + fit)

ggplot(newdata, aes(y = estimate, x = as.numeric(x) - 0.1)) + geom_blank(aes(x = x)) +
  geom_point(data = rdata, aes(y = partial.resid, x = as.numeric(x) +
                                 0.1), color = "gray") + geom_linerange(aes(ymin = conf.low, ymax = conf.high)) +
  geom_point() + scale_y_continuous("Y") + scale_x_discrete("") + theme_classic()