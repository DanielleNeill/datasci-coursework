# CRISP-DM Phase 3: Data Preparation
# Prepare birth data
# =====================================
# Key tasks:
# - read project/data/raw/monthly_births_NISRA.xlsx
# - births_raw is the original table from Excel
# - create a tidy monthly births dataset: births_monthly
# - create a tidy annual births dataset: births_annual
# - write both to project/data/processed/

library(readxl)
library(dplyr)
library(tidyr)
library(readr)

file_path <- "project/data/raw/monthly_births_NISRA.xlsx"

# Check available sheet names
excel_sheets(file_path)

# Read the births table
births_raw <- read_excel(
  file_path,
  sheet = "Births_Month of Birth",
  range = "A4:U17",
  col_names = TRUE
)

View(births_raw)

# Rename the first column to make future work easier
names(births_raw)[1] <- "birth_month"

# Create a tidy MONTHLY births dataset
births_monthly <- births_raw %>%
  # Remove "Total" row as this is for annual totals, not monthly values
  filter(birth_month != "Total") %>%
  
  # Convert data from wide to long format (1 col for year, 1 col for births)
  pivot_longer(
    cols = -birth_month,
    names_to = "year",
    values_to = "births"
  ) %>%
      
  # Clean up data types and create a numeric month variable
  mutate(
    year = as.integer(year), # convert year from text to integer
    births = as.integer(births), # convert births to integer
    # Turn birth_month into an ordered factor so months stay in calendar order instead of alphabetical
    birth_month = factor(
      birth_month,
      levels = c(
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
      ),
      ordered = TRUE
    ),
    month_num = as.integer(birth_month), # Create numeric month variable: January = 1, February = 2, etc.
    date = as.Date(sprintf("%d-%02d-01", year, month_num))
    ) %>%
  
  # Keep only the columns we want
  select(date, year, month_num, birth_month, births) %>%
  
  # Sort by year and month number
  arrange(year, month_num)


# Create a tidy ANNUAL births dataset
births_annual <- births_raw %>%
  filter(birth_month == "Total") %>%
  pivot_longer(
    cols = -birth_month,
    names_to = "year",
    values_to = "annual_births"
  ) %>%
  mutate(
    year = as.integer(year),
    annual_births = as.integer(annual_births)
  ) %>%
  select(year, annual_births) %>%
  arrange(year)

View(births_monthly)
View(births_annual)

# Save outputs
write_csv(births_monthly, "project/data/processed/births_monthly_occurrence.csv")
write_csv(births_annual, "project/data/processed/births_annual_occurrence.csv")

sum(births_monthly$births[births_monthly$year == 2006])
births_annual$annual_births[births_annual$year == 2006]
