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
# How to run: open tutorial7_code_lecturer.Rproj in RStudio (so that R starts in the code folder
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

# Lecturer's version: code on GitHub (repo Teaching_PEIB, folder tutorial7), data and output
# on OneDrive (module folder, week7/project/tutorial7_project).
# The student version uses Documents/GitHub/tutorial7_code and OneDrive/tutorial7_project.
if (.Platform$OS.type != "windows") stop("The lecturer's version is set up for Windows only.")
code_root <- file.path("C:/Users", user_name, "Documents/GitHub/Teaching_PEIB/tutorial7/tutorial7_code_lecturer")
data_root <- file.path("C:/Users", user_name, "OneDrive - University College London/UCL teaching/Political Economy of International Business/PEIB_Florian_Irakli/lectures_tutorials/week7/project/tutorial7_project")
# Check: show both paths and test that both folders exist
# Response to Question 3.1 c)
print(code_root)
print(data_root)
print(dir.exists(c(code_root, data_root)))   # both must be TRUE

### Code folder ----
code <- file.path(code_root, "code")

### Data and output folders ----
d <- file.path(data_root, "data")

fdi_raw   <- file.path(d, "fdi", "raw")
fdi_inter <- file.path(d, "fdi", "inter")
fdi_final <- file.path(d, "fdi", "final")

# Response to Question 3.2
sol_raw   <- file.path(d, "sol", "raw")
sol_inter <- file.path(d, "sol", "inter")
sol_final <- file.path(d, "sol", "final")

an_final  <- file.path(d, "an", "final")

output  <- file.path(data_root, "output")
out_fig <- file.path(output, "figures")
# Response to Question 3.2
out_tab <- file.path(output, "tables")

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
# Response to Question 4.4
# 3.1: Import the raw solar capacity file
#   Requires: installed-solar-pv-capacity.csv
#   Creates:  sol_raw.rds
if (1) source(file.path(code, "sol_import.R"), echo = TRUE)

# 3.2: Clean: rename variables
#   Requires: sol_raw.rds
#   Creates:  sol_inter.rds
if (1) source(file.path(code, "sol_clean.R"), echo = TRUE)

# 3.3: Correct: drop rows that are not countries
#   Requires: sol_inter.rds
#   Creates:  sol_inter.rds
if (1) source(file.path(code, "sol_correct.R"), echo = TRUE)

# 3.4: Generate: log of solar capacity
#   Requires: sol_inter.rds
#   Creates:  sol_final.rds
if (1) source(file.path(code, "sol_generate.R"), echo = TRUE)

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
