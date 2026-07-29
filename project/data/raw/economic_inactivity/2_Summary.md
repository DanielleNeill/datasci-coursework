
Predictor Assessment Criteria

| Criterion                                  | Assessment                                           | Suitability |
| ------------------------------------------ | ---------------------------------------------------- | ----------- |
| **Data availability / Source reliability** | ONS & NISRA official statistics                      | High        |
| **Frequency**                              | Monthly releases (rolling averages)                  | Very useful |
| **Time coverage (2006–2025)**              | Only during census periods                           | No          |
| **Theoretical relevance**                  | Strong (labour conditions → fertility behaviour)     | Yes         |
| **Previous research use**                  | Yes — employment/inactivity used in fertility models | Yes         |
| **Missing values**                         | None in official series                              | Yes         |
| **Bias / Representativeness**              | Standard LFS methodology                             | Acceptable  |

# 1. Predictor Needs

Your variable of interest is:

**Female Economic Inactivity Rate (or Female Employment Rate)**

Economic inactivity typically means people **not in employment and not actively seeking work**, including:

- Students
- Homemakers
- Long-term sick or disabled
- Retired early
- Other inactive groups

This variable is theoretically relevant because research shows **economic security strongly affects fertility timing and parity decisions**.

The literature source (Ann Berrington et al., 2023) supports the inclusion of **economic activity/employment status** as a determinant of fertility behaviour.

# 2. Dataset Source

[https://build.nisra.gov.uk/en/](https://build.nisra.gov.uk/en/)

# 3. Create a New Table

On the homepage:

1. Click **Create Table**
2. You will see three main areas:
    - **Geography**
    - **Topics (Attributes)**
    - **Measures**

For your project, you want a **time-series compatible indicator**, but note:

⚠️ Census data is **cross-sectional (2021 only)**  
So it is mainly useful for **contextual variables**, not monthly predictors.

Therefore you must verify **whether this dataset is suitable**.

# 4. Select Geography

Required:

- **Northern Ireland**

Smaller areas are available with this dataset.

# 5. Select Relevant Attributes

You must filter attributes to **construct an economic inactivity rate for females**.
### Required Attributes

Include:
#### 1. Sex

Use to isolate females.
Select:

- **Female**

#### 2. Economic Activity

This is the **core variable**.

Review of the NISRA classifications:

| Classification Option | Categories Included                                                                                       | Advantages                                                                                                                  | Limitations                                                                          | Suitable for Project |
| --------------------- | --------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ | -------------------- |
| 3 Categories          | In employment; Not in employment                                                                          | Very simple structure                                                                                                       | Combines unemployed and inactive groups, losing important labour market distinctions | No                   |
| 4 Categories          | In employment; Unemployed; Economically inactive                                                          | Clear labour market separation; aligns with standard employment statistics; easy to compute employment and inactivity rates | Slightly less detail than full classification                                        | Yes (Recommended)    |
| 5 Categories          | Employee; Self-employed; Unemployed; Inactive                                                             | Distinguishes employment types                                                                                              | Employee vs self-employed adds unnecessary complexity for fertility modelling        | No                   |
| 9 Categories          | Employee; Self-employed; Unemployed; Retired; Student; Looking after home; Long-term sick; Other inactive | Provides detailed breakdown of inactivity reasons                                                                           | Too granular for a macroeconomic predictor; unnecessary for forecasting              | No                   |
| 12 Categories         | Full labour market breakdown including student employment and self-employment types                       | Maximum detail for labour economics research                                                                                | Overly complex; introduces noise and sparse data for ML forecasting                  | No                   |

| Attribute         | Selected Option           | Reason for Inclusion                                                  |
| ----------------- | ------------------------- | --------------------------------------------------------------------- |
| Geography         | Northern Ireland          | Matches the birth dataset geography                                   |
| Sex               | Female                    | Fertility relates directly to female population                       |
| Age               | 15–44                     | Standard reproductive age range                                       |
| Economic Activity | 4 category classification | Allows calculation of female employment and economic inactivity rates |

**Economic Inactivity Rate**

From this data we can calculate the Economic Inactivity Rate:

$$
\text{Inactivity Rate} =
\frac{\text{Inactive Population}}{\text{Working Age Population}}
$$
#### 3. Age

Fertility is age dependent.

Review of the NISRA classifications:

| Age Classification Option      | Example Categories                       | Advantages                                                                  | Limitations                                                                                    | Suitable for Project |
| ------------------------------ | ---------------------------------------- | --------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- | -------------------- |
| Single-year ages               | 0, 1, 2, …, 99                           | Maximum precision; complete population breakdown                            | Extremely granular; unnecessary for fertility forecasting; increases table size and complexity | No                   |
| Full population (0–99)         | All ages combined                        | Simplest dataset                                                            | Includes children and elderly; not relevant to fertility analysis                              | No                   |
| Working-age population (16–64) | 16–19, 20–24, …, 60–64                   | Standard labour market definition                                           | Includes large population not relevant to births                                               | No                   |
| Reproductive age range         | 15–44                                    | Standard demographic fertility range; aligns with most birth statistics     | Slight loss of detailed age fertility patterns                                                 | Yes (Recommended)    |
| Detailed fertility age bands   | 15–19, 20–24, 25–29, 30–34, 35–39, 40–44 | Matches demographic fertility research; captures postponement of childbirth | More complex dataset; not necessary for a single macroeconomic predictor                       | ⚠ Optional           |

### Sources to support age range to use

[1] Office for National Statistics, “User guide to birth statistics,” ONS, London, UK. Available: https://www.ons.gov.uk

[2] World Health Organization, “Total fertility rate – indicator definition,” WHO Global Health Observatory. Available: https://www.who.int

*The analysis focuses on women aged 16–44, approximating the standard reproductive age range used in demographic statistics. The Office for National Statistics defines the General Fertility Rate as the number of live births per 1,000 women aged 15–44, representing the population most at risk of childbearing (ONS, 2024). International organisations such as the World Health Organization also define fertility indicators using age-specific fertility rates for women aged 15–49.*

https://www.ons.gov.uk/peoplepopulationandcommunity/birthsdeathsandmarriages/livebirths/bulletins/birthsummarytablesenglandandwales/2024refreshedpopulations/previous/

https://www.who.int/data/gho/indicator-metadata-registry/imr-details/123

Therefore select '*Age - 19 Categories'* and prepare in R to match the typical categories that represent fertility rate in woman as described above.

*The reproductive-age population was derived by aggregating females aged 15–19, 20–24, 25–29, 30–34, 35–39, and 40–44 from the NISRA census age-band dataset. These five-year age groups correspond to the standard age-specific fertility rate intervals used in demographic analysis. The aggregated population approximates the standard reproductive-age definition (15–44) used in UK fertility statistics.*

# 6. Select the Measure

Choose:

**Count of persons**

![[CleanShot 2026-03-16 at 14.07.22.png]]

# 7. Calculate the Economic Inactivity Rate

Formula:
$$
\text{Female Inactivity Rate} = \frac{\text{Inactive females (15-44)}}{\text{Total females (15-44)}}
$$
# 8. Dataset Summary

|Criterion|Assessment|
|---|---|
|Source|NISRA Census 2021|
|Frequency|Cross-sectional|
|Time coverage|2021 only|
|Missing values|None|
|Bias|Minimal|
|Suitability|Limited for forecasting|

Decision: **Discard as primary predictor due to lack of time-series coverage.**
