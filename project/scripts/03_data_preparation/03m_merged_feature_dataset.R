# CRISP-DM Phase 3: Data Preparation
# Prepare merged quarterly modelling dataset
# =====================================
# Key tasks:
# - Read the previously processed quarterly births, employment, education and housing datasets
# - Merge datasets into one shared quarterly modeling file
# - Restrict output to the agreed final modelling window after lag sacrifices (2007 Q4 to 2024 Q4)
# - Write the final merged dataset to project/data/processed/

library(tidyverse)
library(lubridate)

# 1. Load the prepared datasets for the shared quarterly modeling window
education_path <- "project/data/processed/education_tree_model_features_quarterly.csv"
employment_path <- "project/data/processed/employment_tree_model_features_quarterly.csv"
housing_path <- "project/data/processed/housing_quarterly_features.csv"
birth_path <- "project/data/processed/births_quarterly_occurrence.csv"

education_df <- read_csv(education_path)
employment_df <- read_csv(employment_path)
housing_df <- read_csv(housing_path)
births_df <- read_csv(birth_path)

# Common join keys between the processed datasets
common_keys <- c("quarter_start_date", "year", "quarter", "quarter_num")

# 2. Merge into a single quarterly modelling dataset using common keys
merged_features <- births_df %>%
  inner_join(employment_df, by = common_keys) %>%
  inner_join(education_df, by = common_keys) %>%
  inner_join(housing_df, by = common_keys)

# 3. Restrict to the agreed modelling window 2007-10-01 to 2024-10-01 (accounting for lost rows from lag calcs)
final_dataset <- merged_features %>%
  filter(
    quarter_start_date >= as.Date("2007-10-01") &
    quarter_start_date <= as.Date("2024-10-01")
    ) %>%
  drop_na()

# 4. Validate the output to ensure correctness
# Expected: 
# - 69 rows
# - date range 2007-10-01 to 2024-10-01 
print(paste("Rows in final dataset:", nrow(final_dataset)))
print(paste(
  "Date Range:", 
  min(final_dataset$quarter_start_date),
  "to", 
  max(final_dataset$quarter_start_date)
  ))

names(final_dataset)
#  [1] "quarter_start_date"        "year"
#  [3] "quarter"                   "quarter_num"
#  [5] "quarterly_births"          "emp_rate"
#  [7] "emp_at_conception"         "emp_momentum_lag3"
#  ...
summary(final_dataset)

# 5. Export the merged quarterly modelling dataset
write_csv(final_dataset, "project/data/processed/merged_modeling_features_2007_2024.csv")