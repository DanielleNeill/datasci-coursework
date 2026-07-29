# Stage 2: Evaluation of the optimised comparison with feature engineering
# - Predictors: Model-specific winning features (e.g., Lags, Volatility, Regimes, Momentum).
# - Purpose:    Assess the benefits of engineered features. Since Tree models lack ARIMA's
#               native temporal memory, this tests if ML with feature engineering can outperform traditional
#               time-series approaches.
# Output from Influential Features Step:
#   --> emp_at_conception, is_edu_covid_grading, housing_diff_4q

library(tidyverse)
library(tidymodels)
library(xgboost)
library(ranger)
library(yardstick)

# Standardise on the randomness for reproducible results
set.seed(1)

# 1. Load datasets using the paths for merged features.
model_features  <- read_csv("project/data/processed/merged_modeling_features_2007_2024.csv")

# 2. Add our group validation strategy - all 3 models (ARIMA/RF/XGBOOST) must follow the same strategy.
ts_folds <- rolling_origin(
  model_features,
  initial    = 48,  # 12 years (48 quarters)
  assess     = 4,   # 1 year (4 quarters)
  cumulative = TRUE,
  skip       = 3    # Total skip of 4 quarters (1 natural + 3)
)

# 3. Model Specifications (RF & XGBoost) - Specifics detailed in the previous step
xgb_spec <- boost_tree(trees = 500, tree_depth = 3, learn_rate = 0.01) %>%
  set_engine("xgboost") %>%
  set_mode("regression")

rf_spec <- rand_forest(trees = 500, min_n = 5) %>%
  set_engine("ranger", importance = "impurity") %>%
  set_mode("regression")

# 4. Apply the optimal hypothesis - Test the top three influential features identified previously
#    --> emp_at_conception, is_edu_covid_grading, housing_diff_4q
opt_formula <- quarterly_births ~ emp_at_conception + is_edu_covid_grading + housing_diff_4q

models <- list(xgboost = xgb_spec, random_forest = rf_spec)

# 5. Function to run cross-validation and collect our group agreed metrics
run_optimized_eval <- function(spec, engine_name) {
  set.seed(1)
  workflow() %>%
    add_formula(opt_formula) %>%
    add_model(spec) %>%
    fit_resamples(
      resamples = ts_folds,
      metrics   = metric_set(mae, rmse, mape, smape),
      control   = control_resamples(save_pred = TRUE)
    ) %>%
    collect_metrics() %>%
    mutate(model_engine = engine_name)
}

# 6. Test/Evaluate our RF and XGBoost models
stage_2_results <- map2_df(models, names(models), run_optimized_eval)

stage_2_metrics <- stage_2_results %>%
  select(model_engine, .metric, mean) %>%
  pivot_wider(names_from = .metric, values_from = mean) %>%
  arrange(mae)

print("--- Stage 2 optimized model results ---")
print(stage_2_metrics)
#   model_engine    mae  mape  rmse smape
#   <chr>         <dbl> <dbl> <dbl> <dbl>
# 1 xgboost        333.  6.52  381.  6.25
# 2 random_forest  346.  6.81  382.  6.53

# 7. Extract Feature Importance

final_raw_fit_xgb <- workflow() %>%
  add_formula(opt_formula) %>%
  add_model(xgb_spec) %>%
  fit(data = model_features)

final_raw_fit_rf <- workflow() %>%
  add_formula(opt_formula) %>%
  add_model(rf_spec) %>%
  fit(data = model_features)

# Visualise XGBoost Optimised Importance (Gain)
final_raw_fit_xgb %>%
  extract_fit_engine() %>%
  xgb.importance(model = .) %>%
  as_tibble() %>%
  ggplot(aes(x = reorder(Feature, Gain), y = Gain, fill = Feature)) +
  geom_col(show.legend = FALSE) +
  coord_flip() +
  labs(title = "Stage 2: Optimal Feature Importance (XGBoost)",
       subtitle = "Relative signal of engineered predictors",
       x = "Raw Predictor", y = "Relative Gain") +
  theme_minimal()
# In order of importance (emp_rate, standardised_price, fe_pct)
# --> again emp_rate has a significantly greater influence than the others

# Visualise Random Forest Optimised Importance (Impurity)
final_raw_fit_rf %>%
  extract_fit_engine() %>%
  purrr::pluck("variable.importance") %>%
  enframe(name = "Feature", value = "Importance") %>%
  ggplot(aes(x = reorder(Feature, Importance), y = Importance, fill = Feature)) +
  geom_col(show.legend = FALSE) +
  coord_flip() +
  labs(title = "Stage 2: Optimal Feature Importance (RF)",
       subtitle = "Impurity-based ranking of engineered predictors",
       x = "Raw Predictor", y = "Relative Importance") +
  theme_minimal()
# In order of importance (emp_rate, standardised_price, fe_pct)
# --> emp_rate has a significantly greater influence than the other predictors but not to the extent as with XGB
