# Stage 1: Baseline the models using the raw predictors.
# - Predictors: Raw Quarterly Employment Rate, House Prices, and Higher Education Participation.
# - Purpose:    To creates a level playing field to test the core hypothesis and test if the raw data
#               prediction is strong enough without complex processing / feature engineering.

library(tidyverse)
library(tidymodels)
library(xgboost)
library(ranger)
library(yardstick)

# Standardise on the randomness for reproducible results
set.seed(1)

# 1. Load datasets using the paths provided for all of our raw data.
births     <- read_csv("project/data/processed/births_quarterly_occurrence.csv")
housing    <- read_csv("project/data/processed/housing_quarterly.csv")
employment <- read_csv("project/data/processed/employment_rate_quarterly_occurrence.csv")
education  <- read_csv("project/data/processed/education_rate_quarterly_occurrence.csv")

# Combine into a single raw feature set
common_keys <- c("quarter_start_date", "year", "quarter", "quarter_num")
model_features <- births %>%
  distinct(across(all_of(common_keys)), .keep_all = TRUE) %>%
  inner_join(employment %>% distinct(across(all_of(common_keys)), .keep_all = TRUE), by = common_keys) %>%
  inner_join(education %>% distinct(across(all_of(common_keys)), .keep_all = TRUE), by = common_keys) %>%
  inner_join(housing %>% distinct(across(all_of(common_keys)), .keep_all = TRUE), by = common_keys) %>%
  select(quarter_start_date, quarterly_births, standardised_price, emp_rate, fe_pct)

# Restrict to the agreed modelling window 2007-10-01 to 2024-10-01
model_features <- model_features %>%
  filter(
    quarter_start_date >= as.Date("2007-10-01") &
      quarter_start_date <= as.Date("2024-10-01")
  ) %>%
  drop_na()

cat("Final Row Count:", nrow(model_features), "\n") # Final Row Count: 69 (should be 69 - confirmed!)

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

# 4. Apply the raw data as the formula --> births are a direct result of the current raw stats
raw_formula <- quarterly_births ~ standardised_price + emp_rate + fe_pct

models <- list(xgboost = xgb_spec, random_forest = rf_spec)

# 5. Function to run cross-validation and collect our group agreed metrics (MAE/RMSE/SMAPE) for our RF/XGB models
run_raw_baseline_workflow <- function(spec, engine_name) {
  set.seed(1)
  workflow() %>%
    add_formula(raw_formula) %>%
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
comparison_results <- map2_df(models, names(models), run_raw_baseline_workflow)

stage_1_metrics <- comparison_results %>%
  filter(.metric %in% c("mae", "rmse", "mape", "smape")) %>%
  # Organise the data so metrics are side-by-side for easy comparison
  select(model_engine, .metric, mean) %>%
  pivot_wider(names_from = .metric, values_from = mean) %>%
  arrange(mae)

print("--- Stage 1 raw baseline results ---")
print(stage_1_metrics)
#   model_engine    mae  mape  rmse smape
#   <chr>         <dbl> <dbl> <dbl> <dbl>
# 1 xgboost        463.  9.02  497.  8.56
# 2 random_forest  498.  9.78  530.  9.23

# 7. Extract Feature Importance

final_raw_fit_xgb <- workflow() %>%
  add_formula(raw_formula) %>%
  add_model(xgb_spec) %>%
  fit(data = model_features)

final_raw_fit_rf <- workflow() %>%
  add_formula(raw_formula) %>%
  add_model(rf_spec) %>%
  fit(data = model_features)

# Visualise XGBoost Raw Importance (Gain)
# --> Gain --> Measures the improvement in the model's accuracy using a specific tree split/decision
final_raw_fit_xgb %>%
  extract_fit_engine() %>%
  xgb.importance(model = .) %>%
  as_tibble() %>%
  ggplot(aes(x = reorder(Feature, Gain), y = Gain, fill = Feature)) +
  geom_col(show.legend = FALSE) +
  coord_flip() +
  labs(title = "Stage 1: Raw Feature Importance (XGBoost)",
       subtitle = "Relative signal of raw predictors",
       x = "Raw Predictor", y = "Relative Gain") +
  theme_minimal()
# In order of importance (emp_rate, standardised_price, fe_pct)
# --> again emp_rate has a significantly greater influence than the others

# Visualise Random Forest Raw Importance (Impurity)
# --> Impurity --> Measures how mixed-up the data is at a specific node in the tree.
final_raw_fit_rf %>%
  extract_fit_engine() %>%
  purrr::pluck("variable.importance") %>%
  enframe(name = "Feature", value = "Importance") %>%
  ggplot(aes(x = reorder(Feature, Importance), y = Importance, fill = Feature)) +
  geom_col(show.legend = FALSE) +
  coord_flip() +
  labs(title = "Stage 1: Raw Feature Importance (RF)",
       subtitle = "Impurity-based ranking of raw predictors",
       x = "Raw Predictor", y = "Relative Importance") +
  theme_minimal()
# In order of importance (emp_rate, standardised_price, fe_pct)
# --> emp_rate has a significantly greater influence than the other predictors but not to the extent as with XGB
