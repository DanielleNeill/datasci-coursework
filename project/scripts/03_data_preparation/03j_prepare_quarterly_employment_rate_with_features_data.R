# CRISP-DM Phase 3: Data Preparation (Feature Engineering)
# =======================================================
# Objective: Create high density features for use with our tree-based models (XGBoost/RF).
# Per discussion with Danielle, we want to keep these seperate for tree based models
# since ARIMA doesn't need them, at least for Stage 1 of our project methodology.

library(tidyverse)
library(lubridate)
library(zoo)
library(rsample)

# 1. Load the processed quarterly employment data that we previously prepared
emp_quarterly <- read_csv("project/data/processed/employment_rate_quarterly_occurrence.csv")

# 2. Apply Feature Engineering to this dataset for use with tree-based models (XGBoost/RF)
# Here we transform the raw rate into high-density predictors (Lags, Momentum, Volatility, Regimes)
# shifted by 3 quarters to represent and align with the conception window.
# TODO A reminder to consider and build these into the formulas during the modeling phase.
model_features <- emp_quarterly %>%
  arrange(quarter_start_date) %>%
  mutate(
    emp_at_conception   = lag(emp_rate, 3), # 3 Quarters = 9 Months
    # Introduce momentum as change between conception quarter and 1 year prior to conception (4Q = 1 year)
    emp_momentum_lag3   = lag(emp_rate, 3) - lag(emp_rate, 7),
    # Introduce volatility (i.e. the stability of the market at time of conception)
    # --> apply a 4-quarter rolling SD (1 year), lagged to the point of conception (3 * 3 months = 9)
    emp_volatility_lag3 = rollapply(emp_rate, width = 4, FUN = sd, fill = NA, align = "right") %>%
      lag(3),
    # Introduce regimes as a categorical state of the job market at time of conception where transition is
    # when things are moving from one level of intensity to another, i.e. moving from low to high intensity.
    emp_regime_at_conception = case_when(
      emp_at_conception >= 67.5 ~ "High_Intensity",
      emp_at_conception <= 64.0 ~ "Low_Intensity",
      TRUE                      ~ "Transition"
    ),
    # A binary indicator to later test the idea on opportunity cost, which is the theory that with
    # more intensive careers comes a reduction in the desire or time to have children.
    # 69 is the value that was derived during the data understanding phase of analysis.
    is_emp_peak_at_conception = ifelse(emp_at_conception > 69.0, 1, 0)
  ) %>%
  # Remove any NAs that were added by the 7-quarter lookback - we do lose 2 years of data doing this.
  # However, by sacrificing the first two years of data we better ensure that the model has enough
  # historical context to calculate market speed and stability at the exact moment of conception.
  # Basically, because a pregnancy takes 9 months we wouldn't be able to explain why babies were born in
  # 2006 without knowing what the economy looked like in 2005, therefore even though we sacrifice this
  # data we end up with higher quality data that can be used to make predictions using our tree models.
  drop_na()

# 3. Visualise the Regimes to verify if Opportunity Cost is a possible reality
# i.e. in the Red high intensity period, this is where we should expect to see birth rates drop in relation
# to economic factors - this is when females are in much higher employment, therefore we would expect to
# see a drop in birth rates as females sacrifice having children in favour of their careers.
# This can be confirmed later, but for now this just shows that our data is appropriate to later demonstrate
# this theory. Note that this theory is derived from the literature and is therefore a good indication
# of what we should expect to see when comparing employment rate to birth rates.
# Updated note post-Modeling - we did indeed observe this since for the tree based models, lagged employment
# rate was the key predictor for both RF and XGBoost.
ggplot(model_features, aes(x = quarter_start_date, y = emp_at_conception, color = emp_regime_at_conception)) +
  geom_line(size = 1, aes(group = 1)) +
  geom_point() +
  scale_color_manual(values = c("High_Intensity" = "red", "Transition" = "orange", "Low_Intensity" = "green")) +
  labs(title = "Quarterly Employment: Conception-Aligned",
       subtitle = "Data lagged by 3 quarters to match Birth Outcome timing",
       x = "Birth Quarter", y = "Emp Rate at Conception (%)") +
  theme_minimal()

# 4. Save the output for Phase 4 (Modeling)
write_csv(model_features, "project/data/processed/employment_tree_model_features_quarterly.csv")

# 5. Summary check
summary(model_features)
#  quarter_start_date        year        quarter           quarter_num
#  Min.   :2007-10-01   Min.   :2007   Length:69          Min.   :1.000
#  1st Qu.:2012-01-01   1st Qu.:2012   Class :character   1st Qu.:2.000
#  Median :2016-04-01   Median :2016   Mode  :character   Median :3.000
#  Mean   :2016-03-31   Mean   :2016                      Mean   :2.522
#  3rd Qu.:2020-07-01   3rd Qu.:2020                      3rd Qu.:4.000
#  Max.   :2024-10-01   Max.   :2024                      Max.   :4.000
# --> Note the loss of some initial data points as we use them to derive lag.