# ***********************************************************
# Title: PEIB Tutorial 7 - Does cleantech FDI drive the diffusion of solar energy?
#
# Purpose: Main script. It is the ONLY file you run. It loads the packages, defines all
#          folder paths and then runs every other script in the right order.
#       Part 1: Settings, packages and paths (always runs)
#       Part 2: Cleantech FDI projects (prefix fdi)
#       Part 3: Solar capacity (prefix sol)
#       Part 4: Analysis data set: merge, visualise, regress (prefix an)
#
# Authors: [your name]
# Requires: the raw files cm-fdi-projects.csv and installed-solar-pv-capacity.csv
# Creates: everything in data/*/inter, data/*/final and output/
# ***********************************************************

# ***********************************************************
# Part 1: Settings, packages and paths ----
# ***********************************************************
# How to run: open tutorial7_code.Rproj in RStudio (so that R starts in the code folder
# that GitHub tracks), then run this script from top to bottom (button Source).
# Run single lines with Ctrl + Enter (Mac: Cmd + Enter).
# Document outline (list of the parts): Ctrl + Shift + O (Mac: Cmd + Shift + O).

### Packages ----
# pacman installs a package if it is missing and then loads it.
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(
  data.table,    # data handling: import, clean, correct, generate, aggregate, merge
  ggplot2,       # figures
  fixest,        # regressions with fixed effects
  modelsummary,  # regression tables
  flextable      # Word (.docx) export of the regression table
)

### User name and the two root folders ----
# R reads your user name on this computer, so nobody has to type it into a path.
user_name <- Sys.info()[["user"]]

# Code: local Documents/GitHub folder (tracked by Git, shared on GitHub).
# Data and output: OneDrive folder (NOT on GitHub).
# The only thing you may have to change is the name of your OneDrive folder (Question 3.1).
if (.Platform$OS.type == "windows") {
  code_root <- file.path("C:/Users", user_name, "Documents/GitHub/tutorial7_code")
  data_root <- file.path("C:/Users", user_name, "OneDrive - University College London/tutorial7_project")
} else {  # Mac
  code_root <- file.path("/Users", user_name, "Documents/GitHub/tutorial7_code")
  data_root <- file.path("/Users", user_name, "Library/CloudStorage/OneDrive-UniversityCollegeLondon/tutorial7_project")
}
# Check: show both paths and test that both folders exist
# your_code_here (Question 3.1)

### Code folder ----
code <- file.path(code_root, "code")

### Data and output folders ----
d <- file.path(data_root, "data")

fdi_raw   <- file.path(d, "fdi", "raw")
fdi_inter <- file.path(d, "fdi", "inter")
fdi_final <- file.path(d, "fdi", "final")

# your_code_here (Question 3.2)

an_final  <- file.path(d, "an", "final")

output  <- file.path(data_root, "output")
out_fig <- file.path(output, "figures")
# your_code_here (Question 3.2)

# ***********************************************************
# Part 2: Cleantech FDI projects (fdi) ----
# ***********************************************************
# Switch a step on with if (1) and off with if (0).

# 2.1: Import the raw project list
#   Requires: cm-fdi-projects.csv
#   Creates:  fdi_raw.rds
if (1) source(file.path(code, "fdi_import.R"), echo = TRUE)

# 2.2: Clean: keep and rename variables (no values change)
#   Requires: fdi_raw.rds
#   Creates:  fdi_inter.rds
if (1) source(file.path(code, "fdi_clean.R"), echo = TRUE)

# 2.3: Correct: fix country names, drop projects that did not go ahead
#   Requires: fdi_inter.rds
#   Creates:  fdi_inter.rds
if (1) source(file.path(code, "fdi_correct.R"), echo = TRUE)

# 2.4: Generate: new variables
#   Requires: fdi_inter.rds
#   Creates:  fdi_inter.rds
if (1) source(file.path(code, "fdi_generate.R"), echo = TRUE)

# 2.5: Aggregate: from projects to country-years
#   Requires: fdi_inter.rds
#   Creates:  fdi_final.rds
if (1) source(file.path(code, "fdi_aggregate.R"), echo = TRUE)

# ***********************************************************
# Part 3: Solar capacity (sol) ----
# ***********************************************************
# your_code_here (Question 4.4)

# ***********************************************************
# Part 4: Analysis data set (an) ----
# ***********************************************************
# 4.1: Merge solar capacity and FDI by country and year
#   Requires: sol_final.rds, fdi_final.rds
#   Creates:  an_final.rds
if (1) source(file.path(code, "an_merge.R"), echo = TRUE)

# 4.2: Visualise: one figure
#   Requires: an_final.rds
#   Creates:  output/figures/solar_fdi_scatter.pdf and .png
if (1) source(file.path(code, "an_visualise.R"), echo = TRUE)

# 4.3: Regress: one regression table
#   Requires: an_final.rds
#   Creates:  output/tables/reg_solar_fdi.docx and reg_solar_fdi_r.tex
if (1) source(file.path(code, "an_regress.R"), echo = TRUE)
