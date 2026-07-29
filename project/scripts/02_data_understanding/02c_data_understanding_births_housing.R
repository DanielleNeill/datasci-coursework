# CRISP-DM Phase 2: Data Understanding
# ======================================
# Objective: Explore initial birth and housing data
#   - Read processed annual births and housing data
#   - Describe data (volume, format, attributes)
#   - Explore distributions, relationships, and outliers
#   - Verify data quality
#   - Produce plots for discussion
#
# Data range: 2006-2025 (20 complete years)
# 2026 data excluded (partial year ending February) as it 
# could understate the annual total and distort trend analysis,
# particularly for  year-on-year change calculations.
# Note: data restricted to 2006-2024 for the modelling phase.

library(readr)
library(dplyr)
library(ggplot2)
library(tidyr) 
library(psych)
library(TTR)
library(tseries)

# -----------------------------
# Load data
# -----------------------------
births_annual <- read_csv("project/data/processed/births_annual_occurrence.csv")
housing_annual <- read_csv("project/data/processed/housing_annual.csv")

# -----------------------------
# Merge and engineer lag features
# - join births and housing by year
# - create 1- and 2-year lagged house price and HPI columns for correlation analysis
# -----------------------------
births_housing_annual <- births_annual |>
  inner_join(housing_annual, by = "year") |>
  arrange(year) |>
  mutate(
    house_price_lag1 = lag(mean_annual_house_price, 1),
    house_price_lag2 = lag(mean_annual_house_price, 2),
    house_price_lag3 = lag(mean_annual_house_price, 3),
    house_price_lag4 = lag(mean_annual_house_price, 4),
    hpi_lag1         = lag(mean_annual_hpi, 1),
    hpi_lag2         = lag(mean_annual_hpi, 2),
    hpi_lag3         = lag(mean_annual_hpi, 3),
    hpi_lag4         = lag(mean_annual_hpi, 4)
  )

# Check structure, data types, and value ranges
glimpse(births_housing_annual)
summary(births_housing_annual)

# Confirm expected NAs from lag engineering
colSums(is.na(births_housing_annual))

# Descriptive statistics:mean/SD, skewness and kurtosis inform modelling assumptions
describe(births_housing_annual$annual_births)
describe(births_housing_annual$mean_annual_house_price)

# -----------------------------
# Shared plot theme
# Defined once here so all plots stay visually consistent
# -----------------------------
cw2_theme <- function() {
  theme_minimal() +
    theme(plot.title = element_text(face = "bold"))
}

# -----------------------------
# Time-series structure and stationarity
# -----------------------------
# Convert births to a time series object
ts_births <- ts(births_housing_annual$annual_births,
                start = min(births_housing_annual$year),
                frequency = 1) # annual data with no intra-year seasonality

plot(ts_births, main = "Annual births time series")

# Augmented Dickey-Fuller (ADF) test 
# H0: series is non-stationary (series has a persistant trend)
# H1: series is stationary (series flucates around a stable mean)
adf.test(ts_births)

# Result: Dickey-Fuller = -1.9811, p-value = 0.5796
# p > 0.05 = fail to reject H0 (birth series is non-stationary)
# - raw-level correlations between births and housing both trend over time 
# - risk of producing misleading results through spurious correlation
# - reinforces year-on-year change analysis as the more reliable basis for inference.

# Note: decompose() needs at least 2 full seasonal cycles.
# Annual data (frequency = 1) has no intra-year seasonality to de-compose,
# Seasonality analysis was explored separately on the underlying monthly birth series

# -----------------------------
# Annual births plots
# -----------------------------

# Overall trend with linear regression line
ggplot(births_housing_annual, aes(x = year, y = annual_births)) +
  geom_line(linewidth = 1) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE, linewidth = 1, color = "red") +
  labs(
    title    = "Annual births in Northern Ireland",
    subtitle = "Red line shows overall linear trend",
    x        = "Year",
    y        = "Annual births"
  ) +
  cw2_theme()

# 3-year simple moving average (SMA) 
# - smooths year-year noise to reveal trajectory
# - SMA needs 3 data points, so the first 2 years will always be NA
births_sma <- SMA(births_housing_annual$annual_births, n = 3)

ggplot(births_housing_annual, aes(x = year, y = annual_births)) +
  geom_line(linewidth = 1, alpha = 0.4) +
  geom_point(alpha = 0.4) +
  geom_line(aes(y = births_sma), linewidth = 1, color = "darkred", 
            na.rm = TRUE) +  # NAs expected
  labs(
    title    = "Annual births with 3-year simple moving average",
    subtitle = "Red line shows smoothed trajectory (starts 2008)",
    x        = "Year",
    y        = "Annual births"
  ) +
  cw2_theme()

# Distribution with density overlay
# Bin width computed outside aes() to avoid variable scoping issue
births_binwidth <- (max(births_housing_annual$annual_births) -
                      min(births_housing_annual$annual_births)) / 15

ggplot(births_housing_annual, aes(x = annual_births)) +
  geom_histogram(bins = 15, fill = "steelblue", color = "white") +
  geom_density(aes(y = after_stat(density) * nrow(births_housing_annual) * births_binwidth),
               color = "red") +
  labs(
    title = "Distribution of annual births",
    x     = "Annual births",
    y     = "Frequency"
  ) +
  cw2_theme()

# Lag-1 scatter: births this year vs births last year
# - strong diagonal cloud = high autocorrelation 
# - births are highly persistent year-on-year
# - supports the use of lagged variables as predictors in modelling
births_housing_annual |>
  mutate(births_lag1 = lag(annual_births)) |>
  ggplot(aes(x = births_lag1, y = annual_births)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE) +
  labs(
    title = "Lag-1 scatter: annual births",
    x     = "Births (t-1)",
    y     = "Births (t)"
  ) +
  cw2_theme()

# -----------------------------
# Housing plots
# -----------------------------
# Mean annual house price 
ggplot(births_housing_annual, aes(x = year, y = mean_annual_house_price)) +
  geom_line(linewidth = 1) +
  geom_point() +
  labs(
    title = "Mean annual house price in Northern Ireland",
    x = "Year", y = "Mean annual house price (£)"
  ) +
  cw2_theme()

# Mean house price index (HPI) 
ggplot(births_housing_annual, aes(x = year, y = mean_annual_hpi)) +
  geom_line(linewidth = 1) +
  geom_point() +
  labs(
    title = "Mean annual NI house price index",
    x = "Year",
    y = "Mean annual HPI"
  ) +
  cw2_theme()

# Standardised trends — all three series on the same axis
# Scaling to z-scores allows shape comparison regardless of unit differences
births_housing_annual |>
  mutate(
    Births        = as.numeric(scale(annual_births)),
    `House price` = as.numeric(scale(mean_annual_house_price)),
    HPI           = as.numeric(scale(mean_annual_hpi))
  ) |>
  pivot_longer(
    cols = c(Births, `House price`, HPI),
    names_to = "series", 
    values_to = "value") |>
  ggplot(aes(x = year, y = value, linetype = series)) +
  geom_line(linewidth = 1) +
  labs(
    title   = "Standardised annual trends (births - housing)",
    x       = "Year",
    y       = "Standardised value (z-score)",
    linetype = "Series"
  ) +
  cw2_theme()

# -----------------------------
# Scatter plots: births vs housing 
# (raw levels + lags)
# -----------------------------

# Reusable function to avoid repeating identical plot structure
scatter_births_vs <- function(data, x_var, x_label, title) {
  ggplot(data, aes(x = .data[[x_var]], y = annual_births)) +
    geom_point(na.rm = TRUE) +
    geom_smooth(method = "lm", se = FALSE, na.rm = TRUE) +
    labs(title = title, x = x_label, y = "Annual births") +
    cw2_theme()
}

scatter_births_vs(
  births_housing_annual,
  "mean_annual_house_price",
  "Mean annual house price (£)",
  "Annual births vs mean annual house price"
  )

scatter_births_vs(
  births_housing_annual,
  "house_price_lag1",
  "Lagged mean annual house price, t\u22121 (£)",
  "Annual births vs lagged mean annual house price (t\u22121)"
  )

scatter_births_vs(
  births_housing_annual,
  "house_price_lag2",
  "Lagged mean annual house price, t\u22122 (£)",
  "Annual births vs 2-year lagged mean annual house price"
  )

scatter_births_vs(
  births_housing_annual,
  "hpi_lag2",
  "Lagged mean annual HPI, t\u22122",
  "Annual births vs 2-year lagged mean annual HPI")

scatter_births_vs(
  births_housing_annual,
  "house_price_lag4",
  "Lagged mean annual house price, t\u22124 (£)",
  "Annual births vs 4-year lagged mean annual house price"
)
# -----------------------------
# Correlations: levels and lags
# -----------------------------
# Stored as a named vector to avoid repetitive cor() calls and ensure results are printet in one consistent block
cor_pairs <- c(
  "births ~ house price"         = cor(births_housing_annual$annual_births, births_housing_annual$mean_annual_house_price, use = "complete.obs"),
  "births ~ HPI"                 = cor(births_housing_annual$annual_births, births_housing_annual$mean_annual_hpi,          use = "complete.obs"),
  "births ~ house price (t-1)"   = cor(births_housing_annual$annual_births, births_housing_annual$house_price_lag1,         use = "complete.obs"),
  "births ~ HPI (t-1)"           = cor(births_housing_annual$annual_births, births_housing_annual$hpi_lag1,                 use = "complete.obs"),
  "births ~ house price (t-2)"   = cor(births_housing_annual$annual_births, births_housing_annual$house_price_lag2,         use = "complete.obs"),
  "births ~ HPI (t-2)"           = cor(births_housing_annual$annual_births, births_housing_annual$hpi_lag2,                 use = "complete.obs"),
  "births ~ house price (t-3)" = cor(births_housing_annual$annual_births, births_housing_annual$house_price_lag3,         use = "complete.obs"),
  "births ~ HPI (t-3)"         = cor(births_housing_annual$annual_births, births_housing_annual$hpi_lag3,                 use = "complete.obs"),
  "births ~ house price (t-4)" = cor(births_housing_annual$annual_births, births_housing_annual$house_price_lag4,         use = "complete.obs"),
  "births ~ HPI (t-4)"         = cor(births_housing_annual$annual_births, births_housing_annual$hpi_lag4,                 use = "complete.obs")
)

cat("\n--- Correlations ---\n")
for (nm in names(cor_pairs)) {
  cat(sprintf("  %-35s r = %+.3f\n", nm, cor_pairs[[nm]]))
}

# -----------------------------
# Year-on-year change analysis
# -----------------------------
# Addresses non-stationarity identified by ADF test 
# Differencing reduces trend-on-trend effects to provide a more
# reliable basis for assessing the births-housing relationship.
births_housing_changes <- births_housing_annual |>
  arrange(year) |>
  mutate(
    births_change          = annual_births            - lag(annual_births),
    births_change_pct      = annual_births            / lag(annual_births) - 1,
    house_price_change     = mean_annual_house_price  - lag(mean_annual_house_price),
    house_price_change_pct = mean_annual_house_price  / lag(mean_annual_house_price) - 1,
    hpi_change             = mean_annual_hpi          - lag(mean_annual_hpi),
    hpi_change_pct         = mean_annual_hpi          / lag(mean_annual_hpi) - 1
  )

# Dual-series change over time
# House price change scaled by 1,000 for visual comparability with births
scale_factor <- 1000

ggplot(births_housing_changes, aes(x = year)) +
  geom_line(aes(y = births_change, linetype = "Births change"), linewidth = 1, na.rm = TRUE) +
  geom_line(aes(y = house_price_change / scale_factor,
                linetype = sprintf("House price change (\u00f7%s)", format(scale_factor, big.mark = ","))),
            linewidth = 1, na.rm = TRUE) +
  labs(title   = "Annual changes in births and house prices",
    x       = "Year",
    y       = sprintf("Change  |  House price change \u00f7 %s", format(scale_factor, big.mark = ",")),
    linetype = "Series"
  ) +
  cw2_theme()

# % change: births vs house prices
# Did years with bigger house price increases also see bigger changes in births?
ggplot(births_housing_changes, aes(x = house_price_change_pct, y = births_change_pct)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE) +
  scale_x_continuous(labels = scales::percent) +
  scale_y_continuous(labels = scales::percent) +
  labs(
    title = "Annual % change: births vs house prices",
    x = "House price annual % change",
    y = "Births annual % change"
  ) +
  cw2_theme()

# % change: births vs HPI
# Did years with bigger HPI increases also see bigger changes in births?
ggplot(births_housing_changes, aes(x = hpi_change_pct, y = births_change_pct)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE) +
  scale_x_continuous(labels = scales::percent) +
  scale_y_continuous(labels = scales::percent) +
  labs(
    title = "Annual % change: births vs HPI",
    x = "HPI annual % change",
    y = "Births annual % change"
  ) +
  cw2_theme()

# Barchart of year-on-year births change
ggplot(births_housing_changes, aes(x = year, y = births_change)) +
  geom_col() +
  labs(
    title = "Year-to-year change in annual births",
    x = "Year",y = "Change in births") +
  cw2_theme()

# -----------------------------
# Save merged exploration dataset
# -----------------------------
write_csv(
  births_housing_annual,
  "project/data/processed/births_housing_annual_exploration.csv"
)

# -----------------------------
# Findings
# -----------------------------
#
# Data range:
#   2006-2025 (20 complete years). 2026 excluded — partial year (to Feb 2026).
#   Data restricted to 2006-2024 for the modelling phase.
#
# Trend:
#   Annual births show a sustained downward movement across the observed period.
#   Births declined ~17.8% between 2006 and 2024
#   Births declined ~25% relative to the 2010-2012 peak 
#   House prices fell sharply after the financial crisis, then recovered
#   and sustained upward growth.
#
# Stationarity:
#   ADF test confirms the births series is non-stationary (p = 0.5796).
#   Raw-level correlations are treated cautiously as a result.
#
# Pandemic period:
#   Annual births fell sharply from 2020 while house prices continued to rise.
#   This strengthens the negative raw-level association, but the pattern likely
#   reflects wider COVID-19 disruption and should not be interpreted as evidence
#   of a housing effect alone.
#
# Relationship (raw levels):
#   Births and house prices show a moderate negative association — years with
#   higher house prices tended to coincide with lower births.
#
# Change-on-change check:
#   The association weakens under year-on-year % changes, suggesting part of
#   the raw-level signal reflects shared long-run trends rather than a direct
#   relationship.
#
# Decision:
#   Housing retained as a plausible predictor for modelling, but simple annual
#   correlations treated cautiously and not over-interpreted.
#
# Lag structure:
#   Lags 1-4 explored based on XGBoost/RF modelling findings suggesting
#   lag 4 was a strong predictor. Each additional lag costs one year of
#   usable observations — with 20 years of data, lag 4 leaves 16 complete
#   cases, which is worth noting ahead of the modelling phase.