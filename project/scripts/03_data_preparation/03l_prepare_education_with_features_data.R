# CRISP-DM Phase 3: Data Preparation (Feature Engineering)
# =======================================================
# Objective: 
# - Create simplified education features for tree-based models (XGBoost/RF).
# - Education is treated as a slow-moving structural predictor using quarterly-aligned values,
#   conception-aligned lags and a COVID grading flag.
# - Avoid over-engineering an already interpolated quarterly series.

library(tidyverse)
library(lubridate)

# 1. Load the processed quarterly education data
education_quarterly <- read_csv("project/data/processed/education_rate_quarterly_occurrence.csv")

# 2. Apply Feature Engineering
# Shift quarterly-aligned education measures (derived from annual data) by 3 quarters to represent conditions
# at the time of conception.
education_features <- education_quarterly %>%
  arrange(quarter_start_date) %>%
  mutate(
    # Lag education (HE/FE) by 3 quarters to align with conception timing (3 quarters = 9 month)
    he_at_conception = lag(he_pct, 3),
    fe_at_conception = lag(fe_pct, 3),
    
    # Create a policy/event flag for the COVID grading period
    # This identifies the period affected by COVID-related grading disruption where grades tended to go up.
    # Ref: https://www.beaconschool.co.uk/news/shock-impact-of-covid-student-grades-have-gone-up/
    # It is included so the model doesn't treat this unusual period as part of the normal education trend.
    is_edu_covid_grading = if_else(quarter_start_date >= as.Date("2020-01-01"), 1, 0)
  ) %>%
  drop_na()

# Check the results
View(education_features)
summary(education_features) # ensure feature ranges & NA removal
nrow(education_features) # [1] 73 - remember some rows lost due to calculation of lag.

# Save the output for Phase 4 (Modeling)
write_csv(education_features, "project/data/processed/education_tree_model_features_quarterly.csv")