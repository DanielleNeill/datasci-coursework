# CRISP-DM Phase 3: Data Preparation
# Prepare housing data
# =====================================
# Key tasks:
# - read the raw NI House Price Index Excel file
# - housing_raw is the original NI House Price Index table from Excel
# - extract year, quarter, NI House Price Index and standardised price
# - create a tidy quarterly housing dataset: housing_quarterly
# - write the processed housing dataset to project/data/processed/

library(readxl)
library(dplyr)
library(tidyr)
library(readr)

file_path <- "project/data/raw/housing/ni_house_price_index.xlsx"

# Check available sheet names
excel_sheets(file_path)

# Read Table 1 from the workbook - the real column headers start on row 4
housing_raw <- read_excel(file_path,
                          sheet = "Table 1",
                          range = "A4:F200",
                          col_names = TRUE)

View(housing_raw)

# Rename columns to ensure later code is readable
names(housing_raw) <- c(
  "year",
  "quarter",
  "ni_house_price_index",
  "standardised_price",
  "quarterly_change_decimal",
  "annual_change_decimal"
)

# Create a tidy quarterly housing dataset
housing_quarterly <- housing_raw %>%
  fill(year, .direction = "down") %>%  # Fill the year down because Excel table only shows the year once for each block of quarters
  filter(!is.na(quarter)) %>%   # Only keep the rows that actually contain quarter values
  # Keep only rows with valid quarter values
  filter(quarter %in% c("Q1", "Q2", "Q3", "Q4")) %>%
  
  # Convert values into clean numeric fields
  mutate(
    year = as.integer(year),
    # Parse strings into numeric values
    ni_house_price_index = as.numeric(ni_house_price_index),
    standardised_price = parse_number(as.character(standardised_price)),
    
    # Change columns are stored as decimals, e.g. 0.10 = 10%
    quarterly_change_decimal = as.numeric(quarterly_change_decimal),
    annual_change_decimal = as.numeric(annual_change_decimal),
    
    # Create a numeric quarter variable for easier joining and sorting
    quarter_num = case_when(
      quarter == "Q1" ~ 1L,
      quarter == "Q2" ~ 2L,
      quarter == "Q3" ~ 3L,
      quarter == "Q4" ~ 4L,
      TRUE ~ NA_integer_
    ),
    
    # Create a quarter start date for time-based modelling
    quarter_start_date = as.Date(
      case_when(
        quarter == "Q1" ~ paste0(year, "-01-01"),
        quarter == "Q2" ~ paste0(year, "-04-01"),
        quarter == "Q3" ~ paste0(year, "-07-01"),
        quarter == "Q4" ~ paste0(year, "-10-01")
      )
    )
  ) %>%
  
  # Only keep the final columns needed
  select(
    quarter_start_date,
    year,
    quarter,
    quarter_num,
    ni_house_price_index,
    standardised_price,
    quarterly_change_decimal,
    annual_change_decimal
  ) %>%
  
  # Sort in time order
  # arrange(year, quarter_num)
  arrange(quarter_start_date)

# View cleaned dataset
View(housing_quarterly)

# Save the processed housing dataset
write_csv(housing_quarterly,
          "project/data/processed/housing_quarterly.csv")

# Create a tidy ANNUAL housing dataset from the quarterly series
housing_annual <- housing_quarterly %>%
  group_by(year) %>%
  summarise(
    mean_annual_house_price = mean(standardised_price, na.rm = TRUE),
    mean_annual_hpi = mean(ni_house_price_index, na.rm = TRUE),
    #mean_quarterly_change_decimal = mean(quarterly_change_decimal, na.rm = TRUE),
    #mean_annual_change_decimal = mean(annual_change_decimal, na.rm = TRUE)
  ) %>%
  arrange(year)

View(housing_annual)
summary(housing_annual)

# Save processed annual housing dataset
write_csv(housing_annual, "project/data/processed/housing_annual.csv")
