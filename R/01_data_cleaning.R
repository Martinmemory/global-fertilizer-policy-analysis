#!/usr/bin/env Rscript

# 01_data_cleaning.R
# Clean the Our World in Data / FAOSTAT nitrogen-fertilizer panel and the
# ten-country displayed-data extract used in the paper.

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

required_packages <- c("dplyr")
available <- vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
if (!all(available)) {
  stop("Missing required R packages: ", paste(required_packages[!available], collapse = ", "))
}
suppressPackageStartupMessages(library(dplyr))

source_dir <- file.path(root, "data", "source")
processed_dir <- file.path(root, "data", "processed")
table_dir <- file.path(root, "tables")
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)

raw_file <- file.path(source_dir, "nitrogen_fertilizer_use_per_hectare_1961_2023.csv")
ten_country_file <- file.path(source_dir, "ten_country_displayed_1961_2023.csv")
stopifnot(file.exists(raw_file), file.exists(ten_country_file))

raw <- read.csv(raw_file, check.names = FALSE, stringsAsFactors = FALSE)
stopifnot(identical(names(raw), c(
  "Entity", "Code", "Year", "Use of nutrient nitrogen per area of cropland"
)))

panel <- raw |>
  rename(
    entity = Entity,
    code = Code,
    year = Year,
    nitrogen_kg_ha = `Use of nutrient nitrogen per area of cropland`
  ) |>
  mutate(
    year = as.integer(year),
    nitrogen_kg_ha = as.numeric(nitrogen_kg_ha)
  ) |>
  arrange(entity, year)

stopifnot(nrow(panel) == 12568L)
stopifnot(n_distinct(panel$entity) == 242L)
stopifnot(min(panel$year) == 1961L, max(panel$year) == 2023L)
stopifnot(!anyNA(panel[c("entity", "year", "nitrogen_kg_ha")]))
stopifnot(!anyDuplicated(panel[c("entity", "year")]))
stopifnot(all(panel$nitrogen_kg_ha >= 0))

world <- panel |>
  filter(entity == "World") |>
  mutate(t = year - min(year))

stopifnot(nrow(world) == 63L)
stopifnot(identical(world$t, 0:62))

selected_regions <- c(
  "Africa (FAO)",
  "Eastern Asia (FAO)",
  "Europe (FAO)",
  "Northern America (FAO)",
  "South America (FAO)",
  "Southern Asia (FAO)"
)

regions <- panel |>
  filter(entity %in% selected_regions) |>
  mutate(
    entity = factor(entity, levels = selected_regions),
    region_label = recode(
      as.character(entity),
      "Africa (FAO)" = "Africa",
      "Eastern Asia (FAO)" = "Eastern Asia",
      "Europe (FAO)" = "Europe",
      "Northern America (FAO)" = "Northern America",
      "South America (FAO)" = "South America",
      "Southern Asia (FAO)" = "Southern Asia"
    )
  )

stopifnot(n_distinct(regions$entity) == length(selected_regions))

write.csv(panel, file.path(processed_dir, "nitrogen_panel_clean.csv"), row.names = FALSE)
write.csv(world, file.path(processed_dir, "world_series_1961_2023.csv"), row.names = FALSE)
write.csv(regions, file.path(processed_dir, "regional_series_1961_2023.csv"), row.names = FALSE)

selected_countries <- c(
  "Australia", "France", "Japan", "South Korea", "United States",
  "Brazil", "China", "India", "Nigeria", "Pakistan"
)

ten_raw <- read.csv(ten_country_file, check.names = FALSE, stringsAsFactors = FALSE)
names(ten_raw)[names(ten_raw) == "Use of nutrient nitrogen per area of cropland"] <- "nitrogen_kg_ha"
stopifnot(identical(sort(unique(ten_raw$Entity)), sort(selected_countries)))

ten_country <- ten_raw[, c("Entity", "Code", "Year", "nitrogen_kg_ha")]
ten_country <- ten_country[order(match(ten_country$Entity, selected_countries), ten_country$Year), ]

counts <- table(ten_country$Entity)
stopifnot(nrow(ten_country) == 630L)
stopifnot(length(counts) == 10L)
stopifnot(all(counts[selected_countries] == 63L))
stopifnot(!anyNA(ten_country))
stopifnot(!anyDuplicated(ten_country[c("Entity", "Year")]))

write.csv(
  ten_country,
  file.path(processed_dir, "ten_country_series_1961_2023.csv"),
  row.names = FALSE
)

country_summary <- do.call(rbind, lapply(selected_countries, function(country) {
  x <- ten_country[ten_country$Entity == country, ]
  peak_index <- which.max(x$nitrogen_kg_ha)
  data.frame(
    country = country,
    observations = nrow(x),
    start_year = x$Year[1],
    start_kg_ha = x$nitrogen_kg_ha[1],
    end_year = x$Year[nrow(x)],
    end_kg_ha = x$nitrogen_kg_ha[nrow(x)],
    peak_year = x$Year[peak_index],
    peak_kg_ha = x$nitrogen_kg_ha[peak_index],
    stringsAsFactors = FALSE
  )
}))
write.csv(country_summary, file.path(table_dir, "ten_country_summary.csv"), row.names = FALSE)

coverage_by_entity <- panel |>
  group_by(entity, code) |>
  summarise(
    first_year = min(year),
    last_year = max(year),
    observations = n(),
    .groups = "drop"
  )
write.csv(coverage_by_entity, file.path(table_dir, "coverage_by_entity.csv"), row.names = FALSE)

message("Data cleaning completed.")
message("World observations: ", nrow(world))
message("Ten-country observations: ", nrow(ten_country))
