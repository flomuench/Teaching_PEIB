# ***********************************************************
# Title: SEES0082 Political Economy of International Business, UCL SSEES:
#        course website with interactive diagrams (Teaching_PEIB)
#
# Purpose: Tutorial 3 static figures (300 dpi PNGs) for the Word handouts
#          and the website, plus the numbers for the answer key:
#          government subsidies and learning-by-doing (solar panels)
#       Part 1: Parameters (the model, figure sizes, axes, tick steps)
#       Part 2: Helper function that saves one figure as a PNG
#       Part 3: Figure 1, the solar-panel market without a subsidy
#       Part 4: Figures 2a and 2, the producer subsidy: the shift and the
#               welfare changes
#       Part 5: Figures 3, 4 and 5, learning curves (conceptual)
#       Part 6: Figures 6 and 7, period 2 after learning, without and
#               with the subsidy
#       Part 7: Overview sheet of the answers figures (a working file)
#       Part 8: Answer key numbers (printed in the console)
#
# Authors: Florian Münch
# Requires: Parts 1 and 2 of code/master.R: the path variable o_fig_t3
#     (figures/tutorial3/) and the drawing functions from
#     code/functions_models.R (Part 6 there); the R package png for the
#     overview sheet only (Part 7 is skipped with a message without it)
# Creates: PNGs in figures/tutorial3/ (300 dpi), overwriting the previous
#     versions:
#     tutorial03_fig01_market_noanswers/answers.png               (Part 3)
#     tutorial03_fig02a_subsidy_shift_noanswers/answers.png,
#     tutorial03_fig02_subsidy_welfare_noanswers/answers.png      (Part 4)
#     tutorial03_fig03_learning_curve.png,
#     tutorial03_fig04_learning_spillover.png,
#     tutorial03_fig05_learning_breakeven.png                     (Part 5)
#     tutorial03_fig06_period2_market_noanswers/answers.png,
#     tutorial03_fig07_period2_subsidy_welfare_noanswers/answers.png
#                                                                 (Part 6)
#     tutorial03_figures_overview.png                             (Part 7)
# ***********************************************************

# How to run (explanatory notes):
  # Do not run this script on its own: open Teaching_PEIB.Rproj, open
  # code/master.R and run it (Part 5 switches this script on). master.R sets
  # the folder paths (Part 1) and loads the drawing functions (Part 2).
  # Afterwards commit and push the new PNGs with GitHub Desktop so the
  # website shows them too.
  #
  # Two versions of the market figures, named after the two versions of the
  # handout: "noanswers" (handed out before the tutorial: no numbers in the
  # areas, the subsidised equilibrium E1 drawn as a dot but not labelled)
  # and "answers" (handed out after it: numbers in the areas, E1 labelled,
  # the size of the subsidy wedge). One argument, version = "noanswers" or
  # "answers", switches between them, so both versions always show exactly
  # the same curves. The learning-curve figures have no numbers, so they
  # exist in one version. The website shows the noanswers versions.
  #
  # Size: every figure is 6 x 4.5 inches; in Word set the width to 15 cm
  # with "Lock aspect ratio" ticked.

# Safety check: stop with a clear message if master.R Parts 1-2 have not run
if (!exists("o_fig_t3") || !exists("draw_subsidy")) {
  stop("o_fig_t3 or the drawing functions are missing. Run code/master.R ",
       "(at least Parts 1 and 2) instead of this script on its own.",
       call. = FALSE)
}
# All Tutorial 3 figures go into their own folder, figures/tutorial3/
dir.create(o_fig_t3, recursive = TRUE, showWarnings = FALSE)


# ***********************************************************
# Part 1: Parameters ----
# ***********************************************************
# Edit here so the figures match your handout questions. If you change the
# model values, change the "handout" list of the explorer app in
# tutorials/tutorial03_subsidy.qmd too.

### The model (handout Exercises 1 and 2) ----
# Demand P = a - b*Q; supply (= marginal cost of the industry) P = c + d*Q,
# from ten identical firms with TC_i = FC + 20 q_i + 5 q_i^2, i.e.
# MC_i = 20 + 10 q_i; producer subsidy s per panel.
sub03 <- list(a = 100, b = 1, c = 20, d = 1, s = 20, n = 10, FC = 50)

### Period 2 (Exercise 3): learning lowers the cost intercept to 16 ----
# Same slopes and subsidy; only c changes.
sub03_p2 <- modifyList(sub03, list(c = 16))

### Learning curves (Figures 3 to 5, conceptual: no numbers shown) ----
# c(E) = cbar + (c0 - cbar) * E^(-beta). The values only set the shapes:
# a steep fall, then flattening towards the mature cost cbar.
learn03 <- list(c0 = 20, beta = 1, cbar = 4, beta_slow = 0.3, spill = 0.6,
                E_max = 10, xlim = c(0, 10), ylim = c(0, 25))

### Figure size (inches) and resolution ----
fig_dpi  <- 300
size_one <- c(6, 4.5)

### Axes and numbered ticks (no titles: the handout caption names a figure) ----
# Ticks every 10 on both axes, so that 40, 50, 60 and 70 are all numbered.
ax_market <- list(xlim = c(0, 100), ylim = c(0, 100), ticks = c(10, 10))


# ***********************************************************
# Part 2: Helper function that saves one figure as a PNG ----
# ***********************************************************
# png() opens a file "device", everything plotted goes into the file, and
# dev.off() closes and saves it. on.exit() makes sure the file is closed
# even if a drawing function stops with an error. 'draw' is a function
# that draws the figure; its result (the model's numbers) is returned
# invisibly for the answer key in Part 8.
save_png <- function(name, size, draw) {
  file <- file.path(o_fig_t3, paste0("tutorial03_", name, ".png"))
  png(file, width = size[1], height = size[2], units = "in", res = fig_dpi)
  on.exit(dev.off())
  out <- draw()
  message("Saved ", file)
  invisible(out)
}
versions <- c("noanswers", "answers")

# The arguments every market figure shares (model, axes, ticks, no title)
market_args <- function(p) {
  list(a = p$a, b = p$b, c = p$c, d = p$d, s = p$s, xlim = ax_market$xlim,
       ylim = ax_market$ylim, tick_step = ax_market$ticks, fit_top = TRUE)
}


# ***********************************************************
# Part 3: Figure 1, the solar-panel market without a subsidy ----
# ***********************************************************
# D: P = 100 - Q, S = MC: P = 20 + Q. E0 = (40, 60); CS = PS = 800.
f1 <- list()
for (v in versions) {
  f1[[v]] <- save_png(paste0("fig01_market_", v), size_one, function()
    do.call(draw_subsidy, c(list(view = "market", version = v),
                            market_args(sub03))))
}


# ***********************************************************
# Part 4: Figures 2a and 2, the producer subsidy ----
# ***********************************************************
# Explanatory notes:
  # With the consumer price PC on the vertical axis, the subsidy s = 20
  # moves the supply curve down by 20: S - s is PC = Q. E1 = (50, 50):
  # buyers pay PC = 50, sellers receive PP = 70.
  # Figure 2a: the shift, both prices and the wedge s between them.
  # Figure 2 (Question 2.5): the welfare CHANGES: consumers gain 450,
  #   producers gain 450, and the DWL of 100 completes the rectangle
  #   G = 1,000. (The welfare LEVELS view of draw_subsidy() is an extra
  #   view of the website app only: no PNG.)
f2 <- list()
for (v in versions) {
  f2[[paste0("a_", v)]] <- save_png(paste0("fig02a_subsidy_shift_", v),
    size_one, function() do.call(draw_subsidy,
      c(list(view = "shift", version = v), market_args(sub03))))
  f2[[v]] <- save_png(paste0("fig02_subsidy_welfare_", v), size_one,
    function() do.call(draw_subsidy, c(list(view = "welfare_changes",
                                            version = v), market_args(sub03))))
}


# ***********************************************************
# Part 5: Figures 3, 4 and 5, learning curves (conceptual) ----
# ***********************************************************
# Explanatory notes:
  # Arrow axes without numbers: these figures show shapes, not values.
  # Figure 3: one learning curve c(E), flattening towards the mature cost.
  # Figure 4: internal learning versus spillovers (own + industry
  #           experience): the spillover curve is lower at every level of
  #           the firm's own experience.
  # Figure 5: break-even: the fast learner's cost falls below the price P
  #           (loss first, gain afterwards); the slow learner's does not
  #           within the horizon shown.
learn_args <- function(view) {
  c(list(view = view, fit_top = TRUE), learn03)
}
f3 <- save_png("fig03_learning_curve", size_one, function()
  do.call(draw_learning, learn_args("curve")))
f4 <- save_png("fig04_learning_spillover", size_one, function()
  do.call(draw_learning, learn_args("spillover")))
f5 <- save_png("fig05_learning_breakeven", size_one, function()
  do.call(draw_learning, learn_args("breakeven")))


# ***********************************************************
# Part 6: Figures 6 and 7, period 2 after learning ----
# ***********************************************************
# Explanatory notes:
  # Learning has lowered the cost intercept from 20 to 16 (supply
  # P = 16 + Q).
  # Figure 6 (Walkthroughs 3 to 5): period 2 WITHOUT the subsidy (it was
  #   temporary): E2 = (42, 58), CS = PS = 882, G = 0, net surplus 1,764.
  #   The equilibrium is named E2 (e0_name) to set it apart from E0 of
  #   period 1; Figure 7 uses the same name for the same point.
  # Figure 7 (Question 3.6d): the subsidy KEPT in period 2: E1 = (52, 48)
  #   with PP = 68, CS = PS = 1,352, G = 1,040, consumers and producers
  #   each gain 470 relative to E2 and the DWL of 100 returns.
f6 <- list(); f7 <- list()
for (v in versions) {
  f6[[v]] <- save_png(paste0("fig06_period2_market_", v), size_one,
    function() do.call(draw_subsidy, c(list(view = "market", version = v,
                                            e0_name = "E2"),
                                       market_args(sub03_p2))))
  f7[[v]] <- save_png(paste0("fig07_period2_subsidy_welfare_", v), size_one,
    function() do.call(draw_subsidy, c(list(view = "welfare_changes",
                                            version = v, e0_name = "E2"),
                                       market_args(sub03_p2))))
}


# ***********************************************************
# Part 7: Overview sheet of the answers figures (a working file) ----
# ***********************************************************
# Explanatory notes:
  # One PNG with every answers figure as a small tile and a bold caption,
  # to check the whole series at a glance (not linked on the website). It
  # reads the PNGs back in with the png package (readPNG), so it is skipped
  # with a message if that package is not installed. Each image is shrunk
  # (every 4th pixel) before it is placed, to keep the memory use small.
overview <- list(
  c("fig01_market_answers",          "Fig 1 - the market, no subsidy"),
  c("fig02a_subsidy_shift_answers",  "Fig 2a - the subsidy shifts supply"),
  c("fig02_subsidy_welfare_answers", "Fig 2 - who gains, who loses"),
  c("fig03_learning_curve",          "Fig 3 - a learning curve"),
  c("fig04_learning_spillover",      "Fig 4 - learning spillovers"),
  c("fig05_learning_breakeven",      "Fig 5 - learning and break-even"),
  c("fig06_period2_market_answers",  "Fig 6 - period 2, no subsidy"),
  c("fig07_period2_subsidy_welfare_answers",
    "Fig 7 - period 2, subsidy kept"))
if (requireNamespace("png", quietly = TRUE)) {
  file_ov <- file.path(o_fig_t3, "tutorial03_figures_overview.png")
  n_col <- 2; n_row <- ceiling(length(overview) / n_col)
  tile_w <- 6; tile_h <- 4.5 + 0.45            # inches: image + caption
  png(file_ov, width = n_col * tile_w, height = n_row * tile_h,
      units = "in", res = 100)
  op_ov <- par(mfrow = c(n_row, n_col), mar = c(0.3, 0.3, 2.2, 0.3))
  for (tile in overview) {
    img <- png::readPNG(file.path(o_fig_t3, paste0("tutorial03_", tile[1],
                                                   ".png")))
    img <- img[seq(1, dim(img)[1], by = 4), seq(1, dim(img)[2], by = 4), ,
               drop = FALSE]
    # Fit the image into the tile without stretching it
    asp <- dim(img)[1] / dim(img)[2]                # height / width
    plot(NA, xlim = c(0, 1), ylim = c(0, 1), axes = FALSE, ann = FALSE,
         xaxs = "i", yaxs = "i")
    pin <- par("pin"); box_asp <- pin[2] / pin[1]
    w <- if (asp > box_asp) box_asp / asp else 1
    h <- if (asp > box_asp) 1 else asp / box_asp
    rasterImage(img, (1 - w) / 2, (1 - h) / 2, (1 + w) / 2, (1 + h) / 2,
                interpolate = TRUE)
    rect(0, 0, 1, 1, border = "grey80")
    title(main = tile[2], font.main = 2, cex.main = 1.5, line = 0.6)
  }
  par(op_ov)
  dev.off()
  message("Saved ", file_ov)
} else {
  message("Part 7 skipped: the overview sheet needs the R package 'png' ",
          "(install.packages(\"png\")).")
}


# ***********************************************************
# Part 8: Answer key numbers (printed in the console) ----
# ***********************************************************
# print() is needed because RStudio's "Source" button does not auto-print.
# All numbers come from subsidy_outcomes(), the same function the figures
# and the website app use.
ak <- do.call(subsidy_outcomes, sub03)

### Exercise 1: no subsidy (Figure 1) ----
print(round(c(Q0 = ak$Q0, P0 = ak$P0, CS0 = ak$CS0, PS0 = ak$PS0,
              TS0 = ak$NS0, q0_firm = ak$q0_firm,
              PS0_firm = ak$PS0_firm, profit0_firm = ak$profit0_firm), 2))

### Exercise 2: the producer subsidy s = 20 (Figures 2a and 2) ----
print(round(c(Q1 = ak$Q1, PC = ak$PC, PP = ak$PP, dPC = ak$dPC,
              dPP = ak$dPP, share_cons = ak$share_cons,
              share_prod = ak$share_prod, q1_firm = ak$q1_firm,
              PS1_firm = ak$PS1_firm, profit1_firm = ak$profit1_firm), 2))

### Exercise 2: welfare ledger (levels, changes, net surplus) ----
# Net surplus NS = CS + PS - G (taxpayers pay the subsidy bill G)
print(round(rbind(
  no_subsidy = c(CS = ak$CS0, PS = ak$PS0, G = 0, NS = ak$NS0, DWL = 0),
  subsidy    = c(CS = ak$CS1, PS = ak$PS1, G = ak$G, NS = ak$NS1,
                 DWL = ak$DWL),
  change     = c(CS = ak$dCS, PS = ak$dPS, G = ak$G, NS = ak$dNS,
                 DWL = ak$DWL)), 2))

### The slider table: who gains depends on the slopes (a, c, s fixed) ----
# (b, d) = (1, 1), (4, 1), (1, 4), (3, 2): CS1 and PS1 with their changes
slopes <- list(c(1, 1), c(4, 1), c(1, 4), c(3, 2))
tab <- t(sapply(slopes, function(bd) {
  o <- subsidy_outcomes(a = sub03$a, b = bd[1], c = sub03$c, d = bd[2],
                        s = sub03$s)
  c(b = bd[1], d = bd[2], Q1 = o$Q1, PC = o$PC, PP = o$PP, CS1 = o$CS1,
    dCS = o$dCS, PS1 = o$PS1, dPS = o$dPS, G = o$G, DWL = o$DWL,
    share_cons = o$share_cons)
}))
print(round(tab, 2))

### Exercise 3: period 2 after learning (c = 16) ----
ak2 <- do.call(subsidy_outcomes, sub03_p2)
# Walkthroughs 3 to 5, Figure 6: the subsidy withdrawn (temporary subsidy)
print(round(c(Q2 = ak2$Q0, P2 = ak2$P0, CS2 = ak2$CS0, PS2 = ak2$PS0,
              G = 0, NS2 = ak2$NS0, q2_firm = ak2$q0_firm,
              profit2_firm = ak2$profit0_firm), 2))
# Question 3.6d, Figure 7: the subsidy kept in period 2 (changes are
# relative to period 2 without the subsidy)
print(round(c(Q1 = ak2$Q1, PC = ak2$PC, PP = ak2$PP, CS1 = ak2$CS1,
              PS1 = ak2$PS1, G = ak2$G, NS1 = ak2$NS1, DWL = ak2$DWL,
              dCS = ak2$dCS, dPS = ak2$dPS, dNS = ak2$dNS), 2))
