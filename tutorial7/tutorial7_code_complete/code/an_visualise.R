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

fig <- ggplot(an[year == 2024 & solar_gw > 0], aes(x = fdi_cum, y = solar_gw)) +
  geom_point(colour = "#4C78A8") +
  scale_y_log10(breaks = c(0.00001, 0.001, 0.1, 10, 1000),
                labels = c("0.00001", "0.001", "0.1", "10", "1,000")) +
  labs(x = "Cleantech FDI projects announced since 2000",
       y = "Installed solar capacity in 2024 (GW, log scale)") +
  theme_classic()

# Save the figure twice: pdf (sharp in LaTeX and Word) and png (for slides and web)
ggsave(file.path(out_fig, "solar_fdi_scatter.pdf"), plot = fig, width = 7, height = 4.5)
ggsave(file.path(out_fig, "solar_fdi_scatter.png"), plot = fig, width = 7, height = 4.5, dpi = 300)
