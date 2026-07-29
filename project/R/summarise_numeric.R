# R/summarise_numeric.R
# ----------------------
# Example helper function demonstrating how to structure reusable R functions
# in this project.  Place all project-wide helper functions in this directory
# (one function per file, named after the function).

#' Summarise Numeric Columns
#'
#' Returns a tidy data frame of common descriptive statistics for every numeric
#' column in a data frame.
#'
#' @param df  A data frame.
#'
#' @return A data frame with columns: variable, n, n_missing, mean, sd, min,
#'   median, max.
#'
#' @examples
#' summarise_numeric(mtcars)
summarise_numeric <- function(df) {
  stopifnot(is.data.frame(df))

  numeric_cols <- names(df)[vapply(df, is.numeric, logical(1))]

  do.call(rbind, lapply(numeric_cols, function(col) {
    x <- df[[col]]
    data.frame(
      variable  = col,
      n         = length(x),
      n_missing = sum(is.na(x)),
      mean      = mean(x, na.rm = TRUE),
      sd        = sd(x, na.rm = TRUE),
      min       = min(x, na.rm = TRUE),
      median    = median(x, na.rm = TRUE),
      max       = max(x, na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  }))
}
