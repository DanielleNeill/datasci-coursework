# CRISP-DM Phase 3: Data Preparation
# Prepare quarterly births dataset
# =====================================
# Key tasks:
# - read the processed monthly births dataset
# - aggregate monthly birth counts to quarterly totals
# - create a clean quarterly births dataset: births_quarterly
# - write the processed quarterly births dataset to project/data/processed/

library(readr)
library(dplyr)

# Read the processed monthly births dataset
births_monthly <- read_csv("project/data/processed/births_monthly_occurrence.csv")

# Create a quarterly births dataset by summing monthly births within each quarter
births_quarterly <- births_monthly %>%
  mutate(
    quarter = case_when(
      month_num %in% 1:3 ~ "Q1",
      month_num %in% 4:6 ~ "Q2",
      month_num %in% 7:9 ~ "Q3",
      month_num %in% 10:12 ~ "Q4"
    ),
    quarter_num = case_when(
      quarter == "Q1" ~ 1L,
      quarter == "Q2" ~ 2L,
      quarter == "Q3" ~ 3L,
      quarter == "Q4" ~ 4L
    ),
    quarter_start_date = as.Date(case_when(
      quarter == "Q1" ~ paste0(year, "-01-01"),
      quarter == "Q2" ~ paste0(year, "-04-01"),
      quarter == "Q3" ~ paste0(year, "-07-01"),
      quarter == "Q4" ~ paste0(year, "-10-01")
    ))
  ) %>%
  group_by(quarter_start_date, year, quarter, quarter_num) %>%
  summarise(
    quarterly_births = sum(births),
    .groups = "drop"
  ) %>%
  arrange(year, quarter_num)

# Check the result
View(births_quarterly)
summary(births_quarterly)

# Save the processed quarterly births dataset
write_csv(
  births_quarterly,
  "project/data/processed/births_quarterly_occurrence.csv"
)
