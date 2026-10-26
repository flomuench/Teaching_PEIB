# ***********************************************************
# Title: SEES0082 Political Economy of International Business, UCL SSEES:
#        course website with interactive diagrams (Teaching_PEIB)
#
# Purpose: Tutorial 4 static figures (300 dpi PNGs) for the Word handouts
#          and the website, plus the numbers for the answer key: from a
#          closed to an open market - trade, a Home production subsidy,
#          international learning-by-doing and welfare across borders
#       Part 1: Parameters (the model, figure sizes, axes, tick steps)
#       Part 2: Helper function that saves one figure as a PNG
#       Part 3: Figure 1, free trade: Home | World | Foreign
#       Part 4: Figure 2, the Home production subsidy: Home | World | Foreign
#       Part 5: Figure 3, who gains and who loses (welfare bars)
#       Part 6: Figure 4, Home's learning and the spillover to Foreign
#       Part 7: Figure 5, the world market in period 1 and period 2
#       Part 8: Figures 6 and 7, two-period welfare and the environment
#       Part 9: Overview sheet of the answers figures (a working file)
#       Part 10: Answer key numbers (printed in the console)
#
# Authors: Florian Münch
# Requires: Parts 1 and 2 of code/master.R: the path variable o_fig_t4
#     (figures/tutorial4/) and the drawing functions from
#     code/functions_models.R (Part 7 there); the R package png for the
#     overview sheet only (Part 9 is skipped with a message without it)
# Creates: PNGs in figures/tutorial4/ (300 dpi), overwriting the previous
#     versions:
#     tutorial04_fig01_free_trade_noanswers/answers.png          (Part 3)
#     tutorial04_fig02_subsidy_noanswers/answers.png             (Part 4)
#     tutorial04_fig03_welfare_bars_answers.png                  (Part 5)
#     tutorial04_fig04_learning_intercepts.png                   (Part 6)
#     tutorial04_fig05_period2_world_noanswers/answers.png       (Part 7)
#     tutorial04_fig06_two_period_bars_answers.png,
#     tutorial04_fig07_env_waterfall_answers.png                 (Part 8)
#     tutorial04_figures_overview.png                            (Part 9)
# ***********************************************************

# How to run (explanatory notes):
  # Do not run this script on its own: open Teaching_PEIB.Rproj, open
  # code/master.R and run it (Part 6 switches this script on). master.R sets
  # the folder paths (Part 1) and loads the drawing functions (Part 2).
  # Afterwards commit and push the new PNGs with GitHub Desktop so the
  # website shows them too.
  #
  # Two versions of the market figures, named after the two versions of the
  # handout: "noanswers" (handed out before the tutorial: the curves only)
  # and "answers" (after it: world price, quantities, trade, equilibria,
  # the world loss). One argument, version = "noanswers" or "answers",
  # switches between them, so both versions show exactly the same curves.
  # The bar charts (Figures 3, 6, 7) are answers by nature and exist in the
  # answers version only; Figure 4 shows only numbers given in the handout
  # and exists in one version.
  #
  # Sizes: the multi-panel figures (1, 2, 5 and 6) are 9 x 4 inches (in Word
  # set the width to the full text width, about 16 cm, "Lock aspect ratio"
  # ticked); Figures 3, 4 and 7 are 6 x 4.5 inches (width 15 cm in Word).

# Safety check: stop with a clear message if master.R Parts 1-2 have not run
if (!exists("o_fig_t4") || !exists("draw_open_market")) {
  stop("o_fig_t4 or the drawing functions are missing. Run code/master.R ",
       "(at least Parts 1 and 2) instead of this script on its own.",
       call. = FALSE)
}
# All Tutorial 4 figures go into their own folder, figures/tutorial4/
dir.create(o_fig_t4, recursive = TRUE, showWarnings = FALSE)


# ***********************************************************
# Part 1: Parameters ----
# ***********************************************************
# Edit here so the figures match your handout questions. If you change the
# model values, change the "handout" list of the explorer app in
# tutorials/tutorial04_open_economy.qmd too.

### The model (handout Exercises 1 and 2) ----
# Ten identical firms per country, TC = F + c q + 5 q^2 (c = 20 in Home,
# 40 in Foreign), so industry supply Q_H^S = P - 20 and Q_F^S = P - 40;
# demand Q^D = 100 - P in each country. Home subsidy s = 20 per panel made
# in Home. Period 2: Home's cost intercept falls by 4 (20 -> 16), a share
# theta = 0.5 of that reaches Foreign (40 -> 38). Environment: 6 per new
# installation for the installing country (air pollution), 12 per new
# installation for the world (climate), split 50/50.
open04 <- list(a = 100, cH = 20, cF = 40, s = 20, n = 10)
learn04 <- list(theta = 0.5, delta = 1, bAP = 6, bGHG = 12)

### Figure sizes (inches) and resolution ----
fig_dpi    <- 300
size_one   <- c(6, 4.5)    # one panel (Figures 3, 4, 7)
size_three <- c(9, 4)      # multi-panel (Figures 1, 2, 5, 6)

### Axes and numbered ticks (no titles: the handout caption names a figure) ----
# Country panels Q 0-100, the World panel Q 0-120 (world demand is twice
# a country's), price 0-100 in every panel. Ticks every 10 (World: 20).
ax04 <- list(xlim_c = c(0, 100), xlim_w = c(0, 120), ylim = c(0, 100),
             ticks = list(c(10, 10), c(20, 10), c(10, 10)))


# ***********************************************************
# Part 2: Helper function that saves one figure as a PNG ----
# ***********************************************************
# png() opens a file "device", everything plotted goes into the file, and
# dev.off() closes and saves it. on.exit() makes sure the file is closed
# even if a drawing function stops with an error. 'draw' is a function
# that draws the figure; its result (the model's numbers) is returned
# invisibly for the answer key in Part 10.
save_png <- function(name, size, draw) {
  file <- file.path(o_fig_t4, paste0("tutorial04_", name, ".png"))
  png(file, width = size[1], height = size[2], units = "in", res = fig_dpi)
  on.exit(dev.off())
  out <- draw()
  message("Saved ", file)
  invisible(out)
}
versions <- c("noanswers", "answers")

# The arguments every three-panel market figure shares
market_args04 <- function(state, v) {
  c(list(state = state, version = v), open04,
    list(xlim_c = ax04$xlim_c, xlim_w = ax04$xlim_w, ylim = ax04$ylim,
         tick_step = ax04$ticks, fit_top = TRUE))
}


# ***********************************************************
# Part 3: Figure 1, free trade: Home | World | Foreign ----
# ***********************************************************
# Explanatory notes:
  # Home: D P = 100 - Q, S = MC P = 20 + Q; Foreign: D P = 100 - Q,
  # S = MC P = 40 + Q; World: D P = 100 - Q/2, S kinked at Q = 20
  # (P = 20 + Q below, P = 30 + Q/2 above: only Home produces below 40).
  # Answers: P_W = 65; Home makes 45 and buys 35 (exports 10), Foreign
  # makes 25 and buys 35 (imports 10); world E0 = (70, 65).
f1 <- list()
for (v in versions) {
  f1[[v]] <- save_png(paste0("fig01_free_trade_", v), size_three,
    function() do.call(draw_open_market, market_args04("free", v)))
}


# ***********************************************************
# Part 4: Figure 2, the Home production subsidy ----
# ***********************************************************
# Explanatory notes:
  # Home's supply in world-price terms moves down by s = 20 (S - s,
  # P_W = Q); world supply becomes 2P - 40 above P = 40 (S with s).
  # Answers: P_W = 60, Home producers receive P_H,P = 80; Home 60 / 40
  # (exports 20), Foreign 20 / 40 (imports 20); world E0 = (70, 65) ->
  # E1 = (80, 60); the world loss of 150 is the red triangle in the Home
  # panel: (45, 65), (60, 80), (60, 60) = 1/2 x 20 x 15, with "150" inside.
  # Its lower edge is the demand Home's firms face on the world market
  # (world demand minus Foreign supply, P = 80 - Q/3), drawn as a thin
  # dashed line "World demand for Home's panels" (answers version only).
f2 <- list()
for (v in versions) {
  f2[[v]] <- save_png(paste0("fig02_subsidy_", v), size_three,
    function() do.call(draw_open_market, market_args04("subsidy", v)))
}


# ***********************************************************
# Part 5: Figure 3, who gains and who loses (welfare bars) ----
# ***********************************************************
# Five changes (subsidy versus free trade): Home consumers +187.5, Home
# producers +787.5, Home government -1,200, Foreign consumers +187.5,
# Foreign producers -112.5; the totals Home -225, Foreign +75 and World
# -150 are printed beside the bars (sums, not extra bars).
f3 <- save_png("fig03_welfare_bars_answers", size_one, function()
  do.call(draw_open_bars, c(list(type = "ex1", version = "answers",
                                 fit_top = TRUE), open04, learn04)))


# ***********************************************************
# Part 6: Figure 4, Home's learning and the spillover to Foreign ----
# ***********************************************************
# c_H(E) = 20 E^(-0.776) through (1, 20) and (4/3, 16); Foreign's
# intercept 40 - theta (20 - c_H(E)) through (1, 40) and (4/3, 38) for
# theta = 0.5. Only numbers that the handout gives.
f4 <- save_png("fig04_learning_intercepts", size_one, function()
  do.call(draw_open_learning, c(list(theta = learn04$theta, fit_top = TRUE),
                                open04)))


# ***********************************************************
# Part 7: Figure 5, the world market in period 1 and period 2 ----
# ***********************************************************
# Left: period 1, the policy wedge (world supply 2P - 60 -> 2P - 40,
# P 65 -> 60, Home producers receive 80). Right: period 2, lower true
# costs after learning (2P - 60 -> 2P - 54, P 65 -> 63.5 for theta = 0.5).
f5 <- list()
for (v in versions) {
  f5[[v]] <- save_png(paste0("fig05_period2_world_", v), size_three,
    function() do.call(draw_open_period2,
      c(list(version = v, theta = learn04$theta, xlim = ax04$xlim_w,
             ylim = ax04$ylim, tick_step = c(20, 10), fit_top = TRUE),
        open04)))
}


# ***********************************************************
# Part 8: Figures 6 and 7, two-period welfare and the environment ----
# ***********************************************************
# Figure 6: Home -225 / +169.25 / -55.75, Foreign +75 / +66.25 / +141.25,
#   World -150 / +235.5 / +85.5 (period 1 / period 2 / total, delta = 1).
# Figure 7: world waterfall -150, +235.5, +78 (air pollution), +156
#   (climate), total +319.5.
f6 <- save_png("fig06_two_period_bars_answers", size_three, function()
  do.call(draw_open_bars, c(list(type = "two_period", version = "answers"),
                            open04, learn04)))
f7 <- save_png("fig07_env_waterfall_answers", size_one, function()
  do.call(draw_open_bars, c(list(type = "env", version = "answers",
                                 fit_top = TRUE), open04, learn04)))


# ***********************************************************
# Part 9: Overview sheet of the answers figures (a working file) ----
# ***********************************************************
# Explanatory notes:
  # One PNG with every answers figure as a tile and a bold caption, to
  # check the whole series at a glance (not linked on the website). It
  # reads the PNGs back in with the png package (readPNG), so it is skipped
  # with a message if that package is not installed. Each image is shrunk
  # (every 4th pixel) before it is placed, to keep the memory use small.
overview <- list(
  c("fig01_free_trade_answers",        "Fig 1 - free trade"),
  c("fig02_subsidy_answers",           "Fig 2 - the Home subsidy"),
  c("fig03_welfare_bars_answers",      "Fig 3 - who gains, who loses"),
  c("fig04_learning_intercepts",       "Fig 4 - learning and spillover"),
  c("fig05_period2_world_answers",     "Fig 5 - period 1 vs period 2"),
  c("fig06_two_period_bars_answers",   "Fig 6 - two-period welfare"),
  c("fig07_env_waterfall_answers",     "Fig 7 - with the environment"))
# The sheet is drawn inside a small function, so that on.exit() closes the
# PNG file even if reading one of the tiles fails (as in save_png(), Part 2)
make_overview04 <- function(file_ov) {
  n_col <- 2; n_row <- ceiling(length(overview) / n_col)
  tile_w <- 9; tile_h <- 4.5 + 0.45            # inches: image + caption
  png(file_ov, width = n_col * tile_w, height = n_row * tile_h,
      units = "in", res = 80)
  on.exit(dev.off())
  par(mfrow = c(n_row, n_col), mar = c(0.3, 0.3, 2.2, 0.3))
  for (tile in overview) {
    img <- png::readPNG(file.path(o_fig_t4, paste0("tutorial04_", tile[1],
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
  message("Saved ", file_ov)
}
if (requireNamespace("png", quietly = TRUE)) {
  make_overview04(file.path(o_fig_t4, "tutorial04_figures_overview.png"))
} else {
  message("Part 9 skipped: the overview sheet needs the R package 'png' ",
          "(install.packages(\"png\")).")
}


# ***********************************************************
# Part 10: Answer key numbers (printed in the console) ----
# ***********************************************************
# print() is needed because RStudio's "Source" button does not auto-print.
# All numbers come from open_outcomes() and open_two_period(), the same
# functions the figures and the website app use.
ak0 <- do.call(open_outcomes, modifyList(open04, list(s = 0)))
ak1 <- do.call(open_outcomes, open04)
show_vars <- c("P_W", "P_HP", "Q_HS", "Q_HD", "Q_FS", "Q_FD", "Q_W", "X",
               "CS_H", "PS_H", "G_H", "W_H", "CS_F", "PS_F", "W_F", "W_W")

### Exercise 1: free trade, the subsidy and the changes (Tables 1 to 3) ----
print(round(rbind(free_trade = unlist(ak0[show_vars]),
                  subsidy    = unlist(ak1[show_vars]),
                  change     = unlist(ak1[show_vars]) -
                               unlist(ak0[show_vars])), 3))
# Autarky prices (Q1.1c, Q1.4d) and the world loss as a triangle in the
# Home panel: 1/2 x s x (Home's extra output) = 1/2 x 20 x 15 = 150
print(c(P_aut_H = ak0$P_aut_H, P_aut_F = ak0$P_aut_F,
        world_loss = ak0$W_W - ak1$W_W,
        triangle = 0.5 * (ak1$P_HP - ak1$P_W) * (ak1$Q_HS - ak0$Q_HS)))

### Exercise 2: period 2 and two periods, theta = 0.5 (Tables 4 to 7) ----
tp04 <- do.call(open_two_period, c(list(s = open04$s), learn04,
                                   open04[c("a", "cH", "cF", "n")]))
print(round(c(beta = tp04$beta, E = tp04$E, cH2 = tp04$cH2,
              cF2 = tp04$cF2), 4))
# Period 2: Path A (no subsidy in period 1, so no learning) versus Path B
# (learning after the period-1 subsidy), and the changes B - A
print(round(rbind(path_A = unlist(tp04$A2[show_vars]),
                  path_B = unlist(tp04$B2[show_vars]),
                  change = unlist(tp04$B2[show_vars]) -
                           unlist(tp04$A2[show_vars])), 3))
# Rows: p1 = period 1 (subsidy), p2 = period 2 (learning, x delta),
# total, env_ap (air pollution), env_ghg (climate), env, total_env
print(round(tp04$table, 3))
# Installations (new panels bought) per country: period 1 and period 2
print(rbind(period1 = tp04$dQD1, period2 = tp04$dQD2))

### Slider table (handout Question 2.5): theta = 0, 0.2, 0.5, 0.8, 1 ----
slider04 <- t(sapply(c(0, 0.2, 0.5, 0.8, 1), function(th) {
  tp <- open_two_period(s = open04$s, theta = th, delta = 1)
  c(theta = th, cF2 = tp$cF2, P2 = tp$B2$P_W, Q_HS = tp$B2$Q_HS,
    Q_FS = tp$B2$Q_FS, Q_D_each = tp$B2$Q_HD,
    p2_Home = tp$table[["p2", "Home"]],
    p2_Foreign = tp$table[["p2", "Foreign"]],
    p2_World = tp$table[["p2", "World"]],
    tot_Home = tp$table[["total", "Home"]],
    tot_Foreign = tp$table[["total", "Foreign"]],
    tot_World = tp$table[["total", "World"]])
}))
print(round(slider04, 3))
