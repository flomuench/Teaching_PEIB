# ***********************************************************
# Title: PEIB Tutorial 7 - Does cleantech FDI drive the diffusion of solar energy?
#
# Purpose: Import the raw list of cleantech manufacturing FDI projects
#
# Authors: [your name]
# Requires: cm-fdi-projects.csv
#     ID variables: project
# Creates: fdi_raw.rds
#     ID variables: project
# ***********************************************************

# ***********************************************************
# Part 1: Import the raw project list ----
# ***********************************************************

# The raw csv is never edited. We read it and save an unchanged copy in R's own format.
# your_code_here (Question 3.3)

saveRDS(fdi, file.path(fdi_raw, "fdi_raw.rds"))
