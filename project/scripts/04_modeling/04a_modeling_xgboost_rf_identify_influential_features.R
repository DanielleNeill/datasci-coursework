# Some useful references which help shape the approach in this file:
# https://campus.datacamp.com/courses/machine-learning-with-tree-based-models-in-r/
# Chapter 7, 10 & 11 of Tidy Modeling with R by Max Kuhn, Julia Silge, 2022.
# We needed something that would allow us to run the XGBoost and RF evaluation together and tidymodels seemed
# a suitable way forward with yardstick to gather the metrics we were assessing on.

install.packages("tidyverse")
install.packages("tidymodels")
install.packages("xgboost")
install.packages("yardstick")
install.packages("ranger")

library(tidyverse)  # Data manipulation & visualization common packages (dplyr, ggplot2)
library(tidymodels) # Unified framework for machine learning workflows and resampling - for our RF & XGBoost comparison
library(ranger)     # Implementation of Random Forest for our model comparisons
library(xgboost)    # Gradient boosting engine (XGBoost)
library(yardstick)  # Specialized tools for calculating metrics (MAE, RMSE, MAPE) agreed upon for our output.

# Standardise the randomness for reproducible results
set.seed(1)

# Summary of our team comparative proposal to apply a two-stage model comparison strategy for the prediction
# of NI birth rates.
#
# Goal: To ensure a fair assessment between ARIMA, RF, and XGBoost.
#
# Stage 1: Baseline the models using the raw predictors (no feature engineering).
# - Predictors: Raw Quarterly Employment Rate, House Prices, and Higher Education Participation (Interpolated).
# - Purpose:    To create a level playing field to test our core hypothesis and test if the raw data
#               prediction is strong enough without additional more complex processing / feature engineering.
#
# Stage 2: Evaluation of the optimised predictors (with feature engineering)
# - Predictors: Model-specific winning feature set (e.g., Lags, Volatility, Regimes, Momentum).
# - Purpose:    Assess the benefits of engineered features. Since Tree models lack ARIMA's
#               native temporal memory, this tests if ML with feature engineering can outperform traditional
#               time-series approaches.
#
# Evaluation Standards to Ensure Fairness
# - Timeline:   Use of the 2007–2024 window (approx. 69 quarters) for all models.
# - Validation: Identical Rolling Origin Control (initial=48, assess=4, skip=3).
# - Primary Metrics: Mean Absolute Error (MAE), Root Mean Square Error (RMSE) and Symmetric
#               Mean Absolute Percentage Error (SMAPE) averaged across 5 test folds.
#               --> To align with Tzitiridou-Chatzopoulou, M. et al. (2024) paper which used the same.
#
# Our Reasoning:
# - ARIMA:      By applying a Stage 1 we are not forcing ARIMA into using engineered features so that it
#               stays within the boundary of ARIMA's native statistical advantages.
# - RF/XGB:     With Stage 2 we are not handicapping these tree models with static raw data alone,
#               we can leverage the time-contextual features that suit tree models better.
# - Direct MAE/RMSE/SMAPE Comparison: By comparing Stage 1 vs Stage 2 metrics, we can prove whether
#               predictive success originates from raw predictors or from ML engineering.

# 1. Prepare the Datasets
# Load datasets using the path for merged features (raw and engineered).
model_features  <- read_csv("project/data/processed/merged_modeling_features_2007_2024.csv")

# This quick check is to verify the opportunity cost drops after 69% as this will drive later hypothesis
# Remember that the opportunity cost in this case is when career is the primary focus in life
# which results in an impact to ability to have children due to a focus on career. This was
# acknowledged in the data understanding section of CRISP-DM flow.
model_features %>%
  ggplot(aes(x = emp_at_conception, y = quarterly_births)) +
  geom_point() +
  geom_vline(xintercept = 69, linetype = "dashed", color = "red") + # Does it drop-off at 69%?
  geom_smooth(method = "lm") +
  labs(title = "Births vs Employment Intensity",
       subtitle = "Checking the 69% Opportunity Cost Tipping Point")
# Interpretation of this scatter chart:
# Shows a shift rather than a simple linear decline after 69%. While the blue regression line stays relatively flat,
# the density of the data points appears to reduce significantly after the 69% red dashed line. i.e. high-birth quarter
# numbers (6,000+) effectively vanish beyond this point (there are only 2 points beyond this threshold).
# --> include as part of the hypothesis assessment below, specifically for is_emp_peak_at_conception which uses the 69%.
# Note that ultimately this wasn't a strong predictor for our models but was an interesting theory to test - tree
# models sometimes, from what I have read, perform well using binary indicators, but emp_at_conception was
# ultimately more predictive on the Stage 2 assessment.

# 2. Add our group validation strategy - all 3 models (ARIMA/RF/XGBOOST) must follow the same strategy.
# Why? In time-series, a single split to train/test (say on a year such as 2022) is risky. Instead, 'assess = 4'
# creates 5 distinct test sets which are used to evaluate our ARIMA, RF, and XGBoost models.
# 1. Each model trains on 12 years (initial=48, so 48 quarters) and tests on the following year (assess=4).
#    The window then slides forward by 1 year (with skip=3).
# 2. Then an average MAE/RMSE/SMAPE is taken across all 5 test years.
#
# We are adjusting for the 2007-10-01 - 2024-10-01 timeline where data is consistently available (69 total rows)
# This is because we sacrificed 2 years of data for feature engineering for lag (and other) calculations in the
# data preparation steps for housing/education & employment rate (necessary to introduce concept of time to the data).
# If we let ARIMA use the additional data it has available for 2006, the error metrics (MAE/RMSE/SMAPE) produced
# would be based on a different historical context - this would make it impossible to say if XGBoost/RF are
# actually better or if ARIMA just had an advantage since it had more data to learn from.
# Therefore our common timeline is ~69 quarters (2007 Q4 start).
# We can use initial = 48 (12 years) to ensure we maintain 5 distinct test folds:
# Fold 1: Trains Q1–48 (2007–2019). Tests Q49–52 (2020).
# Fold 2: Trains Q1–52 (2007–2020). Tests Q53–56 (2021).
# Fold 3: Trains Q1–56 (2007–2021). Tests Q57–60 (2022).
# Fold 4: Trains Q1–60 (2007–2022). Tests Q61–64 (2023).
# Fold 5: Trains Q1–64 (2007–2023). Tests Q65–68 (2024).
# --> This will provide 5 distinct and non-overlapping test years.
# Ref: https://www.rdocumentation.org/packages/rsample/versions/1.3.2/topics/rolling_origin
# Ref: Max Kuhn, Julia Silge, 2022, Chapter 10 - Rolling Forecasting Origin Resampling
ts_folds <- rolling_origin(
  model_features, # Data starting on 2007-10-01
  initial    = 48,        # 12 years of training
  assess     = 4,         # 1 year of testing
  cumulative = TRUE,
  skip       = 3          # Slide by 1 year (1 natural + 3 skip)
)

# 3. Model Specifications (RF & XGBoost)

# XGBoost Specification
# Use a slower & shallower approach (with depth=3, learn_rate=0.01) to help prevent overfitting on our relatively small
# 69 row dataset where trees can correct errors more gradually.
# loss_reduction = 0.1 & sample_size = 0.8 is to add randomness to ensure it is less likely to rely on a
# specific sequence of dates.
xgb_spec <- boost_tree(
  trees = 500, tree_depth = 3, learn_rate = 0.01,
  loss_reduction = 0.1, sample_size = 0.8
) %>% set_engine("xgboost") %>% set_mode("regression")

# Random Forest Specification
# Ensure stability via averaging (with trees=500, min_n=5) to ensure more trees help smooth out the predictions and
# base them on groups of data points rather than single outliers (i.e. prevent the model from making rules based
# on just 1 or 2 data points.
rf_spec <- rand_forest(
  trees = 500, min_n = 5
) %>% set_engine("ranger", importance = "impurity") %>% set_mode("regression")

# 4. Define a range of meaningful socio-economic formulas to test to include:
# a. Data alignment: Use a 9-month (3-4Q) lags to match economic conditions at time of conception.
# b. Organize variables into our socio-economic theories, such as:
#    - Test the 69% Opportunity Cost threshold as noted in data understanding step (is_emp_peak_at_conception).
#    - Test price stability (ARIMAX best performers from Danielle) vs standardized cost.
# c. Limit the formulas to 2-3 variables to prevent the risk of overfitting on our smallish (~69 row)
#    dataset while also capturing cross-domain interactions.
model_formulas <- list(
  # Test the Socio-Economic hypothesis where 69% employment rate is a potential tipping point for opportunity cost
  opp_cost_threshold  = quarterly_births ~ emp_at_conception + is_emp_peak_at_conception,
  # Test for the income effect (financial security) vs. opportunity cost (career over kids)
  income_vs_time      = quarterly_births ~ emp_at_conception + emp_momentum_lag3 + emp_volatility_lag3,
  # Test using Danielle's ARIMAX best performers
  housing_arimax_lag  = quarterly_births ~ housing_lag4 + housing_diff_4q,
  housing_arimax_std  = quarterly_births ~ standardised_price + housing_diff_4q,
  # Test for Higher Education and the COVID impact and higher grades
  edu_socio_context   = quarterly_births ~ he_at_conception + is_edu_covid_grading,
  # Test a hybrid Socio-Economic mixture (i.e. something from each of our 3 predictors)
  hybrid_socio_economic_check  = quarterly_births ~ emp_at_conception + housing_diff_4q + is_edu_covid_grading,
  hybrid_socio_economic_check_alt  = quarterly_births ~ emp_at_conception + housing_diff_4q + fe_at_conception,
  # Test the interaction of housing costs spike & peak employment
  affordability_shock = quarterly_births ~ housing_diff_4q + is_emp_peak_at_conception,
  # Test if housing or employment momentum results in economic pressure that often causes people to delay conception.
  economic_anxiety    = quarterly_births ~ housing_volatility_4q + emp_momentum_lag3,
  # Test if COVID altered the relationship between higher education participation and births.
  edu_regime_shift    = quarterly_births ~ he_at_conception + is_edu_covid_grading,
  # Added this formula after first run of the above as ARIMA way outperforms all of these.
  # Justification is to use Danielle's best predictor (housing_lag4) with lagged employment to conception and
  # COVID grading to see if I can get any form of improvement, but it did not add an improvement (rank 11).
  # --> xgboost       arima_bridge                     456.  8.82  491.  8.33
  arima_bridge        = quarterly_births ~ housing_lag4 + is_emp_peak_at_conception + is_edu_covid_grading
)

# 5. Test/Evaluate our RF and XGBoost models
models_to_test <- list(xgboost = xgb_spec, random_forest = rf_spec)
# Call the function once for each of the models in the above list to gather results
comparison_results <- map_df(names(models_to_test), function(m_name) {
  spec <- models_to_test[[m_name]]
  # Now call a function for each of the above defined formulas
  map_df(names(model_formulas), function(f_name) {
    curr_formula <- model_formulas[[f_name]]
    # Reset seed so that every single formula starts with the same random element
    set.seed(1)
    # Run the Cross-Validation and collect the metrics we are interested in
    res <- workflow() %>%
      add_formula(curr_formula) %>%
      add_model(spec) %>%
      # We want the same metrics so we can compare against Tzitiridou-Chatzopoulou, M. et al. (2024) paper, who use
      # MAE/RMSE/SMAPE - also including MAPE just in case we also need it.
      # Ref: https://tune.tidymodels.org/reference/fit_resamples.html
      # This fits our rolling_origin folds (effectively data the model hasn't seen before) to train and test each model
      # Note, we could have taken this further and tuned the models beyond default hyperparameter settings
      # but due to time restrictions we decided that this was out of scope for this project.
      fit_resamples(resamples = ts_folds, metrics = metric_set(mae, rmse, mape, smape))

    collect_metrics(res) %>%
      mutate(model_engine = m_name, formula_name = f_name)
  })
})
# Note: although Max Kuhn, Julia Silge, 2022 book outlines how there workflows work well, I did employ
#       some help from AI for the above to help adjust the results into a format I needed when stuck.

glimpse(comparison_results)
# Rows: 88
# Columns: 8
# $ .metric      <chr> "mae", "mape", "rmse", "smape", "mae", "mape", "rmse", "smape", "m…
# $ .estimator   <chr> "standard", "standard", "standard", "standard", "standard", "stand…
# $ mean         <dbl> 336.054053, 6.687911, 390.431541, 6.356768, 388.143701, 7.720382, …
# $ n            <int> 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, …
# $ std_err      <dbl> 68.1534908, 1.4444950, 76.7432382, 1.3053938, 69.9105931, 1.488072…
# $ .config      <chr> "pre0_mod0_post0", "pre0_mod0_post0", "pre0_mod0_post0", "pre0_mod…
# $ model_engine <chr> "xgboost", "xgboost", "xgboost", "xgboost", "xgboost", "xgboost", …
# $ formula_name <chr> "opp_cost_threshold", "opp_cost_threshold", "opp_cost_threshold", …
View(comparison_results)
# Now we want to extract the result from the .metric column, with the associated value in the mean column:
# # $ .metric <chr> "mae", "mape", "rmse", "smape", "mae", "mape", "rmse", "smape", "m…

# 6. Results
# Rank the combinations to find the top performers for use in our Stage 2
ranking_table <- comparison_results %>%
  filter(.metric %in% c("mae", "rmse", "mape", "smape")) %>%
  # Organise the data so metrics are side-by-side for easy comparison in the ranking table
  select(model_engine, formula_name, .metric, mean) %>%
  pivot_wider(names_from = .metric, values_from = mean) %>%
  arrange(mae)

print("--- Top performing formulas per model engine ---")
print(n = 20, ranking_table)
#  model_engine    formula_name                     mae   mape  rmse smape
#    <chr>         <chr>                           <dbl> <dbl> <dbl> <dbl>
#  1 xgboost       hybrid_socio_economic_check      327.  6.42  373.  6.15
#  2 xgboost       hybrid_socio_economic_check_alt  329.  6.51  375.  6.23
#  3 xgboost       opp_cost_threshold               336.  6.69  390.  6.36
#  4 random_forest hybrid_socio_economic_check      347.  6.81  382.  6.54
#  5 xgboost       income_vs_time                   388.  7.72  446.  7.30
#  6 random_forest hybrid_socio_economic_check_alt  406.  8.04  463.  7.63
#  7 random_forest edu_socio_context                412.  8.11  459.  7.70
#  8 random_forest edu_regime_shift                 412.  8.11  459.  7.70
#  9 xgboost       edu_socio_context                447.  8.80  498.  8.34
# 10 xgboost       edu_regime_shift                 447.  8.80  498.  8.34
# 11 xgboost       arima_bridge                     456.  8.82  491.  8.33
# 12 random_forest housing_arimax_std               462.  9.05  509.  8.57
# 13 random_forest income_vs_time                   492.  9.77  541.  9.18
# 14 xgboost       housing_arimax_std               576. 11.2   623. 10.5
# 15 random_forest opp_cost_threshold               586. 11.6   625. 10.8
# 16 xgboost       housing_arimax_lag               588. 11.4   628. 10.7
# 17 random_forest housing_arimax_lag               589. 11.5   622. 10.8
# 18 random_forest arima_bridge                     632. 12.4   665. 11.6
# 19 xgboost       affordability_shock              672. 13.3   707. 12.3
# 20 random_forest affordability_shock              710. 14.0   743. 13.0

# --> hybrid_socio_economic_check is the best performing formula for both RF & XGBoost models (rank 1&4):
# Interpreting MAE: A lower MAE indicates a more accurate model, with a value of indicating a perfect fit.
# Interpreting RMSE: RMSE measures the average distance between predicted and actual values in the same units as the
# target variable, where a lower value indicates higher accuracy when compared across models using the same dataset.
# --> See https://www.datacamp.com/tutorial/rmse
# Interpreting SMAPE (see https://www.kaggle.com/code/sasakitetsuya/study-on-smape):
#   <10%: Highly accurate forecasting.
#   10%–20%: Good forecasting.
#   21%–50%: Reasonable forecasting.
#   >50%: Poor or inaccurate forecasting.
# This formula uses one predictor from each domain: emp_at_conception, housing_diff_4q, and is_edu_covid_grading.
# Formula: hybrid_socio_economic_check = quarterly_births ~ emp_at_conception + housing_diff_4q + is_edu_covid_grading,
# Accuracy: It has the lowest MAE = 327 with a SMAPE = 6.15.
#           As the RMSE = 373 is relatively close to the MAE, it suggests that it is consistently accurate across the
#           2007–2024 timeline.
# This shows that birth rates in Northern Ireland are not driven by a single factor, but by the intersection of
# employment, housing, and structural shifts (COVID).
# However, both perform much worse than Danielle's ARIMA which gave a mean MAE of about 163 across the 5 rolling folds.

# 7. Extract Feature Importance - which predictor was the most important?

# Fit the 'hybrid_socio_economic_check' to see which domain (Employment/Housing/Education) influences
# the predictions the most.
final_check_xgb <- workflow() %>%
  add_formula(model_formulas$hybrid_socio_economic_check) %>%
  add_model(xgb_spec) %>%
  fit(data = model_features)

final_check_rf <- workflow() %>%
  add_formula(model_formulas$hybrid_socio_economic_check) %>%
  add_model(rf_spec) %>%
  fit(data = model_features)

# Extract and visualise the influential predictors for XGBoost
# Ref: Chapter 6 of Max Kuhn, Julia Silge, 2022, 'Use the Model Results'

# We want to pull out the Gain here
final_check_xgb %>%
  extract_fit_engine() %>%
  xgb.importance(model = .) %>%
  as_tibble()
# # A tibble: 3 × 4
#   Feature                Gain  Cover Frequency
#   <chr>                 <dbl>  <dbl>     <dbl>
# 1 emp_at_conception    0.720  0.562     0.534
# 2 is_edu_covid_grading 0.182  0.0890    0.0601
# 3 housing_diff_4q      0.0980 0.349     0.406

final_check_xgb %>%
  extract_fit_engine() %>%
  xgb.importance(model = .) %>%
  as_tibble() %>%
  ggplot(aes(x = reorder(Feature, Gain), y = Gain, fill = Feature)) +
  geom_col(show.legend = FALSE) +
  coord_flip() +
  labs(title = "Socio-Economic Domain Importance (XGBoost)",
       subtitle = "Identifying the most influential signal from each dataset",
       x = "Engineered Predictor", y = "Relative Gain") +
  theme_minimal()
# In order of importance (emp_at_conception, is_edu_covid_grading, housing_diff_4q)

# Extract the importance scores from the ranger (RF) engine
# View the scores first before extracting them into a tibble.
rf_engine <- final_check_rf %>%
  extract_fit_engine()
importance(rf_engine)
#    emp_at_conception      housing_diff_4q is_edu_covid_grading
#              6596625              3989464              5084040

rf_importance <- final_check_rf %>%
  extract_fit_engine() %>%
  purrr::pluck("variable.importance") %>%
  enframe(name = "Feature", value = "Importance")
rf_importance
# A tibble: 3 × 2
#   Feature              Importance
#   <chr>                     <dbl>
# 1 emp_at_conception      6596625.
# 2 housing_diff_4q        3989464.
# 3 is_edu_covid_grading   5084040.

# Extract and visualise influential predictors for RF
rf_importance %>%
  ggplot(aes(x = reorder(Feature, Importance), y = Importance, fill = Feature)) +
  geom_col(show.legend = FALSE) +
  coord_flip() +
  labs(title = "Socio-Economic Domain Importance (RF)",
       subtitle = "Identifying the most influential signal from each dataset",
       x = "Engineered Predictor", y = "Relative Importance (Impurity)") +
  theme_minimal()
# In order of importance (emp_at_conception, is_edu_covid_grading, housing_diff_4q)
# --> These match for both RF and XGBoost models!

# Output for Stage 2
# --> emp_at_conception, is_edu_covid_grading, housing_diff_4q