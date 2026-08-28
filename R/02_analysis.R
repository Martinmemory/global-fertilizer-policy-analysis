#!/usr/bin/env Rscript

# 02_analysis.R
# World-series time-trend regressions used in the paper:
# OLS (reported in Table 1) and Newey-West standard errors (robustness).

source_helper <- function() {
  helper <- file.path("R", "_project_root.R")
  if (file.exists(helper)) {
    source(helper)
    return(invisible(NULL))
  }
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) >= 1L) {
    script_path <- gsub("~\\+~", " ", sub("^--file=", "", file_arg[[1]]))
    source(file.path(dirname(normalizePath(script_path)), "_project_root.R"))
    return(invisible(NULL))
  }
  stop("Cannot locate R/_project_root.R. Run from the repository root.")
}
source_helper()
root <- find_project_root()
setwd(root)

required_packages <- c("dplyr", "sandwich", "lmtest")
available <- vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
if (!all(available)) {
  stop("Missing required R packages: ", paste(required_packages[!available], collapse = ", "))
}
suppressPackageStartupMessages({
  library(dplyr)
  library(sandwich)
  library(lmtest)
})

processed_dir <- file.path(root, "data", "processed")
table_dir <- file.path(root, "tables")
dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)

world <- read.csv(file.path(processed_dir, "world_series_1961_2023.csv"), stringsAsFactors = FALSE)
stopifnot(nrow(world) == 63L)
stopifnot(identical(as.integer(world$year), 1961:2023))

world_start <- world |> slice_min(year, n = 1, with_ties = FALSE)
world_end <- world |> slice_max(year, n = 1, with_ties = FALSE)
world_peak <- world |> slice_max(nitrogen_kg_ha, n = 1, with_ties = FALSE)
world_low <- world |> slice_min(nitrogen_kg_ha, n = 1, with_ties = FALSE)

descriptive_summary <- data.frame(
  statistic = c(
    "Start year", "Start value (kg N/ha)", "End year", "End value (kg N/ha)",
    "Absolute change (kg N/ha)", "Percent change", "Peak year", "Peak value (kg N/ha)",
    "Low year", "Low value (kg N/ha)", "Mean (kg N/ha)", "Standard deviation (kg N/ha)"
  ),
  value = c(
    world_start$year,
    world_start$nitrogen_kg_ha,
    world_end$year,
    world_end$nitrogen_kg_ha,
    world_end$nitrogen_kg_ha - world_start$nitrogen_kg_ha,
    100 * (world_end$nitrogen_kg_ha / world_start$nitrogen_kg_ha - 1),
    world_peak$year,
    world_peak$nitrogen_kg_ha,
    world_low$year,
    world_low$nitrogen_kg_ha,
    mean(world$nitrogen_kg_ha),
    sd(world$nitrogen_kg_ha)
  )
)
write.csv(descriptive_summary, file.path(table_dir, "descriptive_summary.csv"), row.names = FALSE)

# Paper Table 1: ordinary least squares, t = 0 in 1961.
ols_model <- lm(nitrogen_kg_ha ~ t, data = world)
ols_summary <- summary(ols_model)
ols_ci <- confint(ols_model, level = 0.95)
ols_coef <- ols_summary$coefficients

ols_table <- data.frame(
  term = c("Intercept", "Time trend (t)"),
  estimate = ols_coef[, "Estimate"],
  ols_standard_error = ols_coef[, "Std. Error"],
  t_statistic = ols_coef[, "t value"],
  p_value = ols_coef[, "Pr(>|t|)"],
  ci_95_low = ols_ci[, 1],
  ci_95_high = ols_ci[, 2],
  r_squared = c(ols_summary$r.squared, NA_real_),
  observations = c(nobs(ols_model), NA_real_),
  row.names = NULL,
  check.names = FALSE
)
write.csv(ols_table, file.path(table_dir, "world_ols_regression.csv"), row.names = FALSE)

capture.output(
  "Model: nitrogen_kg_ha = alpha + beta * t + error",
  "Coding: t = 0 in 1961 and t = 62 in 2023",
  "",
  ols_summary,
  "",
  "95 percent confidence intervals:",
  ols_ci,
  file = file.path(table_dir, "world_ols_regression_full_output.txt")
)

# Additional HAC standard errors from the original analysis pipeline.
nw_vcov <- NeweyWest(ols_model, prewhite = FALSE, adjust = TRUE)
nw_test <- coeftest(ols_model, vcov. = nw_vcov)
nw_margin <- sqrt(diag(nw_vcov)) * qnorm(0.975)

nw_table <- data.frame(
  term = c("Intercept", "Time trend (t)"),
  estimate = unname(nw_test[, "Estimate"]),
  newey_west_se = unname(nw_test[, "Std. Error"]),
  statistic = unname(nw_test[, "t value"]),
  p_value = unname(nw_test[, "Pr(>|t|)"]),
  ci_95_lower = unname(coef(ols_model) - nw_margin),
  ci_95_upper = unname(coef(ols_model) + nw_margin),
  r_squared = c(ols_summary$r.squared, NA_real_),
  observations = c(nobs(ols_model), NA_real_)
)
write.csv(nw_table, file.path(table_dir, "trend_regression_results.csv"), row.names = FALSE)

capture.output(
  ols_summary,
  "",
  "Newey-West covariance estimate:",
  nw_test,
  file = file.path(table_dir, "trend_regression_full_output.txt")
)

message("OLS time coefficient: ", round(coef(ols_model)[["t"]], 3), " kg N/ha per year")
message("OLS R-squared: ", round(ols_summary$r.squared, 3))
message("Analysis completed.")
