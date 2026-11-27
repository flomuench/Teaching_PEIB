# ***********************************************************
# Title: PEIB Tutorial 7 - Does cleantech FDI drive the diffusion of solar energy?
#
# Purpose: Correct: change values that are wrong or inconsistent; drop projects that did not go ahead
#
# Authors: [your name]
# Requires: fdi_inter.rds
#     ID variables: project
# Creates: fdi_inter.rds
#     ID variables: project
# ***********************************************************

# ***********************************************************
# Part 1: Fix country names, drop projects that did not go ahead ----
# ***********************************************************

fdi <- readRDS(file.path(fdi_inter, "fdi_inter.rds"))

# Two destination countries are spelled differently from the solar data
# Response to Question 3.5 a)
fdi[country == "Czech Republic", country := "Czechia"]
fdi[country == "UAE", country := "United Arab Emirates"]

# Projects that were cancelled, paused or closed are not investments
fdi <- fdi[!status %in% c("Cancelled", "Paused", "Closed")]

saveRDS(fdi, file.path(fdi_inter, "fdi_inter.rds"))
