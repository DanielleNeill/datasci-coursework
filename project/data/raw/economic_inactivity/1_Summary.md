
Predictor Assessment Criteria

|Criterion|Assessment|Suitability|
|---|---|---|
|**Data availability / Source reliability**|ONS Labour Market Statistics — official LFS time series for Northern Ireland females|High|
|**Frequency**|Quarterly (rolling 3-month averages), can be interpolated to monthly|Very useful|
|**Time coverage (2006–2025)**|Available — historical series from 1992–2026, subset for project period|Yes|
|**Theoretical relevance**|Strong — female labour market participation affects fertility timing and parity decisions|Yes|
|**Previous research use**|Yes — employment/inactivity widely used in fertility and demographic studies|Yes|
|**Missing values**|None reported in official series|Yes|
|**Bias / Representativeness**|Standard LFS methodology; seasonal adjustments applied; minimal bias|Acceptable|
# 1. Predictor Needs

Your variable of interest is:

**Female Economic Inactivity Rate (or Female Employment Rate)**

Economic inactivity typically means people **not in employment and not actively seeking work**, including:

- Students
- Homemakers
- Long-term sick or disabled
- Retired early
- Other inactive groups

This variable is theoretically relevant because research shows **economic security strongly affects fertility timing and parity decisions**.

The literature source (Ann Berrington et al., 2023) supports the inclusion of economic activity/employment status as a determinant of fertility behaviour.

The paper by Fleckenstein, T. and Lee, S. (2023) strongly supports using female inactivity or labour market exclusion as a predictor for fertility:

- It shows a clear causal mechanism between employment insecurity/outside status and fertility reduction.
- Female Inactivity Rate is an appropriate, measurable proxy for this phenomenon at the country level.
- Raw employment or income alone would not capture the structural and perceived barriers highlighted in the study.

# 2. Dataset Source

**ONS Labour Market Statistics — LFS Time Series (Northern Ireland, Females, Aged 16–64)**

- Series ID: **LF62**
- URL: [https://www.ons.gov.uk/employmentandlabourmarket/peopleinwork/employmentandemployeetypes/timeseries/lf62/lms](https://www.ons.gov.uk/employmentandlabourmarket/peopleinwork/employmentandemployeetypes/timeseries/lf62/lms?utm_source=chatgpt.com)

**Notes:**

- Provides female employment rate by age 16–64 in NI.
- Use together with female unemployment rate to compute inactivity:

$$
\text{Female Inactivity Rate (\%)} = 100 - \text{Female Employment Rate (\%)} - \text{Female Unemployment Rate (\%)}
$$

|Metric|Usefulness for fertility forecasting|Recommendation|
|---|---|---|
|Female Employment Rate|Partial info, does not capture non-working inactive women|Not ideal alone|
|Female Unemployment Rate|Only captures active job seekers|Not ideal alone|
|**Female Inactivity Rate**|Captures all women outside the labour market; directly linked to fertility decisions|**Use this**|
- Can be downloaded as CSV/XLS and filtered for 2006–2025.

### Sources to support age range to use

[1] Office for National Statistics, “User guide to birth statistics,” ONS, London, UK. Available: https://www.ons.gov.uk

[2] World Health Organization, “Total fertility rate – indicator definition,” WHO Global Health Observatory. Available: https://www.who.int

*The analysis focuses on women aged 16–44, approximating the standard reproductive age range used in demographic statistics. The Office for National Statistics defines the General Fertility Rate as the number of live births per 1,000 women aged 15–44, representing the population most at risk of childbearing (ONS, 2024). International organisations such as the World Health Organization also define fertility indicators using age-specific fertility rates for women aged 15–49.*

https://www.ons.gov.uk/peoplepopulationandcommunity/birthsdeathsandmarriages/livebirths/bulletins/birthsummarytablesenglandandwales/2024refreshedpopulations/previous/

https://www.who.int/data/gho/indicator-metadata-registry/imr-details/123

Therefore select '*Age - 19 Categories'* and prepare in R to match the typical categories that represent fertility rate in woman as described above.

*The reproductive-age population was derived by aggregating females aged 15–19, 20–24, 25–29, 30–34, 35–39, and 40–44 from the NISRA census age-band dataset. These five-year age groups correspond to the standard age-specific fertility rate intervals used in demographic analysis. The aggregated population approximates the standard reproductive-age definition (15–44) used in UK fertility statistics.*

$$
\text{Female Inactivity Rate} = \frac{\text{Inactive females (15-44)}}{\text{Total females (15-44)}}
$$
# 3. Dataset Summary
| Criterion      | Assessment                                                      |
| -------------- | --------------------------------------------------------------- |
| Source         | ONS Labour Market Statistics (LF62)                             |
| Frequency      | Quarterly (rolling 3-month average), can interpolate to monthly |
| Time coverage  | 1992–2026 (subset 2006–2025 for project)                        |
| Missing values | None reported                                                   |
| Bias           | Minimal; seasonal adjustments applied                           |
| Suitability    | Suitable for forecasting as primary predictor                   |
Decision: Use as **primary predictor** for forecasting models (ARIMAX, ETS with regressors).

# 4. Suitability with other ML Models

|Aspect / Step|Time-Series Models (ARIMAX, SARIMA)|Random Forest|XGBoost / Gradient Boosting|
|---|---|---|---|
|**Input type**|Single-variable or multivariate time series; expects temporal order|Tabular dataset; temporal order not explicitly encoded|Tabular dataset; temporal order not explicitly encoded|
|**Temporal structure**|Explicitly models trend, seasonality, autocorrelation|Must create features to capture temporal dependencies (lags, rolling averages)|Same as RF; lagged features and rolling statistics required|
|**Feature engineering**|Optional macroeconomic predictors added directly|Lagged birth counts (`t-1, t-2…`), lagged macroeconomic indicators|Same as RF; can also include interaction terms or engineered features|
|**Seasonality**|Handled by model (SARIMA seasonal component, ETS)|Must create seasonal indicators (month, quarter, cyclic features)|Same as RF|
|**Scaling / normalization**|Usually not required|Not strictly required but improves distance-based splits (especially if combining different scales)|Not strictly required; boosting is scale-invariant, but normalization can help with regularization|
|**Handling missing data**|May require imputation|Impute missing values or drop rows|Impute missing values or drop rows|
|**Prediction horizon**|Naturally aligned to time series forecasting (next month)|Align features with target variable; use sliding window for multi-step forecasting|Same as RF|
|**Output**|Predicted numeric birth counts|Predicted numeric birth counts|Predicted numeric birth counts|
|**Advantages**|Explicitly models autocorrelation and seasonality|Captures non-linear relationships, robust to correlated features|Captures complex non-linear relationships, handles interactions well, high predictive performance|
|**Key requirement to match time-series context**|None; model designed for temporal data|Must transform time series into supervised learning dataset (lagged features, rolling stats, seasonal dummies)|Same as RF|