# ***********************************************************
# Title: PEIB Tutorial 7 - Does cleantech FDI drive the diffusion of solar energy?
#
# Purpose: Clean: rename the variables. No value changes.
#
# Authors: [your name]
# Requires: sol_raw.rds
#     ID variables: country-year
# Creates: sol_inter.rds
#     ID variables: country-year
# ***********************************************************

# ***********************************************************
# Part 1: Rename variables ----
# ***********************************************************

sol <- readRDS(file.path(sol_raw, "sol_raw.rds"))

# Short names: country, iso3, year, solar_gw
setnames(sol, c("country", "iso3", "year", "solar_gw"))

saveRDS(sol, file.path(sol_inter, "sol_inter.rds"))
