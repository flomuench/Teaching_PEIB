# ***********************************************************
# Title: SEES0082 Political Economy of International Business, UCL SSEES:
#        course website with interactive diagrams (Teaching_PEIB)
#
# Purpose: Tutorial 5 static figures (300 dpi PNGs) for the Word handouts
#          and the website, plus the numbers for the answer key: linked
#          investments (hydrogen and steel) and FDI with local suppliers
#       Part 1: Parameters (figure sizes, resolution)
#       Part 2: Helper function that saves one figure as a PNG
#       Part 3: Figure 1, the status quo: hydrogen | steel
#       Part 4: Figure 2, joint investment: hydrogen | steel
#       Part 5: Figure 4, FDI scenarios in the input and chip markets
#       Part 6: Overview sheet of the answers figures (a working file)
#       Part 7: Answer key numbers, checked against the handout tables
#
# Authors: Florian Münch
# Requires: Parts 1 and 2 of code/master.R: the path variable o_fig_t5
#     (figures/tutorial5/) and the drawing functions from
#     code/functions_models.R (Part 8 there); the R package png for the
#     overview sheet only (Part 6 is skipped with a message without it)
# Creates: PNGs in figures/tutorial5/ (300 dpi), overwriting the previous
#     versions:
#     tutorial05_fig01_status_quo_noanswers/answers.png             (Part 3)
#     tutorial05_fig02_joint_investment_noanswers/answers.png       (Part 4)
#     tutorial05_fig04_two_markets_scenarios_noanswers/answers.png  (Part 5)
#     tutorial05_figures_overview.png                               (Part 6)
#     (Figure 3, the value-chain schematic, is drawn in TikZ:
#     Latex slides/PEIB/tutorial05_figures.tex.)
# ***********************************************************

# How to run (explanatory notes):
  # Do not run this script on its own: open Teaching_PEIB.Rproj, open
  # code/master.R and run it (Part 7 switches this script on). master.R sets
  # the folder paths (Part 1) and loads the drawing functions (Part 2).
  #
  # Two versions, named after the two versions of the handout: "noanswers"
  # (before the tutorial) and "answers" (after it). In the noanswers
  # versions the points students compute carry no coordinates and no drop
  # lines (Figure 2: E1 in both markets, and the steel supply is labelled
  # "green hydrogen" instead of P_H = 26; Figure 4: E3), and no surplus
  # areas are shaded. Points the handout gives keep their coordinates (E0
  # everywhere; E1 of the enclave in Figure 4, Walkthrough 3).
  #
  # Sizes: Figures 1 and 2 are 9 x 4.2 inches, Figure 4 8 x 7.2 inches; in
  # Word set the width to the text width (about 16 cm), "Lock aspect ratio"
  # ticked.

# Safety check: stop with a clear message if master.R Parts 1-2 have not run
if (!exists("o_fig_t5") || !exists("draw_h2_steel")) {
  stop("o_fig_t5 or the drawing functions are missing. Run code/master.R ",
       "(at least Parts 1 and 2) instead of this script on its own.",
       call. = FALSE)
}
dir.create(o_fig_t5, recursive = TRUE, showWarnings = FALSE)


# ***********************************************************
# Part 1: Parameters ----
# ***********************************************************
# The model values are the defaults of h2_outcomes() and fdi_outcomes()
# (functions_models.R, Part 8); change them there, so that the website app
# changes too.
fig_dpi   <- 300
size_two  <- c(9, 4.2)     # Figures 1 and 2: two panels side by side
size_fdi  <- c(8, 7.2)     # Figure 4: two rows of two panels
# Figure 4 rows: c(lambda, tau). Enclave (all inputs imported) and local
# inputs with knowledge transfer. Scenario 2 (local inputs, tau = 0) is
# left out of the handout figure (Florian, 2 Nov 2026); add c(1, 0) as a
# middle row (and make the figure 9.5 inches tall) for the slides.
scen05 <- list(c(0, 0), c(1, 12))


# ***********************************************************
# Part 2: Helper function that saves one figure as a PNG ----
# ***********************************************************
# png() opens a file, everything plotted goes into it, dev.off() closes and
# saves it; on.exit() closes it even if a drawing function stops.
save_png05 <- function(name, size, draw) {
  file <- file.path(o_fig_t5, paste0("tutorial05_", name, ".png"))
  png(file, width = size[1], height = size[2], units = "in", res = fig_dpi)
  on.exit(dev.off())
  out <- draw()
  message("Saved ", file)
  invisible(out)
}
versions <- c("noanswers", "answers")


# ***********************************************************
# Part 3: Figure 1, the status quo: hydrogen | steel ----
# ***********************************************************
# Hydrogen: supply 40 + Q_H/2, other users' demand fixed at 10: E0 = (10, 45),
# PS = 25. Steel: demand 100 - Q_S, supply 60 + Q_S: E0 = (20, 80), PS = 200.
# Both points are given in the handout (Table 2), so they carry their
# coordinates in both versions; the answers version shades the PS areas.
f1 <- list()
for (v in versions) {
  f1[[v]] <- save_png05(paste0("fig01_status_quo_", v), size_two,
    function() draw_h2_steel("status_quo", v))
}


# ***********************************************************
# Part 4: Figure 2, joint investment: hydrogen | steel ----
# ***********************************************************
# Hydrogen: green supply 5 + Q_H/2, derived demand 110 - 2 Q_H (Q_H >= 10):
# E1 = (42, 26), PS1 = 441. Steel: hydrogen-based supply 10 + 26 + Q_S =
# 36 + Q_S: E1 = (32, 68), PS1 = 512. Dashed: steel alone (conventional
# hydrogen at 54, supply 64 + Q_S). Middle: the backward (demand) and
# forward (cost) linkages.
f2 <- list()
for (v in versions) {
  f2[[v]] <- save_png05(paste0("fig02_joint_investment_", v), size_two,
    function() draw_h2_steel("joint", v))
}


# ***********************************************************
# Part 5: Figure 4, FDI scenarios in the input and chip markets ----
# ***********************************************************
# Grey: the no-FDI benchmark (input demand 80 - 2Q, local supply 20 + Q,
# E0 = (20, 40); chip supply 120 + Q_D, E0 = (20, 140)). Black: the active
# curves after FDI. Row 1, enclave: suppliers abroad 8 + Q, E1 = (44, 52)
# and (44, 116). Row 2, local inputs with knowledge transfer (tau = 12):
# local supply 8 + Q, E3 = (44, 52) and (44, 116). Answers: surpluses
# coloured by owner (Home blue, Foreign red), each 968.
f4 <- list()
for (v in versions) {
  f4[[v]] <- save_png05(paste0("fig04_two_markets_scenarios_", v), size_fdi,
    function() draw_fdi_scenarios(scen05, version = v))
}


# ***********************************************************
# Part 6: Overview sheet of the answers figures (a working file) ----
# ***********************************************************
# One PNG with the answers figures as tiles with bold captions, to check
# the series at a glance (not linked on the website). Needs the png package.
overview05 <- list(
  c("fig01_status_quo_answers",              "Fig 1 - status quo"),
  c("fig02_joint_investment_answers",        "Fig 2 - joint investment"),
  c("fig03_value_chain_fdi",                 "Fig 3 - value chain (TikZ)"),
  c("fig04_two_markets_scenarios_answers",   "Fig 4 - FDI scenarios"))
make_overview05 <- function(file_ov) {
  n_col <- 2; n_row <- ceiling(length(overview05) / n_col)
  tile_w <- 9; tile_h <- 6.6 + 0.45
  png(file_ov, width = n_col * tile_w, height = n_row * tile_h,
      units = "in", res = 80)
  on.exit(dev.off())
  par(mfrow = c(n_row, n_col), mar = c(0.3, 0.3, 2.2, 0.3))
  for (tile in overview05) {
    f <- file.path(o_fig_t5, paste0("tutorial05_", tile[1], ".png"))
    plot(NA, xlim = c(0, 1), ylim = c(0, 1), axes = FALSE, ann = FALSE,
         xaxs = "i", yaxs = "i")
    if (file.exists(f)) {
      img <- png::readPNG(f)
      img <- img[seq(1, dim(img)[1], by = 4), seq(1, dim(img)[2], by = 4), ,
                 drop = FALSE]
      asp <- dim(img)[1] / dim(img)[2]
      pin <- par("pin"); box_asp <- pin[2] / pin[1]
      w <- if (asp > box_asp) box_asp / asp else 1
      h <- if (asp > box_asp) 1 else asp / box_asp
      rasterImage(img, (1 - w) / 2, (1 - h) / 2, (1 + w) / 2, (1 + h) / 2,
                  interpolate = TRUE)
    } else {
      text(0.5, 0.5, "(file not found)", cex = 1.4)
    }
    rect(0, 0, 1, 1, border = "grey80")
    title(main = tile[2], font.main = 2, cex.main = 1.5, line = 0.6)
  }
  message("Saved ", file_ov)
}
if (requireNamespace("png", quietly = TRUE)) {
  make_overview05(file.path(o_fig_t5, "tutorial05_figures_overview.png"))
} else {
  message("Part 6 skipped: the overview sheet needs the R package 'png'.")
}


# ***********************************************************
# Part 7: Answer key numbers, checked against the handout tables ----
# ***********************************************************
# print() because RStudio's "Source" does not auto-print. Every number is
# also CHECKED against the handout: if the model functions ever change, the
# script stops with a message naming the number that no longer matches.
check05 <- function(got, want, what) {
  if (!isTRUE(all.equal(unname(got), unname(want), tolerance = 1e-9))) {
    stop("Tutorial 5 answer key mismatch (", what, "): got ",
         paste(round(got, 3), collapse = ", "), ", handout says ",
         paste(want, collapse = ", "), call. = FALSE)
  }
}

### Exercise 1: the four cases (Table 4 and Appendix Table A.1) ----
h2_vars <- c("Q_H", "P_H", "Q_S", "P_S", "PS_H", "PS_S", "Pi_H", "Pi_S")
h2_tab <- rbind(
  status_quo     = unlist(h2_outcomes(FALSE, FALSE)[h2_vars]),
  hydrogen_alone = unlist(h2_outcomes(FALSE, TRUE)[h2_vars]),
  steel_alone    = unlist(h2_outcomes(TRUE, FALSE)[h2_vars]),
  joint          = unlist(h2_outcomes(TRUE, TRUE)[h2_vars]))
print(h2_tab)
check05(h2_tab["status_quo", ],     c(10, 45, 20, 80, 25, 200, 25, 200),
        "status quo")
check05(h2_tab["hydrogen_alone", ], c(10, 10, 20, 80, 25, 200, -155, 200),
        "hydrogen alone")
check05(h2_tab["steel_alone", ],    c(28, 54, 18, 82, 196, 162, 196, 12),
        "steel alone")
check05(h2_tab["joint", ],          c(42, 26, 32, 68, 441, 512, 261, 362),
        "joint investment")
# Gains from joint investment over the status quo (net of fixed costs)
gain05 <- h2_tab["joint", c("Pi_H", "Pi_S")] -
  h2_tab["status_quo", c("Pi_H", "Pi_S")]
print(gain05)
check05(gain05, c(236, 162), "gains from joint investment")

### Exercise 2: Tables 8 and 9 (variant B) ----
fdi_vars <- c("Q_D", "Q_U", "Q_M", "P_U", "P_M", "P_D", "CS_D", "PS_U",
              "PS_M", "PS_D", "Pi_F", "W_H", "W_F", "W_W")
fdi_tab <- rbind(
  "0 no FDI"             = unlist(fdi_outcomes(FALSE)[fdi_vars]),
  "1 enclave"            = unlist(fdi_outcomes(TRUE, 0, 0)[fdi_vars]),
  "2 local, no transfer" = unlist(fdi_outcomes(TRUE, 1, 0)[fdi_vars]),
  "3 local + transfer"   = unlist(fdi_outcomes(TRUE, 1, 12)[fdi_vars]))
print(fdi_tab)   # NA = n/a (no transactions in that market)
want8 <- rbind(c(20, 20, 0, 40, NA, 140),
               c(44, 0, 44, NA, 52, 116),
               c(40, 40, 0, 60, NA, 120),
               c(44, 44, 0, 52, NA, 116))
want9 <- rbind(c(200, 200, 0, 200, 0, 600, 0, 600),
               c(968, 0, 968, 0, 968, 968, 1936, 2904),
               c(800, 800, 0, 0, 800, 1600, 800, 2400),
               c(968, 968, 0, 0, 968, 1936, 968, 2904))
for (i in 1:4) {
  check05(fdi_tab[i, 1:6], want8[i, ], paste("Table 8, row", i))
  check05(fdi_tab[i, 7:14], want9[i, ], paste("Table 9, row", i))
}
message("Tutorial 5: all answer key numbers match the handout (Tables 2, ",
        "4, 8, 9 and A.1).")
