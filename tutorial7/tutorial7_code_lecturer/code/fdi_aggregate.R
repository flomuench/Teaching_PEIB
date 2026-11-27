# ***********************************************************
# Title: PEIB Tutorial 7 - Does cleantech FDI drive the diffusion of solar energy?
#
# Purpose: Aggregate: collapse the project list to one row per destination country and year
#
# Authors: [your name]
# Requires: fdi_inter.rds
#     ID variables: project
# Creates: fdi_final.rds
#     ID variables: country-year
# ***********************************************************

# ***********************************************************
# Part 1: From projects to country-years ----
# ***********************************************************

fdi <- readRDS(file.path(fdi_inter, "fdi_inter.rds"))

# Number of projects and total announced investment per country and year.
# na.rm = TRUE: projects without a published amount count as zero in the sum.
# Response to Question 4.6 a)
fdi <- fdi[, .(n_projects = .N, invest_bn = sum(invest_bn, na.rm = TRUE)),
           by = .(country, year)]

saveRDS(fdi, file.path(fdi_final, "fdi_final.rds"))
