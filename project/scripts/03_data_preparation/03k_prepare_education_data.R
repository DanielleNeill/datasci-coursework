# CRISP-DM Phase 3: Data Preparation
# Prepare quarterly education (school leaver) dataset
# =====================================
# Key tasks:
# - Convert annual school leaver data into quarterly series via interpolation to match with births/housing/employment.
# - Align the "Exit Year" (e.g., 2006 for a 05/06 cohort) with calendar quarters
# - Provide a clean dataset for ARIMA (exclude engineered features and move those into a subsequent script)

library(tidyverse)
library(lubridate)
library(zoo)

# 1. Load and clean the annual education data
edu_raw <- read_csv("project/data/raw/education/ni_school_leavers_girls_destinations_all_years.csv")

# 2. Map the academic year to the education 'Exit Year' (e.g., 2005/06 becomes 2006 as when students finish a year)
edu_annual <- edu_raw %>%
  rename(he_pct = Higher_Education_Pct, fe_pct = Further_Education_Pct, total_girls = Total_Girls) %>%
  mutate(
    year = as.numeric(paste0("20", substr(Year, 6, 7)))
  ) %>%
  select(year, he_pct, fe_pct, total_girls)

glimpse(edu_annual)
# Rows: 20
# Columns: 4
# $ year        <dbl> 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014…
# $ he_pct      <dbl> 45.6, 44.3, 45.3, 47.3, 48.8, 48.4, 48.3, 49.5, 48.7, 48.1…
# $ fe_pct      <dbl> 29.7, 30.9, 29.8, 29.8, 32.5, 33.1, 31.4, 33.3, 33.2, 34.2…
# $ total_girls <dbl> 12375, 12491, 12211, 11955, 11671, 11444, 11313, 11153, 11…
summary(edu_annual)
#       year          he_pct          fe_pct       total_girls
#  Min.   :2005   Min.   :44.30   Min.   :26.20   Min.   :10195
#  1st Qu.:2010   1st Qu.:48.10   1st Qu.:29.80   1st Qu.:10926
#  Median :2014   Median :48.95   Median :31.45   Median :11284
#  Mean   :2014   Mean   :49.30   Mean   :31.05   Mean   :11297
#  3rd Qu.:2019   3rd Qu.:50.40   3rd Qu.:32.55   3rd Qu.:11676
#  Max.   :2024   Max.   :56.30   Max.   :34.20   Max.   :12491
# --> We only have eduction data from 2005 (given 2004/05) to 2024 (2025 not yet released)

# 3. Create the Quarterly Template (2006 Q1 to 2024 Q4 is our agreed upon period within our group)
# Basically this will use the annual value for the 4 quarters of the year, further processing of this below.
# Start with the first quarter of our study period up to the last quarter in 2024 (end of our study period)
# Note that it was education that limited our study period given the 2025 data was unavailable.
edu_quarterly <- data.frame(
  quarter_start_date = seq(as.Date("2006-01-01"), as.Date("2024-10-01"), by = "3 months")
) %>%
  mutate(year = year(quarter_start_date))

View(edu_quarterly)
glimpse(edu_quarterly)
# Rows: 76
# Columns: 2
# $ quarter_start_date <date> 2006-01-01, 2006-04-01, 2006-07-01, 2006-10-01, 20…
# $ year               <dbl> 2006, 2006, 2006, 2006, 2007, 2007, 2007, 2007, 200…
summary(edu_quarterly)
#  quarter_start_date        year
#  Min.   :2006-01-01   Min.   :2006
#  1st Qu.:2010-09-08   1st Qu.:2010
#  Median :2015-05-16   Median :2015
#  Mean   :2015-05-17   Mean   :2015
#  3rd Qu.:2020-01-23   3rd Qu.:2020
#  Max.   :2024-10-01   Max.   :2024

# 4. Join and Interpolate
# Interpolate the annual education data into a quarterly frequency to align with our Employment Rate and Housing data.
# This avoids significant jumps which can arise from repeating annual values and instead assumes gradual change
# between yearly observations so the series aligns more realistically with our quarterly data from Housing/Education.
# This transforms 19 annual rows (we also excluded 2005) into 76 quarterly rows (see summary output below).
# Pros: Aligns available education data with quarterly employment/housing data, and avoids artificialstep changes
#       we would get from repeating the same annual value, and should allow for smoother time-series modeling.
# Cons: Quarterly values are estimated (so not actual observations) by assuming gradual within-year changes,
#       and may give a false sense of higher data frequency beyond what we actually had.
# TODO It is important for us to acknowledge that we did this in our writeup!
# We can justify that interpolation is methodologically acceptable in our model because:
# a. Education trends tend to move slowly (interpolation is not really suitable when there are jumps between years).
#    Although there is a jump / instability during COVID, our data analysis shows a mostly steady change over time.
# b. Although we are including it as a predictor, education can and will also act as a control variable:
#      Controlling for education helps to isolate the relationship between our main short-term predictors
#      (employment rate and housing conditions) for birth rates. While included as a model predictor in the
#      ARIMA/RF/XGBoost frameworks we have chosen, its role is also to help capture slower-moving
#      background changes in educational participation, that could otherwise confuse impact of job market
#      and housing effects.
# c. We are expecting the key variation to be in job and housing market changes
#    --> Interestingly our results actually showed that employment rate was the best predictor for RF/XGBoost,
#        whereas Housing was the least useful for the fomulas that were identified and applied.

# 4a. Prepare annual data with an anchor quarter (retains the actual annual value from the raw dataset)
# --> Q3 is when school year end so it makes sense to use this as the common anchor point.
edu_annual_anchored <- edu_annual %>%
  mutate(quarter_num = 3L)

View(edu_annual_anchored)
glimpse(edu_annual_anchored)
# Rows: 20
# Columns: 5
# $ year        <dbl> 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014…
# $ he_pct      <dbl> 45.6, 44.3, 45.3, 47.3, 48.8, 48.4, 48.3, 49.5, 48.7, 48.1…
# $ fe_pct      <dbl> 29.7, 30.9, 29.8, 29.8, 32.5, 33.1, 31.4, 33.3, 33.2, 34.2…
# $ total_girls <dbl> 12375, 12491, 12211, 11955, 11671, 11444, 11313, 11153, 11…
# $ quarter_num <int> 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3

# 4b. Join it to the quarterly template created above and apply the interpolation
# Note that 2006 Q1-Q3 will remain constant (44.3/12491) in the output dataset because they precede our first
# quarterly anchor point (2006 Q3), with interpolation starting after this to reach the 2007 anchor (45.3/12211).
# Ref: https://stackoverflow.com/a/33697009 / https://stackoverflow.com/a/7318951
# Ref: https://www.rdocumentation.org/packages/zoo/versions/1.8-15/topics/na.approx
edu_quarterly_clean <- edu_quarterly %>%
  select(quarter_start_date, year) %>%
  mutate(quarter_num = quarter(quarter_start_date)) %>%
  left_join(edu_annual_anchored, by = c("year", "quarter_num")) %>% #  e.g. [1] NA NA 44.3 NA NA NA 45.3 ...
  mutate( # Interpolate on the NA values introduced by the left_join (all but the anchor point)
    he_pct      = na.approx(he_pct, na.rm = FALSE, rule = 2), # 2, the value at the closest data extreme is used.
    fe_pct      = na.approx(fe_pct, na.rm = FALSE, rule = 2),
    total_girls = na.approx(total_girls, na.rm = FALSE, rule = 2)
  ) %>%
  mutate(quarter = paste0("Q", quarter_num)) %>%
  select(quarter_start_date, year, quarter, quarter_num, he_pct, fe_pct, total_girls)

# 5. Review and then Save
View(edu_quarterly_clean)
glimpse(edu_quarterly_clean)
# Rows: 76
# Columns: 7
# $ quarter_start_date <date> 2006-01-01, 2006-04-01, 2006-07-01, 2006-10-01, 20…
# $ year               <dbl> 2006, 2006, 2006, 2006, 2007, 2007, 2007, 2007, 200…
# $ quarter            <chr> "Q1", "Q2", "Q3", "Q4", "Q1", "Q2", "Q3", "Q4", "Q1…
# $ quarter_num        <int> 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, …
# $ he_pct             <dbl> 44.300, 44.300, 44.300, 44.550, 44.800, 45.050, 45.…
# $ fe_pct             <dbl> 30.900, 30.900, 30.900, 30.625, 30.350, 30.075, 29.…
# $ total_girls        <dbl> 12491.00, 12491.00, 12491.00, 12421.00, 12351.00, 1…
summary(edu_quarterly_clean)
#  quarter_start_date        year        quarter           quarter_num       he_pct          fe_pct       total_girls
#  Min.   :2006-01-01   Min.   :2006   Length:76          Min.   :1.00   Min.   :44.30   Min.   :26.20   Min.   :10195
#  1st Qu.:2010-09-08   1st Qu.:2010   Class :character   1st Qu.:1.75   1st Qu.:48.34   1st Qu.:30.01   1st Qu.:10926
#  Median :2015-05-16   Median :2015   Mode  :character   Median :2.50   Median :49.10   Median :31.82   Median :11198
#  Mean   :2015-05-17   Mean   :2015                      Mean   :2.50   Mean   :49.48   Mean   :31.12   Mean   :11246
#  3rd Qu.:2020-01-23   3rd Qu.:2020                      3rd Qu.:3.25   3rd Qu.:50.57   3rd Qu.:32.58   3rd Qu.:11567
#  Max.   :2024-10-01   Max.   :2024                      Max.   :4.00   Max.   :56.30   Max.   :34.20   Max.   :12491
write_csv(edu_quarterly_clean, "project/data/processed/education_rate_quarterly_occurrence.csv")