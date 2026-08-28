#!/usr/bin/env Rscript

# 03_visualization.R
# Reproduce the paper figures from processed data.
# Figure 1 is a ggplot global trend; Figure 3 is the base-R externality diagram
# used in the final manuscript.

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

required_packages <- c("ggplot2", "dplyr", "scales")
available <- vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
if (!all(available)) {
  stop("Missing required R packages: ", paste(required_packages[!available], collapse = ", "))
}
suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(scales)
})

processed_dir <- file.path(root, "data", "processed")
figure_dir <- file.path(root, "figures")
additional_dir <- file.path(figure_dir, "additional")
dir.create(additional_dir, recursive = TRUE, showWarnings = FALSE)

world <- read.csv(file.path(processed_dir, "world_series_1961_2023.csv"), stringsAsFactors = FALSE)
regions <- read.csv(file.path(processed_dir, "regional_series_1961_2023.csv"), stringsAsFactors = FALSE)

world_start <- world |> slice_min(year, n = 1, with_ties = FALSE)
world_end <- world |> slice_max(year, n = 1, with_ties = FALSE)
world_peak <- world |> slice_max(nitrogen_kg_ha, n = 1, with_ties = FALSE)

theme_paper <- theme_minimal(base_family = "Arial", base_size = 11) +
  theme(
    plot.title = element_text(face = "plain", size = 13, color = "black", margin = margin(b = 5)),
    plot.subtitle = element_text(size = 10.5, color = "black", margin = margin(b = 9)),
    plot.caption = element_text(size = 8.5, color = "black", hjust = 0, margin = margin(t = 8)),
    axis.title = element_text(size = 10.5, color = "black"),
    axis.text = element_text(size = 9.5, color = "black"),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "grey88", linewidth = 0.35),
    plot.margin = margin(12, 14, 10, 12)
  )

fig1 <- ggplot(world, aes(year, nitrogen_kg_ha)) +
  geom_line(linewidth = 0.85, color = "black") +
  geom_point(data = bind_rows(world_start, world_peak, world_end), size = 2.2, color = "black") +
  geom_smooth(method = "lm", formula = y ~ x, se = TRUE, color = "grey35", fill = "grey80", linewidth = 0.65) +
  annotate(
    "text", x = world_start$year + 2.5, y = world_start$nitrogen_kg_ha - 2,
    label = sprintf("1961: %.1f", world_start$nitrogen_kg_ha), hjust = 0, size = 3.1
  ) +
  annotate(
    "text", x = world_peak$year - 1.5, y = world_peak$nitrogen_kg_ha + 3.5,
    label = sprintf("Peak %d: %.1f", world_peak$year, world_peak$nitrogen_kg_ha), hjust = 1, size = 3.1
  ) +
  annotate(
    "text", x = world_end$year - 1.5, y = world_end$nitrogen_kg_ha - 3,
    label = sprintf("2023: %.1f", world_end$nitrogen_kg_ha), hjust = 1, size = 3.1
  ) +
  scale_x_continuous(breaks = seq(1960, 2020, by = 10), limits = c(1960, 2024)) +
  scale_y_continuous(labels = label_number(accuracy = 1), expand = expansion(mult = c(0.04, 0.10))) +
  labs(
    title = "Global nitrogen fertilizer use per hectare of cropland, 1961–2023",
    subtitle = "The gray line and confidence band summarize a linear time trend; they are not a policy-effect estimate.",
    x = "Year",
    y = "Nitrogen fertilizer use (kg N/ha of cropland)",
    caption = "Source: FAO (2025), with major processing by Our World in Data. Author's calculations."
  ) +
  theme_paper

ggsave(
  file.path(additional_dir, "global-nitrogen-trend-ggplot.png"),
  fig1, width = 7.1, height = 4.7, dpi = 320, bg = "white"
)

fig2 <- ggplot(regions, aes(year, nitrogen_kg_ha)) +
  geom_line(linewidth = 0.75, color = "black") +
  facet_wrap(~ region_label, ncol = 2) +
  scale_x_continuous(breaks = seq(1960, 2020, by = 20), limits = c(1960, 2024)) +
  scale_y_continuous(labels = label_number(accuracy = 1), limits = c(0, NA)) +
  labs(
    title = "Nitrogen fertilizer use differs sharply across broad FAO regions",
    subtitle = "Each panel represents a multi-country regional aggregate, not a small selection of countries.",
    x = "Year",
    y = "Nitrogen fertilizer use (kg N/ha of cropland)",
    caption = "Source: FAO (2025), with major processing by Our World in Data. Author's calculations."
  ) +
  theme_paper +
  theme(
    strip.text = element_text(face = "plain", color = "black", size = 10.2),
    strip.background = element_rect(fill = "grey94", color = "grey70", linewidth = 0.4)
  )

ggsave(
  file.path(additional_dir, "regional-nitrogen-trends.png"),
  fig2, width = 7.1, height = 6.5, dpi = 320, bg = "white"
)

# Base-R externality diagram used as the paper's Figure 3.
quantity <- seq(0, 90, by = 0.25)
mpb <- 120 - quantity
mpc <- 20 + 0.6 * quantity
msc <- 45 + 0.6 * quantity
q_market <- (120 - 20) / (1 + 0.6)
q_efficient <- (120 - 45) / (1 + 0.6)
mpb_at_market <- 120 - q_market
msc_at_market <- 45 + 0.6 * q_market
mpc_at_efficient <- 20 + 0.6 * q_efficient
msc_at_efficient <- 45 + 0.6 * q_efficient

png(
  file.path(additional_dir, "negative-production-externality.png"),
  width = 1400, height = 900, res = 180, bg = "white"
)
par(mar = c(5.0, 5.6, 3.2, 2.0), family = "sans", las = 1, xaxs = "i", yaxs = "i")
plot(
  quantity, mpb, type = "n", xlim = c(0, 92), ylim = c(0, 125),
  axes = FALSE,
  xlab = "Nitrogen fertilizer use",
  ylab = "Marginal benefit and marginal cost",
  main = "Negative Production Externality",
  font.main = 1, cex.main = 1.25, cex.lab = 1.05
)
arrows(0, 0, 91, 0, length = 0.08, angle = 20)
arrows(0, 0, 0, 123, length = 0.08, angle = 20)
polygon(
  x = c(q_efficient, q_market, q_market),
  y = c(msc_at_efficient, msc_at_market, mpb_at_market),
  col = "grey85", border = NA
)
lines(quantity, mpb, lwd = 2.0, lty = 1)
lines(quantity, mpc, lwd = 2.0, lty = 2)
lines(quantity, msc, lwd = 2.0, lty = 3)
label_x <- 82
text(label_x + 1.5, 120 - label_x, "MPB", pos = 4, cex = 1.0)
text(label_x + 1.5, 20 + 0.6 * label_x, "MPC", pos = 4, cex = 1.0)
text(label_x + 1.5, 45 + 0.6 * label_x, "MSC", pos = 4, cex = 1.0)
segments(q_efficient, 0, q_efficient, msc_at_efficient, lty = 3)
segments(q_market, 0, q_market, msc_at_market, lty = 3)
text(q_efficient, 3.5, expression(Q^"*"), cex = 1.05)
text(q_market, 3.5, expression(Q[m]), cex = 1.05)
arrows(
  q_efficient, mpc_at_efficient, q_efficient, msc_at_efficient,
  code = 3, length = 0.08, angle = 20
)
text(q_efficient - 2.0, (mpc_at_efficient + msc_at_efficient) / 2, "MEC", pos = 2, cex = 0.95)
text(55.5, 72.5, "DWL", cex = 0.95)
dev.off()

message("Figures written to ", additional_dir)
