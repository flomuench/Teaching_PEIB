# ***********************************************************
# Title: PEIB Tutorial 7 - Does cleantech FDI drive the diffusion of solar energy?
#
# Purpose: Clean: keep the variables we need and give them short names. No value changes.
#
# Authors: [your name]
# Requires: fdi_raw.rds
#     ID variables: project
# Creates: fdi_inter.rds
#     ID variables: project
# ***********************************************************

# ***********************************************************
# Part 1: Keep and rename variables ----
# ***********************************************************

fdi <- readRDS(file.path(fdi_raw, "fdi_raw.rds"))

# Keep 8 of the 28 columns
fdi <- fdi[, .(`Project ID`, `Parent company`, `Company Country (HQ)`, `Project Status`,
               `Destination Country`, `Year Announced`, Technology, `Capital Investment (US$m)`)]

# Short lower-case names without spaces
setnames(fdi, c("project_id", "parent", "home_country", "status",
                "country", "year", "technology", "invest_musd"))

saveRDS(fdi, file.path(fdi_inter, "fdi_inter.rds"))
