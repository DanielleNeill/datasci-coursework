# CRISP-DM Phase 3: Data Preparation
# Prepare quarterly housing dataset with engineered features
# =====================================
# Key tasks:
# - Read the processed quarterly housing dataset
# - Create engineered housing features for tree-based models
# - Keep the original quarterly housing variables alongside the engineered features
# - Create lags, differences, volatility and regime/category variables
# - Write the processed quarterly housing features dataset to project/data/processed/

library(readr)   # read & write csv files
library(dplyr)   # data manipulation
library(zoo)     # rolling window calculations

# Read processed quarterly housing dataset
housing_quarterly <- read_csv("project/data/processed/housing_quarterly.csv")

# Arrange in time order before creating lagged & rolling features
housing_quarterly <- housing_quarterly %>%
  arrange(quarter_start_date)

# Create engineered housing features
housing_quarterly_features <- housing_quarterly %>%
  mutate(
    # Use standardised_price as main housing value (easier to interpret than HPI)
    housing_value = standardised_price,
    
    # Lag 3 - approximates conception-to-birth timing at quarterly level
    housing_lag3 = lag(housing_value, 3),
    
    # Lag 4 - gives the same quarter in the previous year
    housing_lag4 = lag(housing_value, 4),
    
    # Quarter-to-quarter absolute change in housing value
    housing_diff_1q = housing_value - lag(housing_value, 1),
    
    # Year-on-year absolute change in housing value
    housing_diff_4q = housing_value - lag(housing_value, 4),
    
    # Rolling 4-quarter standard deviation - short-run instability/volatility in housing costs
    housing_volatility_4q = zoo::rollapplyr(
      housing_value,
      width = 4,
      FUN = sd,
      fill = NA,
      partial = FALSE
    )
  ) %>%
  mutate(
    # Create categories for housing cost
    housing_regime = case_when(
      ntile(housing_value, 3) == 1 ~ "Low_Cost", # low housing pressure
      ntile(housing_value, 3) == 2 ~ "Medium_Cost", 
      ntile(housing_value, 3) == 3 ~ "High_Cost" # high housing pressure
    ),
    
    # Create a simple yes/no flag for high housing cost
    # 1 = high housing cost, 0 = otherwise
    is_high_cost_pressure = if_else(housing_regime == "High_Cost", 1, 0)
  ) %>%
  
  select(
    quarter_start_date,
    year,
    quarter,
    quarter_num,
    ni_house_price_index,
    standardised_price,
    quarterly_change_decimal,
    annual_change_decimal,
    housing_value,
    housing_regime,
    is_high_cost_pressure,
    housing_lag3,
    housing_lag4,
    housing_diff_1q,
    housing_diff_4q,
    housing_volatility_4q
  ) %>%
  arrange(quarter_start_date)

# Check result
View(housing_quarterly_features)
summary(housing_quarterly_features)

names(housing_quarterly_features)

# Save processed quarterly housing features dataset
write_csv(
  housing_quarterly_features,
  "project/data/processed/housing_quarterly_features.csv"
)
