library(ISLR)
attach(Wage)

fit.lm=lm(wage~poly(age, 4, raw=T), data=Wage)
coef(summary(fit.lm))

fit.lm2 = lm(wage~age+I(age^2)+I(age^3)+I(age^4), data=Wage)
coef(fit.lm2)

fit.lm2a = lm(wage~cbind(age, age^2, age^3, age^4), data=Wage)
coef(fit.lm2a)

# Predict the values using fit.lm
agelims = range(age)
age.grid = seq(from=agelims[1], to=agelims[2])
preds = predict(fit.lm, newdata=data.frame(age=age.grid), se=T)
se.bands = cbind(preds$fit + 2 * preds$se.fit, preds$fit - 2 * preds$se.fit)

# Plot
par(mfrow=c(1, 2), mar=c(4.5, 4.5, 1, 1), oma=c(0, 0, 4, 0))
plot(age, wage, col="darkgrey", cex=0.5, xlim=agelims)
title("Degree-4 Polynomial", outer=T)
lines(age.grid, preds$fit, col="blue", lwd=2)
matlines(age.grid, se.bands, lwd=1, lty=3, col="blue")

# Find the best degree polynomial using anova() function
fit.1 = lm(wage ~ age, data=Wage)
fit.2 = lm(wage ~ poly(age, 2), data=Wage)
fit.3 = lm(wage ~ poly(age, 3), data=Wage)
fit.4 = lm(wage ~ poly(age, 4), data=Wage)
fit.5 = lm(wage ~ poly(age, 5), data=Wage)
anova(fit.1, fit.2, fit.3, fit.4, fit.5)

# Classification using polynomial fit
fit.glm = glm(I(wage>250)~poly(age, 4), data=Wage, family=binomial)
preds = predict(fit.glm, newdata=data.frame(age=age.grid), se=T)
pfits = exp(preds$fit) / (1 + exp(preds$fit))
se.bands.logit = cbind(preds$fit + 2 * preds$se.fit, preds$fit - 2 * preds$se.fit)
se.bands = exp(se.bands.logit) / (1 + exp(se.bands.logit))

# Finally plot classification
plot(age, I(wage>250), xlim=agelims, type="n", ylim=c(0, 0.2))
points(jitter(age), I((wage>250)/5), cex=0.5, pch="|", col="darkgrey")
lines(age.grid, pfits, col="blue", lwd=2)
matlines(age.grid, se.bands, lwd=1, col="blue", lty=3)

# Fit a step function to the data
table(cut(age, 4))
fit.lm = lm(wage~cut(age, 4), data=Wage)
coef(summary(fit.lm))

# Splines
library(splines)
fit.sp = lm(wage~bs(age, knots=c(25, 40, 60)), data=Wage)
preds = predict(fit.sp, newdata=list(age=age.grid), se=T)
se.bounds = preds$fit + cbind(2 * preds$se.fit, -2 * preds$se.fit)

plot(age, wage, col="grey")
lines(age.grid, preds$fit, lwd=2)
lines(age.grid, se.bounds[,1], lty="dashed")
lines(age.grid, se.bounds[,2], lty="dashed")

# We can use df to specify uniform knots for given degree of freedom
dim(bs(age, knots=c(25, 40, 60)))
dim(bs(age, df=6))
attr(bs(age, df=6), "knots") 

# Fit natural splines to data
fit2 = lm(wage~ns(age, df=4), data=Wage)
pred2 = predict(fit2, data.frame(age=age.grid), se=T)
lines(age.grid, pred2$fit, col="red", lwd=2)

# Fit smoothing spline
fit3 = smooth.spline(age, wage, df=16)
fit4 = smooth.spline(age, wage, cv=T)
fit4$df
plot(age, wage, col="darkgrey", pch=20)
lines(fit3, col="red", lwd=2)
lines(fit4, col="blue", lwd=2)
legend("topright", legend=c("16 DF", "6.8 DF"), col=c("red", "blue"), lwd=2, lty=1, cex=.8)

# Local regression using loess
plot(age, wage, col="darkgrey")
title("Local Regression")
fit = loess(wage~age, data=Wage, span=.2)
pred = predict(fit, data.frame(age=age.grid), se=T)
se.bounds = pred$fit + cbind(2 * pred$se.fit, -2 * pred$se.fit)
fit2 = loess(wage~age, data=Wage, span=0.5)
pred2 = predict(fit2, data.frame(age=age.grid), se=T)
se.bounds2 = pred2$fit + cbind(2 * pred2$se.fit, -2 * pred2$se.fit)
lines(age.grid, pred$fit, col="red", lwd=2)
lines(age.grid, pred2$fit, col="blue", lwd=2)
matlines(age.grid, se.bounds, col="red", lty="dashed", lwd=1)
matlines(age.grid, se.bounds2, col="blue", lty="dashed", lwd=1)

# Using GAM
gam1=lm(wage ~ ns(year ,4)+ns(age ,5) +education ,data=Wage)
# Now smooth spline can not be used for lm.
library(gam)
gam.m3 = gam(wage~s(age, 5)+s(year, 4)+education, data=Wage)
par(mfrow=c(1, 3))
plot(gam.m3, se=T, col="blue")
plot.gam(gam1, se=T, col="red")
summary(gam.m3)
pred = predict(gam.m3, Wage)

# Use Local Regression with GAM
gam.lo = gam(wage~s(year, df=4) + lo(age, span=0.7) + education, data=Wage)
plot.gam(gam.lo, se=T, col="green")

# Use lo to capture interaction between terms
gam.lo.i = gam(wage ~ lo(year, age, span=0.5) + education, data=Wage)
library(akima)
plot(gam.lo.i)

# GAM can also be used to predict binary response
gam.lr = gam(I(wage>250)~year+s(age, 5)+education, data=Wage, family=binomial)
par(mfrow=c(1, 3))
plot(gam.lr, se=T, col="green")
# No high earners for <HS
table(education, I(wage>250))

# Ignore educations
gam.lr = gam(I(wage>250)~year+s(age, 5)+education, data=Wage, 
             family=binomial, subset=(education != "1. < HS Grad"))
plot(gam.lr, se=T, col="red")