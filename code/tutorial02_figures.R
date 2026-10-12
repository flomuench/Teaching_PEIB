# ***********************************************************
# Title: SEES0082 Political Economy of International Business, UCL SSEES:
#        course website with interactive diagrams (Teaching_PEIB)
#
# Purpose: Tutorial 2 static figures (300 dpi PNGs) for the Word handouts
#          and the website, plus the numbers for the answer key:
#          the nickel-battery value chain (linked markets, elasticities,
#          cost pass-through, welfare)
#       Part 1: Parameters (the model, figure sizes, axes, tick steps)
#       Part 2: Helper function that saves one figure as a PNG
#       Part 3: Figure 1, the value chain schematic
#       Part 4: Figure 2, one nickel producer
#       Part 5: Figures 3 and 3b, from the firm to the industry supply
#       Part 6: Figures 4a and 4b, the nickel market before and after
#       Part 7: Figure 5, slope versus elasticity
#       Part 8: Figures 6, 7 and 7b, the two linked markets and welfare
#       Part 9: Overview sheet of all tutor figures (a working file)
#       Part 10: Answer key numbers (printed in the console)
#
# Authors: Florian Münch
# Requires: Parts 1 and 2 of code/master.R: the path variable o_fig_t2
#     (figures/tutorial2/) and the drawing functions from
#     code/functions_models.R (Part 5 there); the R package png for the
#     overview sheet only (Part 9 is skipped with a message without it)
# Creates: PNGs in figures/tutorial2/ (300 dpi), overwriting the previous
#     versions:
#     tutorial02_fig01_value_chain.png                       (Part 3)
#     tutorial02_fig02_firm_student/tutor.png                (Part 4)
#     tutorial02_fig03_firm_to_industry.png,
#     tutorial02_fig03b_innovation_supply.png                (Part 5)
#     tutorial02_fig04a_nickel_before_student/tutor.png,
#     tutorial02_fig04b_nickel_after_student/tutor.png       (Part 6)
#     tutorial02_fig05_elasticity.png                        (Part 7)
#     tutorial02_fig06_linked_markets_student/tutor.png,
#     tutorial02_fig07_welfare_E0_student/tutor.png,
#     tutorial02_fig07b_welfare_E1_student/tutor.png         (Part 8)
#     tutorial02_figures_overview.png                        (Part 9)
# ***********************************************************

# How to run (explanatory notes):
  # Do not run this script on its own: open Teaching_PEIB.Rproj, open
  # code/master.R and run it (Part 4 switches this script on). master.R sets
  # the folder paths (Part 1) and loads the drawing functions (Part 2).
  # Afterwards commit and push the new PNGs with GitHub Desktop so the
  # website shows them too.
  #
  # Two versions of most figures: "student" (the handout students get: no
  # numbers in the areas, the new equilibrium E1 not labelled, because
  # students find these themselves) and "tutor" (the model-answer handout
  # and the website: numbers in the areas, E1 labelled, arrows with the
  # size of each change). One argument of the drawing functions, version =
  # "student" or "tutor", switches between them, so both versions always
  # show exactly the same curves.
  #
  # Sizes: one-panel figures 6 x 4.5 inches, two-panel figures (Figures 3,
  # 3b, 6, 7, 7b) 8 x 4.5 inches, the schematic (Figure 1) 8 x 3 inches; in
  # Word set the width to 15 cm (one panel) or 16 cm (two panels) with
  # "Lock aspect ratio" ticked.

# Safety check: stop with a clear message if master.R Parts 1-2 have not run
if (!exists("o_fig_t2") || !exists("draw_chain_linked")) {
  stop("o_fig_t2 or the drawing functions are missing. Run code/master.R ",
       "(at least Parts 1 and 2) instead of this script on its own.",
       call. = FALSE)
}
# All Tutorial 2 figures go into their own folder, figures/tutorial2/
dir.create(o_fig_t2, recursive = TRUE, showWarnings = FALSE)


# ***********************************************************
# Part 1: Parameters ----
# ***********************************************************
# Edit here so the figures match your handout questions.

### The model (handout Section III) ----
# Battery demand P_B = A - b*Q; other marginal cost of batteries c + g*Q;
# nickel supply P_N = u + s*Q; the innovation lowers nickel marginal cost
# by k. Ten firms in each industry, fixed cost FC per firm.
# (The nickel demand curve of Exercise 2, P_N = 170 - 2Q, follows from these
# numbers: 170 = A - c and 2 = b + g.)
chain02 <- list(A = 220, b = 1, c = 50, g = 1, u = 50, s = 1, k = 30,
                n = 10, FC = 20)

### One nickel firm (Figure 2) ----
# MC = c0 + d*q = 50 + 10q (TC = 20 + 50q + 5q^2), market price P_N = 90
firm02 <- list(c0 = 50, d = 10, P = 90)

### Figure sizes (inches) and resolution ----
fig_dpi <- 300
size_one    <- c(6, 4.5)     # one panel
size_two    <- c(8, 4.5)     # two panels side by side
size_scheme <- c(8, 3)       # Figure 1, the schematic

### Axes and numbered ticks (no titles: the handout caption names a figure) ----
# A tick step of c(x, y) puts a numbered tick at every multiple of x on the
# quantity axis and of y on the price axis. Two-panel figures take a list,
# one c(x, y) per panel (left, right).
ax_firm     <- list(xlim = c(0, 8), ylim = c(0, 120), ticks = c(1, 10))
# Figures 3 and 3b go up to 140 (not 120) so that the guide at P = 120
# (q = 7, Q = 70) lies inside the box rather than on its top edge.
ax_supply   <- list(xlim_firm = c(0, 8), xlim_industry = c(0, 80),
                    ylim = c(0, 140), ticks = list(c(1, 10), c(10, 10)))
# Figure 4: ticks every 10 on the price axis, so that the prices 90 and 70
# and the intercepts 170, 50 and 20 are all numbered ticks.
ax_nickel   <- list(xlim = c(0, 90), ylim = c(0, 180), ticks = c(10, 10))
ax_linked   <- list(xlim = c(0, 90), ylim_N = c(0, 180), ylim_B = c(0, 240),
                    # nickel panel: prices every 10 (so 90, 70 and the
                    # intercepts 170 and 50 are numbered); batteries every 20
                    ticks = list(c(10, 10), c(10, 20)))


# ***********************************************************
# Part 2: Helper function that saves one figure as a PNG ----
# ***********************************************************
# png() opens a file "device", everything plotted goes into the file, and
# dev.off() closes and saves it. on.exit() makes sure the file is closed
# even if a drawing function stops with an error. 'draw' is a function
# that draws the figure; its result (the model's numbers) is returned
# invisibly for the answer key in Part 10.
save_png <- function(name, size, draw) {
  file <- file.path(o_fig_t2, paste0("tutorial02_", name, ".png"))
  png(file, width = size[1], height = size[2], units = "in", res = fig_dpi)
  on.exit(dev.off())
  out <- draw()
  message("Saved ", file)
  invisible(out)
}
versions <- c("student", "tutor")


# ***********************************************************
# Part 3: Figure 1, the value chain schematic ----
# ***********************************************************
# Explanatory notes:
  # Three boxes from upstream to downstream, with the HS codes used for
  # trade data (HS = Harmonised System product codes). The arrows carry the
  # goods and their prices. A dashed frame marks the part of the chain the
  # exercises model; the electric-vehicle box is grey: context only.
  # Drawn in base R (no ggplot2): plot() on an empty 0-100 x 0-40 canvas,
  # then rect(), arrows() and text().
draw_value_chain <- function() {
  op <- par(mar = c(0.2, 0.2, 0.2, 0.2)); on.exit(par(op))
  plot(NA, xlim = c(0, 100), ylim = c(0, 40), axes = FALSE, ann = FALSE,
       xaxs = "i", yaxs = "i")
  # Box centres, width and height (the gap between boxes 2 and 3 is wider,
  # so that the dashed frame does not cut the label of the second arrow)
  bx <- c(14, 47, 85); bw <- 23; bh <- 14; by <- 22
  fills  <- c(adjustcolor(peib_cols["supply"], 0.15),
              adjustcolor(peib_cols["demand"], 0.15), "grey92")
  border <- c(peib_cols["supply"], peib_cols["demand"], "grey60")
  labs <- c("Nickel mining\nand refining\n(HS 260400, 750210)",
            "Battery cells\n(HS 850760)",
            "Electric vehicles\n(HS 870380)")
  # Dashed frame around the two modelled boxes, with its label on top
  rect(bx[1] - bw / 2 - 1.5, by - bh / 2 - 3, bx[2] + bw / 2 + 1.5,
       by + bh / 2 + 5.5, lty = 2, lwd = 1.4, border = "grey30")
  text(mean(bx[1:2]), by + bh / 2 + 3.2, "modelled in Exercises 1-3",
       cex = 0.85, font = 3, col = "grey20")
  for (i in 1:3) {
    rect(bx[i] - bw / 2, by - bh / 2, bx[i] + bw / 2, by + bh / 2,
         col = fills[i], border = border[i], lwd = 1.8)
    text(bx[i], by, labs[i], cex = 0.9, font = if (i < 3) 2 else 1,
         col = if (i < 3) "black" else "grey45")
  }
  text(bx[3], by + bh / 2 + 2, "context only", cex = 0.8, font = 3,
       col = "grey45")
  # Arrows between the boxes, labelled with the good and its price
  arr <- c("nickel,\nprice P_N", "batteries,\nprice P_B")
  for (i in 1:2) {
    x0 <- bx[i] + bw / 2 + 0.6; x1 <- bx[i + 1] - bw / 2 - 0.6
    arrows(x0, by, x1, by, length = 0.1, lwd = 2, col = "grey15")
    text((x0 + x1) / 2, by + 1.2, arr[i], cex = 0.75, adj = c(0.5, 0))
  }
  # Bottom row: the stage of each box in the chain
  text(bx, 5, c("upstream", "midstream", "downstream"), cex = 0.9,
       font = 3, col = c("grey20", "grey20", "grey45"))
  invisible(NULL)
}
f1 <- save_png("fig01_value_chain", size_scheme, draw_value_chain)


# ***********************************************************
# Part 4: Figure 2, one nickel producer ----
# ***********************************************************
# MC = 50 + 10q is the firm's supply curve; at P_N = 90 the firm makes
# q* = 4 (P_N = MC). TVC = area under MC from 0 to 4 (280); PS = area
# between the price line and MC (80). Tutor: numbers in the areas and
# q* = 4; student: names only.
f2 <- list()
for (v in versions) {
  f2[[v]] <- save_png(paste0("fig02_firm_", v), size_one, function()
    draw_chain_firm(P = firm02$P, c0 = firm02$c0, d = firm02$d,
                    FC = chain02$FC, xlim = ax_firm$xlim, ylim = ax_firm$ylim,
                    tick_step = ax_firm$ticks, fit_top = TRUE, version = v))
}


# ***********************************************************
# Part 5: Figures 3 and 3b, from the firm to the industry supply ----
# ***********************************************************
# Explanatory notes:
  # Figure 3: left one firm, right the industry of 10 firms, with the same
  # price axis. At each price the industry supplies 10 times what one firm
  # supplies (horizontal summation): P = 90 gives q = 4 and Q = 40, P = 120
  # gives q = 7 and Q = 70. The industry curve is 10 times flatter.
  # Figure 3b: the innovation lowers marginal cost by 30: both curves move
  # DOWN by 30 (vertical arrows) and, at P = 90, RIGHT by 3 (firm) and 30
  # (industry) units (horizontal arrows). No demand curve yet.
  # One version only (the numbers are part of Worked examples 1 and 2), so
  # the tutor version is used for both handouts.
supply_args <- list(c0 = firm02$c0, d = firm02$d, n_firms = chain02$n,
                    k = chain02$k, prices = c(90, 120),
                    xlim_firm = ax_supply$xlim_firm,
                    xlim_industry = ax_supply$xlim_industry,
                    ylim = ax_supply$ylim, tick_step = ax_supply$ticks,
                    fit_top = TRUE, version = "tutor")
f3 <- save_png("fig03_firm_to_industry", size_two, function()
  do.call(draw_chain_supply, c(list(what = "firm_industry"), supply_args)))
f3b <- save_png("fig03b_innovation_supply", size_two, function()
  do.call(draw_chain_supply, c(list(what = "innovation"), supply_args)))


# ***********************************************************
# Part 6: Figures 4a and 4b, the nickel market before and after ----
# ***********************************************************
# Demand P_N = 170 - 2Q, supply S0: 50 + Q and S1: 20 + Q (dashed).
# 4a shades CS_N and PS_N at E0 = (40, 90), 4b at E1 = (50, 70).
# Student: S1 drawn, E1 not labelled, no numbers; tutor: E1 labelled,
# numbers in the areas, arrows "-30 (cost)" and "-20 (price)".
# (b = 2 and s = 1 are the slopes of the drawn nickel demand and supply
# curves; nickel_market_outcomes() places the curves through E0.)
nickel_args <- list(b = chain02$b + chain02$g, s = chain02$s, k = chain02$k,
                    E0 = c(40, 90), xlim = ax_nickel$xlim,
                    ylim = ax_nickel$ylim, tick_step = ax_nickel$ticks,
                    fit_top = TRUE)
f4 <- list()
for (v in versions) {
  f4[[paste0("a_", v)]] <- save_png(paste0("fig04a_nickel_before_", v),
    size_one, function() do.call(draw_chain_nickel,
      c(list(panel = "before", version = v), nickel_args)))
  f4[[paste0("b_", v)]] <- save_png(paste0("fig04b_nickel_after_", v),
    size_one, function() do.call(draw_chain_nickel,
      c(list(panel = "after", version = v), nickel_args)))
}


# ***********************************************************
# Part 7: Figure 5, slope versus elasticity ----
# ***********************************************************
# The nickel demand curve Q = 85 - 0.5P with the point E0 = (40, 90): the
# slope dQ/dP = -0.5 is the same everywhere, the elasticity -0.5 x P/Q is
# not (-1.125 at E0, -0.7 at E1, shown by the hollow marker). On the
# website a slider moves the point; this PNG is for the overview sheet.
f5 <- save_png("fig05_elasticity", size_one, function()
  draw_chain_elasticity("nickel", P = 90, xlim = ax_nickel$xlim,
                        ylim = ax_nickel$ylim, tick_step = ax_nickel$ticks,
                        fit_top = TRUE))


# ***********************************************************
# Part 8: Figures 6, 7 and 7b, the two linked markets and welfare ----
# ***********************************************************
# Explanatory notes:
  # Left the nickel market (derived demand 170 - 2Q), right the battery
  # market (demand 220 - Q, supply P_N + 50 + Q: 140 + Q before, 120 + Q
  # after). The quantity axes are the same, because Q_N = Q_B.
  # Figure 6: both equilibria; the nickel price falls by 20, the battery
  # supply curve shifts down by the same 20 (input cost), the battery
  # price falls by 10 (tutor version; the student version shows only E0).
  # Figure 7 (E0) and 7b (E1): welfare. The dashed line splits CS_N into a
  # blue part equal to CS_B and an orange part equal to PS_B: the right
  # panel uses the same colours, so CS_N = CS_B + PS_B can be seen.
linked_args <- list(A = chain02$A, b = chain02$b, c = chain02$c,
                    g = chain02$g, u = chain02$u, s = chain02$s,
                    k = chain02$k, xlim = ax_linked$xlim,
                    ylim_N = ax_linked$ylim_N, ylim_B = ax_linked$ylim_B,
                    tick_step = ax_linked$ticks, fit_top = TRUE)
f6 <- list(); f7 <- list(); f7b <- list()
for (v in versions) {
  f6[[v]] <- save_png(paste0("fig06_linked_markets_", v), size_two,
    function() do.call(draw_chain_linked,
      c(list(show = "curves", version = v), linked_args)))
  f7[[v]] <- save_png(paste0("fig07_welfare_E0_", v), size_two,
    function() do.call(draw_chain_linked,
      c(list(show = "welfare", at = "before", version = v), linked_args)))
  f7b[[v]] <- save_png(paste0("fig07b_welfare_E1_", v), size_two,
    function() do.call(draw_chain_linked,
      c(list(show = "welfare", at = "after", version = v), linked_args)))
}


# ***********************************************************
# Part 9: Overview sheet of all tutor figures (a working file) ----
# ***********************************************************
# Explanatory notes:
  # One PNG with every tutor figure as a small tile and a bold caption, to
  # check the whole series at a glance (not linked on the website). It
  # reads the PNGs back in with the png package (readPNG), so it is skipped
  # with a message if that package is not installed. Each image is shrunk
  # (every 4th pixel) before it is placed, to keep the memory use small.
overview <- list(
  c("fig01_value_chain",            "Fig 1 - value chain"),
  c("fig02_firm_tutor",             "Fig 2 - one nickel producer"),
  c("fig03_firm_to_industry",       "Fig 3 - from firm to industry supply"),
  c("fig03b_innovation_supply",     "Fig 3b - the innovation shifts supply"),
  c("fig04a_nickel_before_tutor",   "Fig 4a - nickel market before"),
  c("fig04b_nickel_after_tutor",    "Fig 4b - nickel market after"),
  c("fig05_elasticity",             "Fig 5 - slope versus elasticity"),
  c("fig06_linked_markets_tutor",   "Fig 6 - two linked markets"),
  c("fig07_welfare_E0_tutor",       "Fig 7 - welfare at E0"),
  c("fig07b_welfare_E1_tutor",      "Fig 7b - welfare at E1"))
if (requireNamespace("png", quietly = TRUE)) {
  file_ov <- file.path(o_fig_t2, "tutorial02_figures_overview.png")
  n_col <- 2; n_row <- ceiling(length(overview) / n_col)
  tile_w <- 8; tile_h <- 4.5 + 0.45            # inches: image + caption
  png(file_ov, width = n_col * tile_w, height = n_row * tile_h,
      units = "in", res = 100)
  op_ov <- par(mfrow = c(n_row, n_col), mar = c(0.3, 0.3, 2.2, 0.3))
  for (tile in overview) {
    img <- png::readPNG(file.path(o_fig_t2, paste0("tutorial02_", tile[1],
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
  message("Part 9 skipped: the overview sheet needs the R package 'png' ",
          "(install.packages(\"png\")).")
}


# ***********************************************************
# Part 10: Answer key numbers (printed in the console) ----
# ***********************************************************
# print() is needed because RStudio's "Source" button does not auto-print.
# All numbers come from chain_outcomes(), the same function the figures
# and the website app use.
ak <- chain_outcomes(A = chain02$A, b = chain02$b, c = chain02$c,
                     g = chain02$g, u = chain02$u, s = chain02$s,
                     k = chain02$k, n_N = chain02$n, n_B = chain02$n,
                     FC = chain02$FC)

### Exercise 1: one nickel firm at P_N = 90 (Figure 2) ----
print(round(c(q_star = f2$tutor$Q_star, TR = f2$tutor$TR, TVC = f2$tutor$TVC,
              PS = f2$tutor$PS, FC = f2$tutor$FC, profit = f2$tutor$profit), 2))

### Exercise 1: firm and industry supply (Figures 3 and 3b) ----
# q and Q at P = 90 and 120; after the innovation at P = 90; 11 firms
print(round(c(q_90 = f3$q[1], Q_90 = f3$Q[1], q_120 = f3$q[2],
              Q_120 = f3$Q[2], q_after_90 = f3$q_after,
              Q_after_90 = f3$Q_after, Q_11_firms_90 = f3$Q_entry,
              shift_firm = f3$shift_firm,
              shift_industry = f3$shift_industry), 2))

### Equilibria before (E0) and after (E1) ----
eq <- rbind(before = unlist(ak$before[c("Q", "P_N", "P_B", "q_N", "q_B")]),
            after  = unlist(ak$after[c("Q", "P_N", "P_B", "q_N", "q_B")]))
print(round(eq, 2))

### Surpluses and the welfare ledger (Table 4) ----
led <- rbind(before = unlist(ak$before[c("PS_N", "PS_B", "CS_B", "NSB",
                                         "CS_N", "TS_N", "wrong_sum")]),
             after  = unlist(ak$after[c("PS_N", "PS_B", "CS_B", "NSB",
                                        "CS_N", "TS_N", "wrong_sum")]))
led <- rbind(led, change = led["after", ] - led["before", ])
print(round(led, 2))

### Per firm: producer surplus and profit (PS - FC) ----
print(round(rbind(
  before = unlist(ak$before[c("PS_firm_N", "profit_firm_N", "PS_firm_B",
                              "profit_firm_B")]),
  after  = unlist(ak$after[c("PS_firm_N", "profit_firm_N", "PS_firm_B",
                             "profit_firm_B")])), 2))

### Resource-cost check (Question 3.4d) ----
# value to final users - cost of nickel - cost of other inputs = NSB
print(round(rbind(
  before = unlist(ak$before[c("value", "cost_N", "cost_other",
                              "NSB_resource")]),
  after  = unlist(ak$after[c("value", "cost_N", "cost_other",
                             "NSB_resource")])), 2))

### Elasticities (Worked examples 5 and 9, Question 2.3) ----
print(round(rbind(
  E0 = unlist(ak$before[c("eps_D_N", "eps_S_N", "eps_D_B", "eps_S_B")]),
  E1 = unlist(ak$after[c("eps_D_N", "eps_S_N", "eps_D_B", "eps_S_B")])), 3))
# Technical box example Q = 100 - 2P at P = 20 and P = 40
print(round(c(at_P20 = elasticity_point(-2, 100, 20)$elasticity,
              at_P40 = elasticity_point(-2, 100, 40)$elasticity), 3))

### Changes and pass-through (Worked examples 6 and 8) ----
print(round(c(dQ = ak$dQ, dP_N = ak$dP_N, dP_B = ak$dP_B,
              rho_upstream = ak$rho_N, rho_downstream = ak$rho_B,
              rho_total = ak$rho_total), 3))
