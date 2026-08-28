#!/usr/bin/env Rscript

# Run the fertilizer-policy analysis from the repository root.
source("R/01_data_cleaning.R")
source("R/02_analysis.R")
source("R/03_visualization.R")
capture.output(sessionInfo(), file = "sessionInfo.txt")
message("All scripts completed.")
