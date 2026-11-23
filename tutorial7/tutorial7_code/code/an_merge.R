# ***********************************************************
# Title: PEIB Tutorial 7 - Does cleantech FDI drive the diffusion of solar energy?
#
# Purpose: Merge solar capacity (all country-years) with FDI projects
#
# Authors: [your name]
# Requires: sol_final.rds, fdi_final.rds
#     ID variables: country-year
# Creates: an_final.rds
#     ID variables: country-year
# ***********************************************************

# ***********************************************************
# Part 1: Merge solar capacity and FDI ----
# ***********************************************************

sol <- readRDS(file.path(sol_final, "sol_final.rds"))
fdi <- readRDS(file.path(fdi_final, "fdi_final.rds"))

# Keep every country-year of the solar data (all.x = TRUE) and add the FDI columns
# your_code_here (Question 4.7)

# Check the merge: how many FDI country-years found no partner in the solar data?
cat("FDI country-years:", nrow(fdi), "| matched:", sum(!is.na(an$n_projects)), "\n")

# Country-years without a project have no FDI: set missing to zero
an[is.na(n_projects), `:=`(n_projects = 0L, invest_bn = 0)]

# Running total of projects announced in each country since 2000
setorder(an, country, year)
an[, fdi_cum := cumsum(n_projects), by = country]

saveRDS(an, file.path(an_final, "an_final.rds"))
