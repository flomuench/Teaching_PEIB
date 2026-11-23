# ***********************************************************
# Title: PEIB Tutorial 7 - Does cleantech FDI drive the diffusion of solar energy?
#
# Purpose: Import the raw solar capacity file
#
# Authors: [your name]
# Requires: installed-solar-pv-capacity.csv
#     ID variables: country-year
# Creates: sol_raw.rds
#     ID variables: country-year
# ***********************************************************

# ***********************************************************
# Part 1: Import the raw solar capacity file ----
# ***********************************************************

# The raw csv is never edited. We read it and save an unchanged copy in R's own format.
sol <- fread(file.path(sol_raw, "installed-solar-pv-capacity.csv"))

saveRDS(sol, file.path(sol_raw, "sol_raw.rds"))
