# Response to Question 2.1 b): this whole script (created from fdi_correct.R in the student version)
# ***********************************************************
# Title: PEIB Tutorial 7 - Does cleantech FDI drive the diffusion of solar energy?
#
# Purpose: Generate: create new variables from existing ones
#
# Authors: [your name]
# Requires: fdi_inter.rds
#     ID variables: project
# Creates: fdi_inter.rds
#     ID variables: project
# ***********************************************************

# ***********************************************************
# Part 1: New variables ----
# ***********************************************************

fdi <- readRDS(file.path(fdi_inter, "fdi_inter.rds"))

# Dummy: 1 if the investing firm is headquartered in China
# Response to Question 4.5 a)
fdi[, china := fifelse(home_country == "China", 1L, 0L)]

# Investment in billion US dollars instead of million
# Response to Question 4.5 a)
fdi[, invest_bn := invest_musd / 1000]

saveRDS(fdi, file.path(fdi_inter, "fdi_inter.rds"))
