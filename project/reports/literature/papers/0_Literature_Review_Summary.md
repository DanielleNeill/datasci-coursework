## Papers 1-9 Key Findings

The following highlights the key findings from this initial literature review

## Other models that could be incorporated in addition to time-series

1. Lam & Wang (2021) used Gaussian Process Regression (GPR) to show how modern statistical learning methods can outperform traditional demographic models
2. Tzitiridou-Chatzopoulou et al. (2024) used ARIMA but also compared Prophet, Random Forest, Extreme Gradient Boosting (XGBoost), Linear Regression & found ML techniques better than time-series

As a summary, this was Tzitiridou-Chatzopoulou et al. findings:

| Model                     | Performance |
| ------------------------- | ----------- |
| Extreme Gradient Boosting | Best        |
| Random Forest             | Very strong |
| Prophet                   | Good        |
| ARIMA                     | Moderate    |
| Linear Regression         | Worst       |

## Socio-Economic Factors to Consider

| Socio-economic factor                  | Evidence in literature              |
| -------------------------------------- | ----------------------------------- |
| Education level                        | Ermisch (2024), Kuang et al. (2024) |
| Family background / parents’ education | Ermisch (2024)                      |
| Employment / economic activity         | Berrington et al.                   |
| Housing & economic conditions          | POSTnote 745                        |
| Age / delayed childbearing             | Kulu et al., Berrington et al.      |
| Migration / country of birth           | Berrington et al.                   |
| Ethnicity                              | Berrington et al.                   |

* Fertility decline occurred across all education groups (Ermisch 2024)
* Childbearing is increasingly postponed to later ages (Kulu et al.)
* Fertility intentions are associated with age, education, economic activity, country of birth and ethnicity (Berrington et al.)

# Key Takeaways for our Project

The literature suggests that:

* Fertility trends are influenced by socioeconomic conditions
* Traditional time-series models remain strong baselines
* Machine learning methods may improve forecasts when relationships between births and economic variables are non-linear.

A non-linear relationship means that changes in a predictor (e.g., housing prices, unemployment) do not result in straight-line changes in the outcome (monthly births).

We can check for this by:

* Plotting predictors against births using `ggplot2::geom_smooth()` to see curves instead of straight lines.
* Use a partial dependence plot (`pdp` package) on a Random Forest or XGBoost model to visualize how each predictor affects the forecast in a non-linear way.

Note: We can include all socio-economic factors in our ML models, because methods like Random Forest and XGBoost can automatically handle a mix of linear and non-linear relationships.

## Likelihood of consistent linear relationships

* Education level / Parents’ education – Effects on fertility often plateau (e.g., fertility rates drop with higher education but only up to a point) → likely non-linear.
* Employment / economic activity – The impact may vary at different levels of employment or income; could be threshold effects → non-linear.
* Housing & economic conditions – Fertility may drop sharply when housing becomes unaffordable, then level off → clearly non-linear.
* Age / delayed childbearing – Fertility rates accelerate or decline at different ages → non-linear.
* Migration / country of birth – Interaction with cultural factors may create non-linear patterns.
* Ethnicity – Effects may differ across groups in non-proportional ways → non-linear.

We could provide supporting evidence for non-linear relationships using information from the literature to justify including ML models.

## Proposal on Initial Literature Review Findings

Given this literature review, we could:
1. Extend the project to incorporate machine learning (ML) methods alongside traditional time-series models. Studies such as Lam & Wang (2021) and Tzitiridou-Chatzopoulou et al. (2024) demonstrate that modern statistical learning techniques, including Gaussian Process Regression, Random Forest, and XGBoost, can outperform classical demographic and ARIMA-based forecasts, particularly when relationships between fertility and socio-economic variables are non-linear.
2. In our study, we could show non-linear effects using exploratory analyses such as scatter plots, and correlation diagnostics to identify thresholds, interactions, or non-proportional relationships.
3. Key socio-economic factors—including education, employment, housing affordability, age at childbirth, migration, and ethnicity could be incorporated as predictors in ML models, enabling the capture of both linear and non-linear influences.
4. The performance of these models could be compared against seasonal naïve, ETS, SARIMA, and ARIMAX benchmarks to assess whether ML approaches provide additional explanatory power in forecasting monthly birth counts in Northern Ireland.

## Feasibility of Recommended ML Methods

I asked AI which ML methods are realistic for our small group:

| Method                                | Feasibility for a small R team | Notes                                                                                                                                                 |
| ------------------------------------- | ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Random Forest**                     | ✅ High                         | Well-supported in R via `randomForest` or `ranger` packages. Handles non-linearities automatically. Relatively fast to train on monthly birth data.   |
| **XGBoost / Gradient Boosting**       | ✅ Moderate                     | R package `xgboost` is available, but requires some tuning (learning rate, tree depth). May need a bit more time to optimize and prevent overfitting. |
| **Gaussian Process Regression (GPR)** | ⚠️ Low                         | `kernlab::gausspr` exists, but GPR scales poorly with data size and can be slow. More complex for parameter tuning and interpretation.                |
| **Neural Networks (MLP / LSTM)**      | ⚠️ Moderate                    | `keras` or `nnet` can implement MLPs. LSTMs are more complex and may be overkill for monthly birth data unless sequence patterns are crucial.         |
