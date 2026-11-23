# ***********************************************************
# Title: PEIB Tutorial 7 - Does cleantech FDI drive the diffusion of solar energy?
#
# Purpose: Correct: give Kosovo a proper code; drop continents, income groups and the world total
#
# Authors: [your name]
# Requires: sol_inter.rds
#     ID variables: country-year
# Creates: sol_inter.rds
#     ID variables: country-year
# ***********************************************************

# ***********************************************************
# Part 1: Drop rows that are not countries ----
# ***********************************************************

sol <- readRDS(file.path(sol_inter, "sol_inter.rds"))

# Kosovo carries the code OWID_KOS; the usual code is XKX
sol[iso3 == "OWID_KOS", iso3 := "XKX"]

# Rows without a country code, or with an OWID_ code, are aggregates (World, Europe, ...)
# your_code_here (Question 4.3)

saveRDS(sol, file.path(sol_inter, "sol_inter.rds"))
