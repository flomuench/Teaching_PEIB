# ***********************************************************
# Title: PEIB Tutorial 7 - Does cleantech FDI drive the diffusion of solar energy?
#
# Purpose: Generate: logarithm of installed solar capacity
#
# Authors: [your name]
# Requires: sol_inter.rds
#     ID variables: country-year
# Creates: sol_final.rds
#     ID variables: country-year
# ***********************************************************

# ***********************************************************
# Part 1: Log of solar capacity ----
# ***********************************************************

sol <- readRDS(file.path(sol_inter, "sol_inter.rds"))

# The log is only defined for positive values; country-years with zero capacity stay missing
# Response to Question 4.5 b)
sol[solar_gw > 0, log_solar_gw := log(solar_gw)]

saveRDS(sol, file.path(sol_final, "sol_final.rds"))
