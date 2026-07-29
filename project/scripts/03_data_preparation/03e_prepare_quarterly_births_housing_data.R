# CRISP-DM Phase 3: Data Preparation
# Prepare quarterly births and housing dataset
# =====================================
# Key tasks:
# - read the processed quarterly births dataset
# - read the processed quarterly housing dataset
# - merge both datasets by quarter
# - create a clean quarterly births + housing dataset: births_housing_quarterly
# - write the processed quarterly merged dataset to project/data/processed/

library(readr)
library(dplyr)

births_quarterly <- read_csv("project/data/processed/births_quarterly_occurrence.csv")
housing_quarterly <- read_csv("project/data/processed/housing_quarterly.csv")

births_housing_quarterly <- births_quarterly %>%
  inner_join(
    housing_quarterly,
    by = c("quarter_start_date", "year", "quarter")
  ) %>%
  arrange(year, quarter_num)

View(births_housing_quarterly)
summary(births_housing_quarterly)

write_csv(
  births_housing_quarterly,
  "project/data/processed/births_housing_quarterly.csv"
)