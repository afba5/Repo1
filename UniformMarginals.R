library(quantmod)
library(qrmtools)

df_BTC <- getSymbols('BTC-EUR',src='yahoo',auto.assign=FALSE, from = "2017-11-11",
                     to = "2024-05-10")
df_ETH <- getSymbols('ETH-EUR',src='yahoo',auto.assign=FALSE, from = "2017-11-11",
                     to = "2024-05-10")

BTC_ETH <- cbind(df_BTC$`BTC-EUR.Adjusted`,df_ETH$`ETH-EUR.Adjusted`)
colnames(BTC_ETH) <- c("BTC-EUR","ETH-EUR") 

R_BTCETH <- returns(BTC_ETH) # calculate log-returns 

library(rugarch)

# For BTC:
# GARCH Model	: eGARCH(3,4) 
# Mean Model	: ARFIMA(0,0,0) WITH MEAN
# Distribution	: sstd

ctrl = list(RHO = 1,DELTA = 1e-8,MAJIT = 100,MINIT = 650,TOL = 1e-6)
## Specify model: ARMA(0,0)-eGARCH(3,4) WITH MEAN and skew Student t innovations
spec_BTC = ugarchspec(variance.model = list(model="eGARCH",garchOrder = c(3, 4)),mean.model = list(armaOrder = c(0,0),include.mean=TRUE),distribution.model = "sstd") 
## Fit marginal ARMA-GARCH model for BTC-EUR returns
garch.fit_BTC = ugarchfit(data = R_BTCETH$`BTC-EUR`, spec = spec_BTC, solver = "solnp", solver.control = ctrl)
## Extract standardized residuals
residuals_BTC <- residuals(garch.fit_BTC,standardize=TRUE)

# For ETH:
# GARCH Model	: eGARCH(4,3) 
# Mean Model	: ARFIMA(0,0,0) WITH ZERO MEAN
# Distribution	: sstd 

## Specify model: ARMA(0,0)-eGARCH(4,3) WITH ZERO MEAN and skew Student t innovations
spec_ETH = ugarchspec(variance.model = list(model="eGARCH",garchOrder = c(4, 3)),mean.model = list(armaOrder = c(0,0),include.mean=FALSE),distribution.model = "sstd") 
## Fit marginal ARMA-GARCH model for ETH-EUR returns
garch.fit_ETH = ugarchfit(data = R_BTCETH$`ETH-EUR`, spec = spec_ETH, solver = "solnp", solver.control = ctrl)
## Extract standardized residuals
residuals_ETH <- residuals(garch.fit_ETH,standardize=TRUE)

# Put together stand. residuals from BTC and ETH ARMA-GARCH models
residuals_BTCETH <- cbind(residuals_BTC,residuals_ETH)
colnames(residuals_BTCETH) <- c("residuals_BTC","residuals_ETH")
# Convert to data frame for plotting
df_residuals_BTCETH <- fortify.zoo(residuals_BTCETH)

# Transform standardized residuals into observations in the interval [0,1]
library(copula)
U <- pobs(df_residuals_BTCETH[,-1])

# Plot uniform marginals
par(pty="s") # to make the plot region square
plot(U, xlab = expression(u["1"]), ylab = expression(u["2"]))

