# ***********************************************************
# Title: PEIB Tutorial 7 - Does cleantech FDI drive the diffusion of solar energy?
#
# Purpose: Regress: log solar capacity on cumulative FDI projects, country and year fixed effects
#
# Authors: [your name]
# Requires: an_final.rds
#     ID variables: country-year
# Creates: output/tables/reg_solar_fdi.docx and reg_solar_fdi_r.tex
#     ID variables: -
# ***********************************************************

# ***********************************************************
# Part 1: Two regressions and the table ----
# ***********************************************************

an <- readRDS(file.path(an_final, "an_final.rds"))

# r1: no fixed effects; r2: country and year fixed effects.
# Standard errors clustered by country (observations of one country are not independent).
r1 <- feols(log_solar_gw ~ fdi_cum, data = an, cluster = ~country)
r2 <- feols(log_solar_gw ~ fdi_cum | country + year, data = an, cluster = ~country)

# Show the table in the Console
etable(r1, r2)

# Export the table with modelsummary: Word (.docx, through flextable) and LaTeX (.tex)
models <- list("(1) No fixed effects" = r1, "(2) Country and year fixed effects" = r2)
labels <- c(fdi_cum = "Cumulative FDI projects")
gof    <- list(list(raw = "nobs", clean = "Observations",
                    fmt = function(x) format(x, big.mark = ",")))
note   <- "Standard errors clustered by country in brackets."
tab <- modelsummary(models, output = "flextable", coef_map = labels, gof_map = gof, notes = note)
tab <- flextable::autofit(tab)   # column widths that fit the text
flextable::save_as_docx(tab, path = file.path(out_tab, "reg_solar_fdi.docx"))
# The .tex file needs \usepackage{xcolor} and \usepackage{tabularray} in the LaTeX preamble
options(modelsummary_format_numeric_latex = "plain")
modelsummary(models, output = file.path(out_tab, "reg_solar_fdi_r.tex"),
             coef_map = labels, gof_map = gof, notes = note)
