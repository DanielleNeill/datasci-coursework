# CRISP-DM Phase 2: Data Understanding
# ======================================
# Objective: Review the Education dataset to build an understanding of its contents.
#
# Key tasks:
#   - Load the data as obtained from the source.
#   - Describe the data in terms of volume, format & attributes.
#   - Explore the data in terms of distributions, relationships & if outliers exist.
#   - Verify the data quality to understand that it is usable for our study.
library(tidyverse)
library(scales)

# 1. Load the raw Education Data
edu_raw <- read_csv("project/data/raw/education/ni_school_leavers_girls_destinations_all_years.csv")

# 2. Data Cleaning & Feature Prep
# Sample row from the dataset to show what we are working with here:
#   Year,Higher_Education_Number,Higher_Education_Pct,Further_Education_Number,Further_Education_Pct,total_girls
#   2004/05,5649,45.6,3678,29.7,12375
edu_cleaned <- edu_raw %>%
  rename(
    he_pct = Higher_Education_Pct,
    fe_pct = Further_Education_Pct,
    total_girls = Total_Girls
  ) %>%
  mutate(
    # Extract the 2-digit end year (e.g., the "06" from "2005/06")
    # and then convert it into a 4-digit numeric year (i.e. 2005/06 --> 2006)
    year_exit = as.numeric(paste0("20", substr(Year, 6, 7))),
    # Calculate the non-HE/FE destinations (everywhere else such as employment, training, etc.)
    other_pct = 100 - he_pct - fe_pct,
    # Calculate the momentum (i.e. the Year-on-Year change) for HE before
    # filtering to allow 2006 to have a valid growth rate when we compare to 2005
    he_momentum = he_pct - lag(he_pct),
    # And also do the same for FE momentum
    fe_momentum = fe_pct - lag(fe_pct)
  ) %>%
  # Filter to align with your project's study period (2006 onwards)
  filter(year_exit >= 2006)

# 01. GGPlot Line Chart for HE vs FE %s
ggplot(edu_cleaned, aes(x = year_exit)) +
  geom_line(aes(y = he_pct, color = "Higher Education"), size = 1.2) +
  geom_point(aes(y = he_pct, color = "Higher Education"), size = 3) +
  geom_line(aes(y = fe_pct, color = "Further Education"), size = 1.2) +
  geom_point(aes(y = fe_pct, color = "Further Education"), size = 3) +
  scale_x_continuous(breaks = seq(2006, 2024, 2)) +
  scale_color_manual(values = c("Higher Education" = "#1f77b4", "Further Education" = "#b22222")) +
  labs(title = "Girl School Leavers: HE vs FE Destinations (for Exit Year)",
       subtitle = "Post-Education Destinations: A primary driver of Opportunity Cost, from 2006-2024",
       x = "Year of School Exit", y = "Percentage (%)", color = "Destination") +
  theme_minimal()

# 02. Stacked area chart showing the post-education destination share
edu_cleaned %>%
  select(year_exit, he_pct, fe_pct, other_pct) %>%
  pivot_longer(-year_exit, names_to = "Type", values_to = "Value") %>%
  mutate(Type = factor(Type, levels = c("other_pct", "fe_pct", "he_pct"))) %>%
  ggplot(aes(x = year_exit, y = Value, fill = Type)) +
  geom_area(alpha = 0.8, color = "white", size = 0.1) +
  scale_fill_manual(values = c("he_pct" = "#1f77b4", "fe_pct" = "#b22222", "other_pct" = "#d3d3d3"),
                    labels = c("Higher Education", "Further Education", "Other (e.g. Employment)")) +
  scale_x_continuous(breaks = seq(2006, 2024, 2)) +
  labs(title = "Post-Education Destinations",
       x = "Year of School Exit", y = "Percentage (%)", fill = "Category") +
  theme_minimal()

# 03. A Scatter Plot to show the relationship between FE & HE and to highlight the COVID effect
ggplot(edu_cleaned, aes(x = he_pct, y = fe_pct)) +
  geom_point(aes(color = (year_exit >= 2020)), size = 4) +
  geom_smooth(method = "lm", color = "black", linetype = "dashed", se = FALSE) +
  scale_color_manual(values = c("FALSE" = "#1f77b4", "TRUE" = "#e45756"),
                     labels = c("Pre-COVID", "COVID Period (2020+)")) +
  labs(title = "Higher Education vs Further Education",
       x = "Higher Education (%)", y = "Further Education (%)", color = "Period") +
  theme_minimal()

# 04. Momentum --> this shows the velocity of change towards higher/further education
ggplot(edu_cleaned, aes(x = year_exit, y = he_momentum, fill = he_momentum > 0)) +
  geom_col() +
  scale_fill_manual(values = c("TRUE" = "#1f77b4", "FALSE" = "#b22222")) +
  scale_x_continuous(breaks = seq(2006, 2024, 2)) +
  labs(title = "HE Percentage Momentum (Year-on-Year)",
       subtitle = "Shows the speed of the shift toward higher education",
       x = "Year of School Exit", y = "Change in HE Percentage Points", fill = "Growth") +
  theme_minimal()

# This is the same as above for FE, and helps to show a clear shift to HE during COVID
# These 2 charts were selected for use in the report to highlight this trend during COVID.
# Positive shown in blue, while negative shown using a red fill.
ggplot(edu_cleaned, aes(x = year_exit, y = fe_momentum, fill = fe_momentum > 0)) +
  geom_col() +
  scale_fill_manual(values = c("TRUE" = "#1f77b4", "FALSE" = "#b22222")) +
  scale_x_continuous(breaks = seq(2006, 2024, 2)) +
  labs(title = "FE Percentage Momentum (Year-on-Year)",
       subtitle = "Shows the speed of the shift toward further education",
       x = "Year of School Exit", y = "Change in FE Percentage Points", fill = "Growth") +
  theme_minimal()

# 05. Bar Chart to show cohort size per year of school exit --> helps identify any significant changes to cohort size
ggplot(edu_cleaned, aes(x = year_exit, y = total_girls)) +
  geom_col() +
  scale_x_continuous(breaks = seq(2006, 2024, 2)) +
  labs(title = "Total Female School Leavers",
       x = "Year of School Exit", y = "Number of Girls") +
  theme_minimal()