# ***********************************************************
# Title: SEES0082 Political Economy of International Business, UCL SSEES:
#        course website with interactive diagrams (Teaching_PEIB)
#
# Purpose: Tutorial 1 static figures (300 dpi PNGs) for the Word handouts
#          and the website, plus the numbers for the answer key
#       Part 1: Parameters (one firm, U-shaped costs, the market, the
#               per-unit tax figure, figure size)
#       Part 2: Helper functions that save one figure as a PNG
#       Part 3: Supply side: one firm, steps 1 to 6b
#       Part 4: Demand
#       Part 5: Equilibrium, excess supply and shortage
#       Part 6: Per-unit tax figure (to move to Tutorial 3)
#       Part 7: Answer key numbers (printed in the console)
#
# Authors: Florian Münch
# Requires: Parts 1 and 2 of code/master.R: the path variable o_fig_t1
#     (figures/tutorial1/) and the drawing functions from
#     code/functions_models.R
# Creates: 13 PNGs in figures/tutorial1/ (6 x 4.5 inches, 300 dpi),
#     overwriting the previous versions:
#     tutorial01_firm_step1/2/3/4/5a/5b/6a/6b.png  (Part 3)
#     tutorial01_demand.png                        (Part 4)
#     tutorial01_equilibrium.png, tutorial01_excess_supply.png,
#     tutorial01_shortage.png                      (Part 5)
#     tutorial01_market_tax.png                    (Part 6)
# ***********************************************************

# How to run (explanatory notes):
  # Do not run this script on its own: open Teaching_PEIB.Rproj, open
  # code/master.R and run it (Part 3 switches this script on). master.R sets
  # the folder paths (Part 1) and loads the drawing functions (Part 2).
  # Afterwards commit and push the new PNGs with GitHub Desktop so the
  # website shows them too.
  #
  # How to put a figure into Word: Insert > Pictures > This Device... and
  # choose the PNG in figures/tutorial1/. The files are 300 dpi at 6 x 4.5
  # inches, so they print sharply. If Word shows them too large:
  # right-click > Size and Position > width 15 cm with "Lock aspect ratio"
  # ticked.
  #
  # The diagrams are drawn by draw_firm_step(), draw_market_step() and
  # draw_market() in code/functions_models.R: the same code the interactive
  # website apps use, so handouts and website always match.

# Safety check: stop with a clear message if master.R Parts 1-2 have not run
if (!exists("o_fig_t1") || !exists("draw_firm_step")) {
  stop("o_fig_t1 or the drawing functions are missing. Run code/master.R ",
       "(at least Parts 1 and 2) instead of this script on its own.",
       call. = FALSE)
}
# All Tutorial 1 figures go into their own folder, figures/tutorial1/
# (one folder per tutorial). Create it if it is missing.
dir.create(o_fig_t1, recursive = TRUE, showWarnings = FALSE)


# ***********************************************************
# Part 1: Parameters ----
# ***********************************************************
# Edit here so the figures match your handout questions.

### Figure size, axes and layout ----
# Figure size and resolution (inches and dots per inch)
fig_width  <- 6
fig_height <- 4.5
fig_dpi    <- 300
# Axis ranges: a narrower range than the website app's 0-20 zooms in on the
# action. Keep them the same in all figures so they are comparable.
fig_xlim <- c(0, 12)
fig_ylim <- c(0, 14)
# Handout layout: a numbered tick at every whole number on both axes
# (0, 1, 2, ...), no titles (the handout's caption names the figure), and a
# top margin only as tall as the legend needs (fit_top = TRUE below).
fig_tick_step <- 1

### One firm (Part 3: figures tutorial01_firm_step*) ----
# Steps 1-5: supply = marginal cost, p = c + d*q (same c and d as the
# market's supply curve below, so the two parts of the tutorial connect).
firm01 <- list(c = 2, d = 1,
               shift = c(2, -2),   # step 2: supply moves 2 units right
                                   # (increase; S1 then starts at the
                                   # origin) and 2 units left (decrease)
               P = 8,              # market price p*
               q_unit = 3,         # step 5b: the unit we look at
               FC = 10)            # fixed cost (step 6)

### U-shaped costs (Part 3, step 6) ----
# TVC(q) = alpha*q - beta*q^2 + gamma*q^3
firm01_cubic <- list(alpha = 6, beta = 1, gamma = 1/12)

### The market step by step (Parts 4 and 5) ----
# Demand: P = a - b*Q    Supply: P = c + d*Q (the same line as the firm's MC
# above). With a = 14 the demand curve starts at the top-left corner of the
# 0-14 price axis; P* = 8, Q* = 6, CS = PS = 18.
mkt01 <- list(a = 14, b = 1, c = 2, d = 1,
              q_unit = 3,      # demand figure: the unit whose buyer we look at
              P2_high = 11,    # excess supply figure: a price above P*
              P2_low = 5)      # shortage figure: a price below P*

### Per-unit tax figure (Part 6) ----
# Demand: P = a - b*Q    Supply: P = c + d*Q    Per-unit tax: t
# (This keeps a = 12, unlike the step-by-step market figures above.)
tut01 <- list(a = 12, b = 1, c = 2, d = 1)
tut01_tax <- 3                     # tax used in tutorial01_market_tax.png


# ***********************************************************
# Part 2: Helper functions that save one figure as a PNG ----
# ***********************************************************
# png() opens a file "device", everything plotted goes into the file, and
# dev.off() closes and saves it. on.exit() makes sure the file is closed even
# if a drawing function stops with an error. Each helper returns the
# function's numbers invisibly, for the answer key in Part 7.

### One firm: draw_firm_step() ----
save_firm_png <- function(step, main = NULL) {
  file <- file.path(o_fig_t1, paste0("tutorial01_firm_step", step, ".png"))
  png(file, width = fig_width, height = fig_height, units = "in",
      res = fig_dpi)
  on.exit(dev.off())
  out <- draw_firm_step(step = step, c = firm01$c, d = firm01$d,
                        shift = firm01$shift, P = firm01$P,
                        q_unit = firm01$q_unit, FC = firm01$FC,
                        alpha = firm01_cubic$alpha, beta = firm01_cubic$beta,
                        gamma = firm01_cubic$gamma,
                        xlim = fig_xlim, ylim = fig_ylim, main = main,
                        tick_step = fig_tick_step, fit_top = TRUE)
  message("Saved ", file)
  invisible(out)
}

### The market step by step: draw_market_step() ----
# Market notation: capital P and Q.
save_market_step_png <- function(step, file, P2 = NULL, main = NULL) {
  file <- file.path(o_fig_t1, paste0("tutorial01_", file, ".png"))
  png(file, width = fig_width, height = fig_height, units = "in",
      res = fig_dpi)
  on.exit(dev.off())
  out <- draw_market_step(step = step, a = mkt01$a, b = mkt01$b, c = mkt01$c,
                          d = mkt01$d, q_unit = mkt01$q_unit, P2 = P2,
                          xlim = fig_xlim, ylim = fig_ylim, main = main,
                          tick_step = fig_tick_step, fit_top = TRUE)
  message("Saved ", file)
  invisible(out)
}

### Per-unit tax figure: draw_market() ----
save_market_png <- function(file, tax, main = NULL) {
  file <- file.path(o_fig_t1, file)
  png(file, width = fig_width, height = fig_height, units = "in",
      res = fig_dpi)
  on.exit(dev.off())
  out <- draw_market(a = tut01$a, b = tut01$b, c = tut01$c, d = tut01$d,
                     tax = tax, xlim = fig_xlim, ylim = fig_ylim, main = main,
                     tick_step = fig_tick_step, fit_top = TRUE)
  message("Saved ", file)
  invisible(out)
}


# ***********************************************************
# Part 3: Supply side: one firm, steps 1 to 6b ----
# ***********************************************************
# Where does the supply curve come from? Steps are named "1" to "4", then
# "5a", "5b", "6a", "6b". No titles in the PNGs; what each step shows:
f1  <- save_firm_png("1")    # the supply curve
f2  <- save_firm_png("2")    # shifts in supply
f3  <- save_firm_png("3")    # total revenue
f4  <- save_firm_png("4")    # total variable cost
f5a <- save_firm_png("5a")   # producer surplus
f5b <- save_firm_png("5b")   # producer surplus, one unit at a time
f6a <- save_firm_png("6a")   # costs and producer surplus (areas)
f6b <- save_firm_png("6b")   # producer surplus vs profit (rectangles)


# ***********************************************************
# Part 4: Demand ----
# ***********************************************************
# Demand curve, consumer surplus, and one unit: its buyer's willingness to
# pay = price paid + surplus
m_dem <- save_market_step_png("demand", "demand")


# ***********************************************************
# Part 5: Equilibrium, excess supply and shortage ----
# ***********************************************************
m_eq  <- save_market_step_png("equilibrium", "equilibrium")
m_es  <- save_market_step_png("excess_supply", "excess_supply",
                              P2 = mkt01$P2_high)
m_sh  <- save_market_step_png("shortage", "shortage", P2 = mkt01$P2_low)


# ***********************************************************
# Part 6: Per-unit tax figure (to move to Tutorial 3) ----
# ***********************************************************
# Explanatory notes:
  # This figure comes from the first version of Tutorial 1. It is no longer
  # shown on the Tutorial 1 page (tutorials/tutorial01_market.qmd): the
  # section "Preview of Tutorial 3" and the per-unit tax app were removed
  # on 2026-10-04. The figure is kept for Tutorial 3 and will MOVE THERE
  # later (probably redrawn as a subsidy); when that happens, move its line
  # below into the Tutorial 3 script.
  # (The no-tax version, tutorial01_market_equilibrium.png, was dropped in
  # October 2026: Figure 8, tutorial01_equilibrium.png, replaces it.)
tx <- save_market_png("tutorial01_market_tax.png", tax = tut01_tax)


# ***********************************************************
# Part 7: Answer key numbers (printed in the console) ----
# ***********************************************************
# print() is needed because RStudio's "Source" button does not auto-print.

### One firm, steps 3-5 (straight-line MC) ----
# q*, TR = p* x q*, TVC (area under MC), PS, and the cost of and surplus on
# the single unit in step 5b
print(round(c(q_star = f5b$Q_star, TR = f5b$TR, TVC = f5b$TVC, PS = f5b$PS,
              unit_cost = f5b$unit_cost, unit_surplus = f5b$unit_surplus), 2))

### One firm, step 6 (U-shaped costs) ----
# PS = TR - TVC = profit + FC
print(round(c(q_star = f6b$Q_star, TR = f6b$TR, TVC = f6b$TVC, PS = f6b$PS,
              FC = f6b$FC, profit = f6b$profit, AVC_at_q_star = f6b$AVC_star,
              ATC_at_q_star = f6b$ATC_star,
              lowest_AVC_shutdown_price = f6b$min_avc), 2))

### Demand and equilibrium ----
# P*, Q*, CS, PS, and the unit in the demand figure (its buyer's willingness
# to pay W2P = price paid P* + surplus)
print(round(c(P_star = m_eq$P_star, Q_star = m_eq$Q_star, CS = m_eq$CS,
              PS = m_eq$PS, unit = m_dem$q_unit, W2P = m_dem$W2P,
              price_paid = m_dem$P_star, unit_surplus = m_dem$unit_surplus), 2))

### A price above P* (excess supply) and below P* (shortage) ----
print(round(c(P2 = m_es$P2, Qd = m_es$Qd, Qs = m_es$Qs,
              excess_supply = m_es$excess_supply), 2))
print(round(c(P2 = m_sh$P2, Qd = m_sh$Qd, Qs = m_sh$Qs,
              shortage = m_sh$shortage), 2))

### Per-unit tax figure (to move to Tutorial 3) ----
# Q0 and P0: the same market without the tax
print(round(unlist(tx[c("Q0", "P0", "Qt", "Pb", "Ps", "CS", "PS", "tax_revenue",
                        "DWL")]), 2))
