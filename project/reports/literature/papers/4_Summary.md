_Robust Non-Parametric Mortality and Fertility Modelling and Forecasting: Gaussian Process Regression Approaches_

## Abstract

A rapid decline in mortality and fertility has become major issues in many developed countries over the past few decades. An accurate model for forecasting demographic movements is important for decision making in social welfare policies and resource budgeting among the government and many industry sectors. This article introduces a novel non-parametric approach using Gaussian process regression with a natural cubic spline mean function and a spectral mixture covariance function for mortality and fertility modelling and forecasting. Unlike most of the existing approaches in demographic modelling literature, which rely on time parameters to determine the movements of the whole mortality or fertility curve shifting from one year to another over time, we consider the mortality and fertility curves from their components of all age-specific mortality and fertility rates and assume each of them following a Gaussian process over time to fit the whole curves in a discrete but intensive style. The proposed Gaussian process regression approach shows significant improvements in terms of forecast accuracy and robustness compared to other mainstream demographic modelling approaches in the short-, mid- and long-term forecasting using the mortality and fertility data of several developed countries in the numerical examples.

## Objective

This paper proposes an advanced non-parametric forecasting approach for fertility and mortality time-series, demonstrating how machine learning–style statistical models can improve demographic forecasts.

It is relevant as a methodological comparison to classical time-series models (SARIMA/ETS).

## Models Used

* Gaussian Process Regression (GPR)
* Natural cubic spline mean function
* Spectral mixture covariance kernel

## Best Performing Model

The Gaussian Process Regression model with spectral mixture kernel produced the best forecasts.

## Why It Performed Best

* Captures non-linear demographic trends
* Models temporal dependence flexibly
* Provides probabilistic prediction intervals

## Key Findings

* GPR produced robust fertility forecasts across multiple demographic datasets.
* Non-parametric approaches performed well when structural demographic patterns change over time.

## Relevance to Our Project

Shows how modern statistical learning methods can outperform traditional demographic models, highlighting potential future extensions beyond classical time-series models.

## IEEE Reference

K. K. Lam and B. Wang, ‘Robust Non-Parametric Mortality and Fertility Modelling and Forecasting: Gaussian Process Regression Approaches’, Forecasting, vol. 3, no. 1, pp. 207–227, Mar. 2021, doi: 10.3390/forecast3010013.
