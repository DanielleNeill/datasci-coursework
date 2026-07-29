# CRISP-DM Phase 2: Data Understanding
# ======================================
# Objective: Review the Employment Rate dataset to build an understanding of its contents.
#
# Key tasks:
#   - Load the data as obtained from the source.
#   - Describe the data in terms of volume, format & attributes.
#   - Explore the data in terms of distributions, relationships & if outliers exist.
#   - Verify the data quality to understand that it is usable for our study.
#
# References which helped the team with ggplot creation:
# 1. H. Wickham, M. et al., ‘R for Data Science’, 2nd ed. CA, USA: O'Reilly Media, Inc., 2023
# 2. Posit Software, PBC, 'Data Visualization with ggplot2: Cheat Sheet', 2021. [Online].
#    Available: https://posit.co/wp-content/uploads/2022/10/data-visualization-1.pdf

# Setup steps, load libraries and check the configuration.
getwd() # Confirm that the working directory is at the root of our project
getOption("repos") # Should show "https://cloud.r-project.org" set from .Rprofile at project root
install.packages("tidyverse")
install.packages("psych")
library(tidyverse)
library(stats)
library(psych)

# 1. Load the Raw Data from the Labour Force Survey (LF62) from the csv file in the data/raw directory
# For now we will load the full file to see the structure and assess the 1992-2025 range available.
# Note that there is no header in this raw CSV and the first 8 lines do not contain any data, so skip those:
#   "Title","LFS: Employment rate: Northern Ireland: Aged 16-64: Female: %: SA"
#   "CDID","LF62"
#   "Source dataset ID","LMS"
#   "PreUnit",""
#   "Unit","%"
#   "Release date","17-02-2026"
#   "Next release","19 March 2026"
#   "Important notes",
raw_df <- read.csv("./project/data/raw/economic_inactivity/1_Labour_Force_Survey_lf62.csv", header = FALSE, skip = 8)
colnames(raw_df) <- c("date_raw", "emp_rate") # Do a column name reassignment on our 2 available columns in the dataset
raw_df$emp_rate <- as.numeric(raw_df$emp_rate) # Convert the Value column to numeric (double) type

# 2. Perform a visual inspection of the data frequency
# Note that this dataset contains Annual, Quarterly (Q1, Q2), and Monthly (JAN, FEB) entries.
# As agreed between our group after we assessed all our chosen datasets, we will use Quarterly.
# Note that the data in the raw CSV file is ordered, so we are looking at specific sections of the csv:
print(head(raw_df, 20)) # Shows Annual entries, example entry '7 1992  54.2'
print(raw_df[60:80, ])  # Shows Quarterly entries, example entry '60 1997 Q1 57.4'
print(tail(raw_df, 20)) # Shows Monthly entries, example entry '560 2024 APR 70.1'

# Notes on using the entire dataset vs restricting to a specific range of 2006-2024.
# In our CRISP-DM project flow, the decision for what period we used was based primarily on our modeling goal.
# The are pros and cons, e.g. more available data vs the risk of learning a relationship from 1994 that was
# no longer true in 2025. Also, for some datasets we simply didn't have the same range of available data.
# Group Recommendation --> Restrict to 2006-2024 because of:
#   1. Economic Transition: The 1990s were a post-conflict transition in NI, so it is very likely that the relationship
#                           between employment and family life was fundamentally different during those times.
#   2. Concept Drift:       By using older data we risk teaching ML models outdated patterns that no longer applied
#                           in the 2024 economy.
#   3. Policy Alignment:    Modern childcare and/or parental leave policies that influence the link between work and
#                           birth rates only really stabilised in the mid-2000s.

# 3. Perform a preliminary visualisation of the data (to identify any trends and seasonality)
# To understand the data correctly, we can isolate the quarterly series temporarily and focus on this range.
# The date_raw column is in the raw form, and contains a few different strings that we need to extract from:
#   "2024" --> year only
#   "1992 Q2" --> year + quarter
#   "1999 OCT" --> year + abbreviated month
# Leverage lubridate to help with working with dates and times here and filter to our range:
#   https://lubridate.tidyverse.org/reference/year.html
#   https://lubridate.tidyverse.org/reference/ymd.html
quarterly_only <- raw_df %>%
  filter(grepl("Q1|Q2|Q3|Q4", date_raw)) %>%
  mutate(date = yq(date_raw)) %>%
  filter(!is.na(date)) %>%
  filter(year(date) >= 2006 & year(date) < 2025) %>%
  drop_na(emp_rate)

# Double check this is doing what it is supposed to do
print(head(quarterly_only, 5))
#   date_raw emp_rate       date
# 1  2006 Q1     61.0 2006-01-01
# 2  2006 Q2     61.8 2006-04-01
# 3  2006 Q3     60.9 2006-07-01
# 4  2006 Q4     61.8 2006-10-01
# 5  2007 Q1     62.6 2007-01-01

describe(quarterly_only$emp_rate)
#    vars  n  mean   sd median trimmed  mad  min  max range skew kurtosis   se
# X1    1 76 64.63 2.85   63.9   64.57 3.34 59.2 70.4  11.2 0.22    -1.16 0.33
sd(quarterly_only$emp_rate) # 2.849672
summary(quarterly_only)
#   date_raw            emp_rate          date
# Length:76          Min.   :59.20   Min.   :2006-01-01
# Class :character   1st Qu.:62.17   1st Qu.:2010-09-08
# Mode  :character   Median :63.90   Median :2015-05-16
# Mean   :64.63   Mean   :2015-05-17
# 3rd Qu.:67.03   3rd Qu.:2020-01-23
# Max.   :70.40   Max.   :2024-10-01

# Plotting the raw trend to better understand the behavior of the economic variable
# Show the employment rate over time within our set range.
understanding_quarterly_plot <- ggplot(quarterly_only, aes(x = date, y = emp_rate)) +
  geom_line(color = "darkblue") +
  theme_minimal() +
  labs(title = "Initial Business Understanding: Female Employment Rate (NI)",
       subtitle = "Raw Monthly Series (2006-2024)",
       y = "Employment Rate (%)")

print(understanding_quarterly_plot)

# 4. Identify Seasonality (2006-2024)
# Convert the raw data into a time series (ts) and break it into trend, seasonal, and residual components to help
# us understand if we need to account for any seasonal peaks/troughs.
ts_obj_emp_rate <- ts(quarterly_only$emp_rate, frequency = 4, start = c(2006, 1), end = c(2024, 4))
# Had to adapt this a little to get a better description for adding into the paper.
dec_emp <- decompose(ts_obj_emp_rate)
plot(dec_emp,
     col = "darkred", 
     lwd = 2,
     ann = TRUE,
     cex.lab = 0.9,
     yax.flip = FALSE)
mtext("ONS Labour Market Statistics (2006-2024): Quarterly Employment Rate",
      side = 1, line = 4, adj = 1, cex = 1, font = 6)

# As per Week 4, Exercise 1, filter out the random signal
# Again this shows the overall rise in employmet over the date range.
emp_components <- decompose(ts_obj_emp_rate)
emp_components <- ts_obj_emp_rate - emp_components$random
plot.ts(emp_components)

# 5. Findings for the 2006-2024 range (76 observations)
# Trend:       Since 2006, there has been a fairly significant upward trend in female employment in Northern Ireland,
#              rising from approximately 60% in 2006 to over 69% in late 2024.
# Seasonality: The data shows consistent seasonal fluctuations with peaks and troughs within each year
#              which likely a consequence of job market trends for hiring cycles and holiday periods.
# Stability:   The standard deviation is relatively low (2.849672) indicating a steady growth path with a
#              dip during the 2020-2021 period (likely COVID-19 related).

# 6. Employment Rate vs Economic Inactivity
# There was a choice to be made here as to whether to use the employment rate directly, or to calculate the
# female economic inactivity rate (i.e. 100 - Female Employment Rate). Both were options available to us given
# the data we had access to. However, in many labour datasets (like the ONS or NISRA), this formula does not
# always apply because of a third category which is unemployment (those that are not working but are actively
# seeking work), but that is not something we could have easily calculated for this study using our datasets.

# Using employment rate allows the study to model the Opportunity Cost (i.e. you have more to lose (wages, career
# progression) if you choose to have children) and Income Effect on birthrate for those in active careers
# (i.e. having money provides the financial security and resources needed to have children), whereas
# economic inactivity would shift the focus toward those already outside the labour market due to reasons
# such as health, education, or existing family committments. However as mentioned above, calculating this
# accurately would be difficult because we don't have data on unemployment and the proportion that were seeking work
# at the time.

# A good description on Opportunity Cost is available here:
# https://www.linkedin.com/top-content/leadership/setting-leadership-priorities/opportunity-cost-in-career-choices/

# From the Literature:
# 1. Berrington et al., 2023
# Quote: "Other things being equal the economic opportunity costs of childbearing are higher for women who are in paid
#         employment outside the home (Becker, 1981). Thus we expect intentions to be more positive among those not
#         currently in paid work."
# --> This somewhat justifies using Employment Rate as a primary predictor because it tracks the population facing the
#     'Opportunity Cost' barrier, i.e. those in careers have less time to have children.

# 2. Dow, 2025
# Quote: "Older women earning higher wages face a greater opportunity cost of their time and thus outsource childcare,
#         making them more sensitive to its price."
# Quote: "I demonstrate that older mothers can be more price responsive than younger mothers because they earn a higher
#         wage, and so the opportunity cost of their time is higher. Women earning higher wages will outsource more,
#         if not all, childcare. This high level of outsourcing will drive greater price responsiveness." (p. 46-47)
# --> Employment rate therefore, again, captures the population facing the Opportunity Cost conflict, which is a primary
#     driver of modern delays to having children.

# 3. Tzitiridou-Chatzopoulou et al., 2024
# Quote: "Factors such as education levels, work prospects for women, childcare expenses, and larger economic factors
#         all contribute to determining decisions on fertility."
# --> Aligns with the finding that non-linear models (XGBoost) perform better by capturing complex relationships
#     between economic participation and birth rates.

# Decision: We will use Employment Rate (LF62) as it represents a cross-over between career participation and
#           fertility as identified (and described above) in the literature.

# 7. Visualise the distribution of the employment rate
ggplot(quarterly_only, aes(x = emp_rate)) +
  geom_histogram(bins = 20, fill = "seagreen", color = "white") +
  geom_density(aes(y = after_stat(count) * 0.5), color = "red") +
  theme_minimal() +
  labs(title = "Distribution of the Female Employment Rate",
       x = "Employment Rate (%)", y = "Frequency")

# Analysis of this histogram --> shows bimodal peaks for the female employment rate (with peaks at ~63% & ~68%)
# This dual peak may suggest that the labour market operates in two distinct economic phases/zones.

# 8. Use a Boxplot to identify statistical outliers
ggplot(quarterly_only, aes(y = emp_rate)) +
  geom_boxplot(fill = "orange", alpha = 0.7) +
  theme_minimal() +
  labs(title = "Outlier Check: Female Employment Rate", y = "Rate (%)")

# Analysis of this boxplot --> general summary --> a wide distribution showing a negative skew
# 1. Distribution: The median sits at ~64%, which shows that for half the series employment rate was below the higher
#    intensity ~67%-70% threshold. i.e. it is weighted towards a generally lower intensity labour pattern.
# 2. Outliers: There are no statistical outliers detected - the lower end values (~59%) are
#    within the expected range (within the boxplot whiskers), i.e. the low employment periods were steady and
#    long-term rather than a one-off break from the top of the scale where employment rates were very high.
# 3. Spread: The large Interquartile Range (~62.5% to 67%) shows significant volatility in the female employment
#    rates, which provides sufficient variance to test Opportunity Cost impacts during different economic cycles.
