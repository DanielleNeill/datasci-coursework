# CRISP-DM Phase 3: Data Preparation
# Prepare quarterly employment rate dataset
# =====================================
# Key tasks:
# - filter the raw employment data for quarterly records
# - parse dates and align formatting with the teams birth dataset
# - create a clean quarterly employment dataset for our chosen date range
# - write the processed quarterly dataset to project/data/processed/

library(readr)
library(dplyr)
library(lubridate)

# 1. Load the raw dataset for employment rate
raw_df <- read.csv("./project/data/raw/economic_inactivity/1_Labour_Force_Survey_lf62.csv", header = FALSE, skip = 8)
colnames(raw_df) <- c("date_raw", "emp_rate")
raw_df$emp_rate <- as.numeric(raw_df$emp_rate)

# 2. Filter and clean the Quarterly Data
employment_rate_quarterly <- raw_df %>%
  # Extract only the quarterly entries (e.g., "2006 Q1")
  filter(grepl("Q1|Q2|Q3|Q4", date_raw)) %>%
  # Extract Year and Quarter label from the raw string
  mutate(
    year = as.integer(substr(date_raw, 1, 4)),
    quarter = substr(date_raw, 6, 7)
  ) %>%
  mutate(
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
  filter(year >= 2006 & year < 2025) %>%
  select(
    quarter_start_date,
    year,
    quarter,
    quarter_num,
    emp_rate
  ) %>%
  arrange(year, quarter_num) %>%
  drop_na(emp_rate)

# 3. Check and confirm the result - there should be 76 rows - 2006-01-01 - 2024-10-01
View(employment_rate_quarterly)
summary(employment_rate_quarterly)
#  quarter_start_date        year        quarter           quarter_num
#  Min.   :2006-01-01   Min.   :2006   Length:76          Min.   :1.00
#  1st Qu.:2010-09-08   1st Qu.:2010   Class :character   1st Qu.:1.75
#  Median :2015-05-16   Median :2015   Mode  :character   Median :2.50
#  Mean   :2015-05-17   Mean   :2015                      Mean   :2.50
#  3rd Qu.:2020-01-23   3rd Qu.:2020                      3rd Qu.:3.25
#  Max.   :2024-10-01   Max.   :2024                      Max.   :4.00
glimpse(employment_rate_quarterly)
# Rows: 76
# Columns: 5
# $ quarter_start_date <date> 2006-01-01, 2006-04-01, 2006-07-01, 2006-10-01, 20…
# $ year               <int> 2006, 2006, 2006, 2006, 2007, 2007, 2007, 2007, 200…
# $ quarter            <chr> "Q1", "Q2", "Q3", "Q4", "Q1", "Q2", "Q3", "Q4", "Q1…
# $ quarter_num        <int> 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, …
# $ emp_rate           <dbl> 61.0, 61.8, 60.9, 61.8, 62.6, 62.0, 61.7, 61.6, 62.…

# 4. Save the processed quarterly employment dataset
write_csv(
  employment_rate_quarterly,
  "project/data/processed/employment_rate_quarterly_occurrence.csv"
)