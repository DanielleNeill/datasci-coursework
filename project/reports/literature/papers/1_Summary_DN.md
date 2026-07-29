# Predicting Future Birth Rates with the Use of an Adaptive Machine Learning Algorithm: A Forecasting Experiment for Scotland

**Authors:**
Tzitiridou-Chatzopoulou, M., Zournatzidou, G. and Kourakos, M. 

**Year:**
2024

**Source:**
International Journal of Environmental Research and Public Health

**Dataset / Study Area:**
Monthly birth registrations in Scotland from January 1998 to December 2022, 
sourced from the National Records of Scotland (www.nrscotland.gov.uk).

---

## Research Objective

This study aims to forecast monthly birth registrations in Scotland and 
compare the predictive performanceof several machine learning algorithms and traditional statistical methods. 

The goal is to improve the accuracy of birth rate predictions and support policymakers
in anticipating demographic shifts and future resource needs.

---

## Methodology

The study compares several forecasting approaches using both machine learning and traditional statistical models.

Models evaluated include:

- **Random Forest** – an ensemble learning method combining multiple decision trees to improve prediction accuracy through randomness in data and feature selection.
- **Extra Trees Regression** – similar to Random Forest but introduces additional randomness in tree construction to reduce overfitting.
- **Extreme Gradient Boosting (XGBoost)** – a scalable tree boosting algorithm designed to optimise predictive performance while controlling model complexity.
- **Prophet** – a time-series forecasting model that uses linear regression for trend modelling and Fourier series to capture seasonal patterns.
- **Linear Regression**
- **ARIMA (Autoregressive Integrated Moving Average)** – a traditional econometric time-series forecasting model.

### Evaluation Metrics

Model performance was evaluated using:

- Root Mean Square Error (**RMSE**)
- Mean Absolute Error (**MAE**)
- Symmetric Mean Absolute Percentage Error (**SMAPE**)

---

## Data

The dataset consists of monthly birth registrations in Scotland from **January 1998 to December 2022**, obtained from the **National Records of Scotland**.

Key preprocessing and analysis steps include:
- A **logarithmic transformation** was applied to stabilise variance in the data.
- A **nonparametric unit root test** indicated non-stationarity in the time series.
- Descriptive statistics showed a mean logarithmic birth value of **8.381** with a standard deviation of **0.429**, indicating an asymmetric and leptokurtic distribution.

The analysis also suggests that **COVID-19 may have influenced birth rates**, potentially due to economic uncertainty affecting family planning decisions.

---

## Key Findings

The study used **one-step-ahead out-of-sample forecasting** with a rolling estimation window of 24 observations.

The dataset was divided into:

- **80% training data**
- **20% testing data**

Hyperparameters and lag structures were optimised through **cross-validation**.

Forecasting was conducted in **R**, using packages including:

- `timetk`
- `tidymodels`
- `lubridate`
- `modeltime`

A **Model Confidence Set (MCS)** approach was used to compare models and identify those with statistically superior performance.

Main results:

- **XGBoost achieved the highest forecasting accuracy**
- **Prophet and Random Forest also performed well**
- **Linear Regression produced the weakest results**

---

## Conclusion

The study demonstrates that **machine learning algorithms can significantly improve the accuracy of birth rate forecasts compared with traditional statistical models**.

Accurate forecasting of birth trends has implications across several areas including:

- demographic research
- healthcare planning
- economic policy
- environmental sustainability

Reliable forecasts allow policymakers to better plan for future demand in **healthcare, education, and social welfare services**.

The authors suggest future research could further improve forecasting accuracy by incorporating **additional explanatory variables and more advanced machine learning techniques**.

---

## Relevance to Our Project
Our project aims to forecast monthly birth counts in **Northern Ireland** and evaluate whether **macroeconomic indicators improve predictive performance**.

This study is relevant as it demonstrates how machine learning models can improve birth rate forecasting. 
Scotland provides a useful comparison case due to similarities with Northern Ireland, including:
- relatively small population sizes
- declining fertility rates
- ageing populations
- similar socioeconomic pressures.

### Demographic Similarities

Both regions show:

- slowing population growth
- declining birth rates over the past decade
- increasing pressure on healthcare and social systems.

Common fertility patterns include:

- delayed childbirth
- fewer second or third children
- declining births among younger age groups.

These factors highlight the importance of accurate birth forecasting for long-term policy planning.

### Economic and Social Context

Both regions share similar economic characteristics:

- exposure to UK-wide economic cycles
- regional inequalities relative to England
- rising housing and childcare costs
- relatively large public sector employment.

These conditions can influence fertility decisions, suggesting that **macroeconomic variables may improve forecasting models**.

### Methodological Relevance

The study demonstrates that machine learning models such as **XGBoost and Random Forest** can outperform traditional statistical approaches when forecasting birth trends.

This supports the inclusion of advanced modelling techniques within our analysis.

Additionally, the research highlights the importance of incorporating external socioeconomic predictors, including:

- housing prices
- cost-of-living indicators
- childcare costs
- unemployment rates.

These findings help justify the use of **ARIMAX models**, which extend ARIMA time-series forecasting by incorporating **exogenous variables** such as macroeconomic indicators.

By comparing standard time-series models with models that include macroeconomic predictors, our research aims to determine whether these additional variables improve the forecasting of birth trends in Northern Ireland.

---

## IEEE Reference

Tzitiridou-Chatzopoulou, M., Zournatzidou, G. and Kourakos, M. (2024)  
*Predicting Future Birth Rates with the Use of an Adaptive Machine Learning Algorithm: A Forecasting Experiment for Scotland*.  
International Journal of Environmental Research and Public Health, 21(7), p. 841.  
https://doi.org/10.3390/ijerph21070841