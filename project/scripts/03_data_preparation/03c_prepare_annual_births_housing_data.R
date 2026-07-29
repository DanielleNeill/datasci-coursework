# CRISP-DM Phase 3: Data Preparation
# Prepare annual births and housing dataset
# =====================================
# Key tasks:
# - read the processed annual births dataset
# - read the processed annual housing dataset
# - merge both datasets by year
# - create a clean annual births + housing dataset: births_housing_annual
# - write the processed annual merged dataset to project/data/processed/

library(readr)
library(dplyr)

births_annual <- read_csv("project/data/processed/births_annual_occurrence.csv")
housing_annual <- read_csv("project/data/processed/housing_annual.csv")

births_housing_annual <- births_annual %>%
  inner_join(housing_annual, by = "year") %>%
  arrange(year)

View(births_housing_annual)
summary(births_housing_annual)
nrow(births_housing_annual)

write_csv(
  births_housing_annual,
  "project/data/processed/births_housing_annual.csv"
)


