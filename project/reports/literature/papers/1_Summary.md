_Predicting Future Birth Rates with the Use of an Adaptive Machine Learning Algorithm: A Forecasting Experiment for Scotland_

## Abstract

The total fertility rate is influenced over an extended period of time by shifts in population socioeconomic characteristics and attitudes and values. However, it may be impacted by macroeconomic trends in the short term, although these effects are likely to be minimal when fertility is low. With the objective of forecasting monthly deliveries, this study concentrates on the analysis of registered births in Scotland. Through this approach, we examine the significance of precisely forecasting fertility trends, which can subsequently aid in the anticipation of demand in diverse sectors by allowing policymakers to anticipate changes in population dynamics and customize policies to tackle emerging demographic challenges. Consequently, this has implications for fiscal stability, national economic accounts and the environment. In conducting our analysis, we incorporated non‐linear machine learning methods alongside traditional statistical approaches to forecast monthly births in an out‐of‐sample exercise that occurs one step in advance. The outcomes underscore the efficacy of machine learning in generating precise predictions within this particular domain. In sum, this research will comprehensively demonstrate a cutting‐edge model of machine learning that utilizes several attributes to assist in clinical decision‐making, predict potential complications during pregnancy and choose the appropriate delivery method, as well as help in medical diagnosis and treatment.

## Conclusion

In this paper, we predict births in Scotland in a one‐step‐ahead out‐of‐sample univariate forecasting exercise. Predicting birth rates holds significant importance across various fields due to its wide‐ranging implications. Effectively and accurately predicting future births can affect demography and public health, as it can enable policymakers and healthcare professionals to anticipate population growth or decline, thereby informing decisions regarding resource allocation for healthcare services, education, and social welfare programs. Additionally, in economics and business, projections of birth and fertility rates provide critical insights into future consumer demographics, labor force dynamics, and market trends, influencing investment strategies, workforce planning, and product development. Moreover, in environmental science and sustainability, understanding population growth patterns is essential for assessing the impact on natural resources, biodiversity, and ecosystems, guiding efforts toward sustainable development. Overall, the ability to predict births facilitates informed decision‐making and strategic planning across a spectrum of fields, contributing to the well‐being and sustainability of societies and ecosystems. Future research on this topic could focus on the examination of more sophisticated machine learning and deep learning algorithms that can better capture the dynamics of these specific data. Furthermore, additional predictors could be considered that relate to factors that affect birth rate and fertility rate to improve the out‐of‐sample forecasts of the machine learning approaches.

## Objective

Forecast monthly birth counts using machine learning and traditional time-series models to evaluate forecasting accuracy.

The study emphasises the importance of accurate fertility forecasts because they allow policymakers to anticipate “changes in population dynamics and customize policies to tackle emerging demographic challenges.”

## Data and Methodology

* Monthly birth data (Scotland)
* Train/test split: 80–20
* Rolling estimation window: 24 observations
* Lagged birth features: 1–12 months (Window sizes of 1, 3, 6, 9 and 12, months were used with the value chosen as 12)
* Hyperparameters tuned using cross-validation

Evaluation metrics:

* MAE
* RMSE
* SMAPE

## Models Tested

**Traditional models**

* ARIMA

**Machine learning models**

* Prophet
* Random Forest
* Extreme Gradient Boosting (XGBoost)
* Linear Regression

## Best Performing Models (see Table 2)

| Model                     | Performance |
| ------------------------- | ----------- |
| Extreme Gradient Boosting | Best        |
| Random Forest             | Very strong |
| Prophet                   | Good        |
| ARIMA                     | Moderate    |
| Linear Regression         | Worst       |

Results show that XGBoost achieved the lowest forecasting error, followed closely by Random Forest.

## Key Findings

* Machine learning models outperform traditional time-series models.
* Tree-based models capture non-linear patterns in birth trends.
* Birth data exhibits strong seasonality, making lag structures important.

## Relevance to Our Project

This paper is very relevant because it directly addresses forecasting monthly births, which is the main objective of the project.

Implications for our project:

1. Confirms that time-series forecasting models are appropriate for birth data.
2. Suggests testing machine learning models alongside traditional methods.
3. Supports using lagged birth variables (up to 12 months) to capture seasonality.

### IEEE Reference

M. Tzitiridou-Chatzopoulou, G. Zournatzidou, and M. Kourakos, ‘Predicting Future Birth Rates with the Use of an Adaptive Machine Learning Algorithm: A Forecasting Experiment for Scotland’, IJERPH, vol. 21, no. 7, p. 841, Jun. 2024, doi: 10.3390/ijerph21070841.
