# =============================================================================
# make_figures.R - static PNG figures for Word handouts (and the website)
# =============================================================================
#
# HOW TO RUN
#   1. Open Teaching_PEIB.Rproj in RStudio. This sets the working directory to
#      the repository root (the folder containing _quarto.yml).
#   2. Open this file and click "Source" (or run source("R/make_figures.R")).
#   3. The PNGs appear in figures/. Commit and push them with GitHub Desktop
#      so the website shows the updated versions.
#
# HOW TO PUT A FIGURE INTO WORD
#   Insert > Pictures > This Device... > choose the PNG in figures/.
#   The files are 300 dpi at 6 x 4.5 inches, so they print sharply. If Word
#   shows them too large, right-click > Size and Position > set width 15 cm
#   with "Lock aspect ratio" ticked.
#
# The diagram itself is drawn by draw_market() in R/models.R - the same code
# the interactive website app uses, so handouts and website always match.
# =============================================================================


# -----------------------------------------------------------------------------
# 0. Safety check: are we in the repository root?
# -----------------------------------------------------------------------------
if (!file.exists("R/models.R")) {
  stop("Cannot find R/models.R from the current working directory:\n  ",
       getwd(), "\n",
       "Open Teaching_PEIB.Rproj in RStudio (or setwd() to the repository ",
       "root, the folder that contains _quarto.yml) and run this script again.",
       call. = FALSE)
}
source("R/models.R")                       # loads market_outcomes(), draw_market()
dir.create("figures", showWarnings = FALSE) # create figures/ if it is missing


# =============================================================================
# >>> PARAMETERS - edit here so the figures match your handout questions <<<
# =============================================================================
# Demand: P = a - b*Q    Supply: P = c + d*Q    Per-unit tax: t
tut01 <- list(a = 12, b = 1, c = 2, d = 1)
tut01_tax <- 3                                   # tax used in the second figure

# Figure size and resolution (inches and dots per inch)
fig_width  <- 6
fig_height <- 4.5
fig_dpi    <- 300
# Axis ranges: a narrower range than the website app's 0-20 zooms in on the
# action. Keep them the same in both figures so they are comparable.
fig_xlim <- c(0, 12)
fig_ylim <- c(0, 14)
# =============================================================================


# -----------------------------------------------------------------------------
# Helper: draw one figure into a PNG file
# -----------------------------------------------------------------------------
# png() opens a file "device", everything plotted goes into the file, and
# dev.off() closes and saves it. on.exit() makes sure the file is closed even
# if draw_market() stops with an error.
save_market_png <- function(file, tax, main) {
  png(file, width = fig_width, height = fig_height, units = "in",
      res = fig_dpi)
  on.exit(dev.off())
  out <- draw_market(a = tut01$a, b = tut01$b, c = tut01$c, d = tut01$d,
                     tax = tax, xlim = fig_xlim, ylim = fig_ylim, main = main)
  message("Saved ", file)
  invisible(out)
}


# -----------------------------------------------------------------------------
# Tutorial 1 figures
# -----------------------------------------------------------------------------
eq <- save_market_png("figures/tutorial01_market_equilibrium.png", tax = 0,
                      main = "Market equilibrium without a tax")
tx <- save_market_png("figures/tutorial01_market_tax.png", tax = tut01_tax,
                      main = paste0("Market with a per-unit tax of ", tut01_tax))

# Print the numbers too, handy for writing the answer key of the handout.
# print() is needed because RStudio's "Source" button does not auto-print.
print(round(unlist(eq[c("Q0", "P0", "CS", "PS")]), 2))
print(round(unlist(tx[c("Qt", "Pb", "Ps", "CS", "PS", "tax_revenue", "DWL")]), 2))
