# CRISP-DM Phase 4: Modeling
# ============================
# Objective: Select and apply modelling techniques and calibrate parameters.
#
# Key tasks:
#   - Select modelling techniques
#   - Generate a test design
#   - Build models
#   - Assess models (technical quality, not business value)

# TODO All models need to follow the same validation strategy!!!
# Validation Strategy: Rolling Window Cross-Validation
# Since we have ~80 rows (quarters) across our chosen years, we adjust the rolling origin parameters:
#   initial: 60 quarters = 15 years of training
#   assess: 4 quarters = 1 year of testing
#   skip: 3 = slide by 1 year (4 quarters - 1)
ts_folds <- rolling_origin(
  model_features,
  initial    = 60,
  assess     = 4,
  cumulative = TRUE,
  skip       = 3
)