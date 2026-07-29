# CRISP-DM Phase 4: Modelling
# Quarterly ARIMA / ARIMAX comparison
# =====================================
# Key tasks:
# - read the merged quarterly modelling dataset
# - fit a baseline quarterly ARIMA model on births only
# - fit a Stage 1 ARIMAX model using raw quarterly predictors
# - test a small set of Stage 2 ARIMAX predictor combinations
# - test the agreed Stage 2 predictor set from the RF/XGBoost search
# - compare models using rolling-origin evaluation

library(tidyverse)   # data handling
library(lubridate)   # date support
library(rsample)     # rolling_origin re-sampling
library(forecast)    # ARIMA / ARIMAX modelling
library(Metrics)     # evaluation metrics

# --------------------------------------------------
# File paths and modelling settings
# --------------------------------------------------
input_data_path <- "project/data/processed/merged_modeling_features_2007_2024.csv"
output_results_path <- "project/data/processed/quarterly_arima_arimax_results.csv"

target_var <- "quarterly_births"
quarterly_frequency <- 4

initial_window <- 48
assessment_window <- 4
skip_window <- 3

# --------------------------------------------------
# Load modelling data
# --------------------------------------------------
quarterly_model_data <- read_csv(input_data_path) %>%
  arrange(quarter_start_date)

# Pre-modelling check to confirm target & predictor names
names(quarterly_model_data)
glimpse(quarterly_model_data)
summary(quarterly_model_data)

# --------------------------------------------------
# Define predictor sets
# --------------------------------------------------

# Stage 1 (baseline comparison): raw quarterly predictors 
stage1_predictors <- c("emp_rate", "standardised_price", "he_pct")

# Stage 2: small housing feature search
# restrained to avoid over-complicating a relatively short quarterly series
stage2_predictor_sets <- list(
  raw_only              = c("emp_rate", "standardised_price", "he_pct"),
  raw_plus_housing_lag3 = c("emp_rate", "standardised_price", "he_pct", "housing_lag3"),
  raw_plus_housing_lag4 = c("emp_rate", "standardised_price", "he_pct", "housing_lag4"),
  raw_plus_diff_1q      = c("emp_rate", "standardised_price", "he_pct", "housing_diff_1q"),
  raw_plus_diff_4q      = c("emp_rate", "standardised_price", "he_pct", "housing_diff_4q")
)

# Agreed Stage 2 predictors from the RF/XGBoost search
# The COVID grading flag was omitted because it did not vary in early ARIMAX training folds
stage2_agreed_predictors <- c("emp_at_conception", "housing_diff_4q")

# Additional theory-informed ARIMAX checks
# based on theoretical reasoning around conception timing and lagged socioeconomic effects.
extra_predictor_sets <- list(
  conception_plus_lag4      = c("emp_at_conception", "housing_lag4"),
  conception_plus_edu_diff4 = c("emp_at_conception", "he_at_conception", "housing_diff_4q"),
  conception_plus_edu_lag4  = c("emp_at_conception", "he_at_conception", "housing_lag4")
)

# Error handling: check all required columns exist 
required_cols <- unique(c(
  target_var,
  unlist(stage2_predictor_sets),
  stage2_agreed_predictors,
  unlist(extra_predictor_sets),
  "quarter_start_date"
))

missing_cols <- setdiff(required_cols, names(quarterly_model_data))

if (length(missing_cols) > 0) {
  stop("The merged modelling dataset is missing: ",
       paste(missing_cols, collapse = ", "))
}

# --------------------------------------------------
# Create rolling-origin folds
# --------------------------------------------------
quarterly_folds <- rolling_origin(
  quarterly_model_data,
  initial = initial_window,
  assess = assessment_window,
  cumulative = TRUE,
  skip = skip_window
)

quarterly_folds

# --------------------------------------------------
# Function to fit and evaluate one ARIMA/ARIMAX model
# --------------------------------------------------
# Fits the model on each rolling fold, and returns
# mean MAE, RMSE, MAPE and SMAPE across all folds.
# - baseline ARIMA if predictors = NULL
# - ARIMAX if predictors are supplied
evaluate_arima_model <- function(folds,
                                 target,
                                 predictors = NULL,
                                 model_label = "model") {
  
  fold_results <- map_dfr(seq_len(nrow(folds)), function(i) {
    
    # Split into training and test data (for this fold)
    train_df <- analysis(folds$splits[[i]]) %>% arrange(quarter_start_date)
    test_df <- assessment(folds$splits[[i]]) %>% arrange(quarter_start_date)
    
    # Convert the training target into a quarterly time series
    train_ts <- ts(
      train_df[[target]],
      start = c(year(min(train_df$quarter_start_date)), 
                quarter(min(train_df$quarter_start_date))),
      frequency = quarterly_frequency)
    
    # Fit baseline ARIMA if no predictors are supplied
    if (is.null(predictors)) {
      fitted_model <- auto.arima(train_ts, seasonal = TRUE)
      forecast_values <- forecast(fitted_model, h = nrow(test_df))
    } else {
      # Fit ARIMAX if predictors are supplied
      train_predictors_matrix <- as.matrix(train_df[, predictors])
      test_predictors_matrix <- as.matrix(test_df[, predictors])
      
      fitted_model <- auto.arima(
        train_ts, 
        xreg = train_predictors_matrix, 
        seasonal = TRUE
        )
      
      forecast_values <- forecast(
        fitted_model, 
        xreg = test_predictors_matrix, 
        h = nrow(test_df)
        )
    }
    
    # Compare predictions with the actual test values
    actual <- test_df[[target]]
    predicted <- as.numeric(forecast_values$mean)
    
    tibble(
      model = model_label,
      mae = Metrics::mae(actual, predicted),
      rmse = Metrics::rmse(actual, predicted),
      mape = Metrics::mape(actual, predicted) * 100,
      smape = Metrics::smape(actual, predicted) * 100
    )
  })
  
  # Average the results across all folds
  fold_results %>%
    summarise(
      model = first(model),
      mean_mae = mean(mae),
      mean_rmse = mean(rmse),
      mean_mape = mean(mape),
      mean_smape = mean(smape)
    )
}

# --------------------------------------------------
# Run models
# --------------------------------------------------

# Baseline quarterly ARIMA (births only, no external predictors)
baseline_arima_results <- evaluate_arima_model(
  folds = quarterly_folds,
  target = target_var,
  predictors = NULL,
  model_label = "Baseline quarterly ARIMA"
)

baseline_arima_results

# Stage 1 ARIMAX: raw predictors
stage1_arimax_results <- evaluate_arima_model(
  folds = quarterly_folds,
  target = target_var,
  predictors = stage1_predictors,
  model_label = "Stage 1 ARIMAX (raw predictors)"
)

stage1_arimax_results

# Stage 2 ARIMAX: small housing feature search
# Find which quarterly ARIMAX predictor set gives the lowest mean MAE
stage2_results <- map2_dfr(
  stage2_predictor_sets,
  names(stage2_predictor_sets),
  \(preds, label) evaluate_arima_model(
      folds = quarterly_folds,
      target = target_var,
      predictors = preds,
      model_label = paste("Stage 2 ARIMAX:", label)
    )
)

stage2_results

# Stage 2 ARIMAX: using agreed predictors from the RF/XGBoost search
# to allow direct comparison with the tree-based models.
stage2_agreed_arimax_results <- evaluate_arima_model(
  folds = quarterly_folds,
  target = target_var,
  predictors = stage2_agreed_predictors,
  model_label = "Stage 2 ARIMAX (agreed predictors)"
)

stage2_agreed_arimax_results


# Additional theory-informed ARIMAX checks
additional_results <- map2_dfr(
  extra_predictor_sets,
  names(extra_predictor_sets),
  \(preds, label) evaluate_arima_model(
      folds = quarterly_folds,
      target = target_var,
      predictors = preds,
      model_label = paste("Additional ARIMAX:", label)
    )
)

additional_results

# --------------------------------------------------
# Combine results into a comparison table and save
# --------------------------------------------------
all_results <- bind_rows(
  baseline_arima_results,
  stage1_arimax_results,
  stage2_results,
  stage2_agreed_arimax_results,
  additional_results
) %>%
  arrange(mean_mae)

all_results

# Save the model comparison results
write_csv(all_results, output_results_path)

# --------------------------------------------------
# Fig.2. Actual vs forecast for baseline ARIMA and
#       best Stage 2 ARIMAX
# --------------------------------------------------
# --------------------------------------------------
# Fig. 2. Actual vs forecast for baseline ARIMA and
#         best Stage 2 ARIMAX
# --------------------------------------------------
best_stage2_predictors <- c("emp_rate", "standardised_price", "he_pct", "housing_diff_4q")

get_fold_predictions <- function(split, model_label, predictors = NULL) {
  train_df <- analysis(split) %>% arrange(quarter_start_date)
  test_df  <- assessment(split) %>% arrange(quarter_start_date)
  
  train_ts <- ts(
    train_df[[target_var]],
    start = c(year(min(train_df$quarter_start_date)),
              quarter(min(train_df$quarter_start_date))),
    frequency = quarterly_frequency
  )
  
  if (is.null(predictors)) {
    fit <- auto.arima(train_ts, seasonal = TRUE)
    fc  <- forecast(fit, h = nrow(test_df))
  } else {
    fit <- auto.arima(
      train_ts,
      xreg = as.matrix(train_df[, predictors]),
      seasonal = TRUE
    )
    fc <- forecast(
      fit,
      xreg = as.matrix(test_df[, predictors]),
      h = nrow(test_df)
    )
  }
  
  tibble(
    quarter_start_date = test_df$quarter_start_date,
    actual = test_df[[target_var]],
    forecast = as.numeric(fc$mean),
    model = model_label
  )
}

figure2_data <- bind_rows(
  map_df(quarterly_folds$splits, get_fold_predictions, model_label = "ARIMA"),
  map_df(
    quarterly_folds$splits,
    get_fold_predictions,
    model_label = "Stage 2 ARIMAX",
    predictors = best_stage2_predictors
  )
)

actual_plot_data <- figure2_data %>%
  distinct(quarter_start_date, actual) %>%
  transmute(
    quarter_start_date,
    value = actual,
    series = "Actual"
  )

forecast_plot_data <- figure2_data %>%
  transmute(
    quarter_start_date,
    value = forecast,
    series = model
  )

plot_data <- bind_rows(actual_plot_data, forecast_plot_data)

figure2_plot <- ggplot(
  plot_data,
  aes(x = quarter_start_date, y = value, linetype = series)
) +
  geom_line(linewidth = 0.9) +
  scale_linetype_manual(
    values = c(
      "Actual" = "solid",
      "ARIMA" = "dashed",
      "Stage 2 ARIMAX" = "dotted"
    )
  ) +
  labs(
    x = "Quarter",
    y = "Quarterly births",
    linetype = NULL
  ) +
  theme_classic(base_size = 10) +
  theme(
    legend.position = "bottom",
    legend.text = element_text(size = 9),
    axis.title = element_text(size = 10),
    axis.text = element_text(size = 9)
  )

print(figure2_plot)

ggsave(
  filename = "project/reports/figures/figure2_actual_vs_forecast_arima_arimax.png",
  plot = figure2_plot,
  width = 7,
  height = 4,
  dpi = 300
)

# --------------------------------------------------
# Refit the best model on the full series
# inspect the final chosen ARIMA/ARIMAX specification
# --------------------------------------------------
best_model_name <- all_results %>% slice(1) %>% pull(model)

best_predictors <- NULL
if (best_model_name == "Baseline quarterly ARIMA") {
  best_predictors <- NULL

} else if (best_model_name == "Stage 1 ARIMAX (raw predictors)") {
  best_predictors <- stage1_predictors

} else if (best_model_name == "Stage 2 ARIMAX (agreed predictors)") {
  best_predictors <- stage2_agreed_predictors

} else if (str_detect(best_model_name, "^Stage 2 ARIMAX:")) {
  best_key <- str_remove(best_model_name, "Stage 2 ARIMAX: ")
  best_predictors <- stage2_predictor_sets[[best_key]]

} else if (str_detect(best_model_name, "^Additional ARIMAX:")) {
  best_key <- str_remove(best_model_name, "Additional ARIMAX: ")
  best_predictors <- extra_predictor_sets[[best_key]]
}

best_model_name
best_predictors

# Fit the best ARIMA/ARIMAX model on the full quarterly series
full_ts <- ts(
  quarterly_model_data[[target_var]],
  start = c(year(min(quarterly_model_data$quarter_start_date)), 
            quarter(min(quarterly_model_data$quarter_start_date))),
  frequency = quarterly_frequency
  )

if (is.null(best_predictors)) {
  best_fit <- auto.arima(full_ts, seasonal = TRUE)
} else {
  best_xreg <- as.matrix(quarterly_model_data[, best_predictors])
  best_fit <- auto.arima(full_ts, xreg = best_xreg, seasonal = TRUE)
}

summary(best_fit)
checkresiduals(best_fit)