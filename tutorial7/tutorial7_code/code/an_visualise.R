# ***********************************************************
# Title: PEIB Tutorial 7 - Does cleantech FDI drive the diffusion of solar energy?
#
# Purpose: Visualise: solar capacity against cumulative cleantech FDI projects, latest year
#
# Authors: [your name]
# Requires: an_final.rds
#     ID variables: country-year
# Creates: output/figures/solar_fdi_scatter.pdf and .png
#     ID variables: country
# ***********************************************************

# ***********************************************************
# Part 1: Scatter plot, saved as pdf and png ----
# ***********************************************************

an <- readRDS(file.path(an_final, "an_final.rds"))

# your_code_here (Question 4.8)

# Save the figure twice: pdf (sharp in LaTeX and Word) and png (for slides and web)
ggsave(file.path(out_fig, "solar_fdi_scatter.pdf"), plot = fig, width = 7, height = 4.5)
ggsave(file.path(out_fig, "solar_fdi_scatter.png"), plot = fig, width = 7, height = 4.5, dpi = 300)
