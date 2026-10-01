# =============================================================================
# models.R - shared model logic and plotting for SEES0082 diagrams
# =============================================================================
#
# This ONE file is used in two places:
#   (a) by the interactive shinylive apps on the website (Quarto copies the
#       file into each app at render time with Quarto's "include" shortcode;
#       never write that shortcode literally in this file, or Quarto would
#       try to include the file inside itself),
#   (b) by R/make_figures.R, which you run locally to produce PNGs for
#       Word handouts.
# So if you change a formula or a colour here, both the website and the
# handout figures change consistently.
#
# Only BASE R is used (no ggplot2, no other packages). This keeps the
# download in the student's browser (webR) small and fast.
#
# Model: linear demand and supply with a per-unit tax
#   Demand:  P = a - b * Q   (a = highest willingness to pay, b = slope)
#   Supply:  P = c + d * Q   (c = lowest cost / reservation price, d = slope)
#   Tax:     t per unit sold. It drives a wedge between the price buyers
#            pay (Pb) and the price sellers keep (Ps = Pb - t).
# =============================================================================


# -----------------------------------------------------------------------------
# 1. Colour palette (colour-blind safe, based on the Tableau 10 palette)
# -----------------------------------------------------------------------------
# A named vector, so code below can write peib_cols["cs"] instead of a hex code.
peib_cols <- c(
  cs     = "#4C78A8",  # consumer surplus - blue
  ps     = "#F58518",  # producer surplus - orange
  tax    = "#54A24B",  # tax revenue      - green
  dwl    = "#E45756",  # deadweight loss  - red
  demand = "#1F3B5C",  # demand line      - dark blue
  supply = "#8C4A00"   # supply line      - dark orange/brown
)


# -----------------------------------------------------------------------------
# 2. check_market_inputs(): defensive checks with readable error messages
# -----------------------------------------------------------------------------
# Called by both functions below. stop() halts with a message that tells the
# user what went wrong in plain words, rather than a cryptic R error later.
check_market_inputs <- function(a, b, c, d, tax) {
  args <- list(a = a, b = b, c = c, d = d, tax = tax)
  for (nm in names(args)) {
    x <- args[[nm]]
    if (!is.numeric(x) || length(x) != 1 || is.na(x)) {
      stop("'", nm, "' must be a single number, not ", deparse(x), ".",
           call. = FALSE)
    }
  }
  if (b <= 0) stop("Demand slope 'b' must be positive (demand slopes down).",
                   call. = FALSE)
  if (d <= 0) stop("Supply slope 'd' must be positive (supply slopes up).",
                   call. = FALSE)
  if (tax < 0) stop("The per-unit 'tax' cannot be negative ",
                    "(a subsidy is not modelled here).", call. = FALSE)
  invisible(TRUE)
}


# -----------------------------------------------------------------------------
# 3. market_outcomes(): all the numbers (equilibrium, surpluses, tax, DWL)
# -----------------------------------------------------------------------------
# Returns a named list, e.g. out <- market_outcomes(12, 1, 2, 1); out$CS
market_outcomes <- function(a, b, c, d, tax = 0) {
  check_market_inputs(a, b, c, d, tax)

  # --- No-tax equilibrium: set a - b*Q = c + d*Q and solve for Q ----------
  # If a <= c, even the keenest buyer values the good less than the cheapest
  # seller's cost: no trade happens at all (Q0 = 0).
  Q0 <- max(0, (a - c) / (b + d))
  P0 <- a - b * Q0           # price read off the demand curve

  # --- With a tax: buyers pay Pb, sellers keep Ps = Pb - t -----------------
  # Trade happens only while willingness to pay exceeds cost PLUS tax,
  # so we solve a - b*Q = c + d*Q + t. max(0, ...) handles "tax kills trade".
  Qt <- max(0, (a - c - tax) / (b + d))
  Pb <- a - b * Qt           # price buyers pay (on the demand curve)
  Ps <- Pb - tax             # price sellers receive

  # If no trade happens, prices are not really defined. We keep the formulas
  # above (so the plot has somewhere to draw guide lines) but flag the case.
  no_trade <- Qt <= 0

  # --- Welfare areas (all triangles/rectangles because the lines are straight)
  CS          <- 0.5 * (a - Pb) * Qt     # triangle between demand and Pb
  PS          <- 0.5 * (Ps - c) * Qt     # triangle between Ps and supply
  tax_revenue <- tax * Qt                # rectangle: tax x quantity
  DWL         <- 0.5 * tax * (Q0 - Qt)   # triangle of trades that no longer happen
  # Note: when the tax kills all trade (Qt = 0) the DWL is the whole no-tax
  # surplus, which the triangle formula above would NOT give (the triangle is
  # cut off at Q = 0). So we compute it as "lost total surplus" in that case.
  total_surplus_no_tax <- 0.5 * (a - c) * Q0
  if (no_trade) {
    DWL <- total_surplus_no_tax
    CS  <- 0   # set exactly to 0: with Qt = 0 and a negative Ps the formula
    PS  <- 0   # above gives -0, which the app table would print as "-0.00"
  }

  list(
    Q0 = Q0, P0 = P0,
    Qt = Qt, Pb = Pb, Ps = Ps,
    CS = CS, PS = PS,
    tax_revenue = tax_revenue,
    DWL = DWL,
    total_surplus = CS + PS + tax_revenue,
    total_surplus_no_tax = total_surplus_no_tax,
    no_trade = no_trade,
    no_trade_ever = a <= c     # TRUE if there is no trade even without a tax
  )
}


# -----------------------------------------------------------------------------
# 4. draw_market(): the supply-and-demand diagram in base R graphics
# -----------------------------------------------------------------------------
# Axis limits are FIXED (xlim, ylim) so that when a slider moves, students see
# the curves move rather than the axes re-scaling.
draw_market <- function(a = 10, b = 1, c = 2, d = 1, tax = 0,
                        show_cs = TRUE, show_ps = TRUE, show_tax = TRUE,
                        xlim = c(0, 20), ylim = c(0, 20), main = NULL) {
  out <- market_outcomes(a, b, c, d, tax)

  # Small helper: semi-transparent version of a colour for shaded areas
  fill <- function(col, alpha = 0.45) adjustcolor(col, alpha.f = alpha)

  # --- Empty canvas with our fixed axes -----------------------------------
  # xaxs = "i" / yaxs = "i" stop R from adding 4% padding, so the axes meet
  # exactly at the origin (as in textbook diagrams).
  # mar = margins in lines (bottom, left, top, right). The top margin always
  # leaves room for a two-row legend (so the plot does not jump when areas are
  # switched on/off), plus a title line if 'main' is given.
  op <- par(mar = c(4.2, 4.2, if (is.null(main)) 2.8 else 4.6, 1), las = 1)
  on.exit(par(op))          # restore the user's settings when we finish
  plot(NA, xlim = xlim, ylim = ylim, xaxs = "i", yaxs = "i",
       xlab = "Quantity (Q)", ylab = "Price (P)",
       bty = "l", cex.lab = 1.1)
  if (!is.null(main)) title(main = main, line = 3.2)

  # clip() limits all subsequent drawing to the plotting region, so lines that
  # would run off the chart are cut neatly at the axes.
  clip(xlim[1], xlim[2], ylim[1], ylim[2])

  # Short-hands for the important numbers
  Q0 <- out$Q0; Qt <- out$Qt; Pb <- out$Pb; Ps <- out$Ps

  # --- Shaded welfare areas (drawn first, so the lines sit on top) ---------
  if (Qt > 0) {
    # Consumer surplus: triangle between demand curve and price buyers pay
    if (show_cs) polygon(c(0, 0, Qt), c(a, Pb, Pb),
                         col = fill(peib_cols["cs"]), border = NA)
    # Producer surplus: triangle between price sellers keep and supply curve
    if (show_ps) polygon(c(0, 0, Qt), c(c, Ps, Ps),
                         col = fill(peib_cols["ps"]), border = NA)
    # Tax revenue: rectangle of height t and width Qt
    if (show_tax && tax > 0) rect(0, Ps, Qt, Pb,
                                  col = fill(peib_cols["tax"]), border = NA)
  }
  # Deadweight loss: triangle between Qt and Q0, bounded by the two curves
  if (show_tax && tax > 0 && Q0 > Qt) {
    if (Qt > 0) {
      polygon(c(Qt, Qt, Q0), c(Pb, Ps, out$P0),
              col = fill(peib_cols["dwl"], 0.6), border = NA)
    } else {
      # Tax so high that no trade happens: ALL of the old surplus is lost,
      # i.e. the whole triangle between the demand and supply lines.
      polygon(c(0, 0, Q0), c(a, c, out$P0),
              col = fill(peib_cols["dwl"], 0.6), border = NA)
    }
  }

  # --- Demand and supply lines --------------------------------------------
  # abline(intercept, slope) draws a straight line across the whole region
  # (clip() above keeps it inside the box).
  abline(a = a, b = -b, col = peib_cols["demand"], lwd = 2.5)
  abline(a = c, b =  d, col = peib_cols["supply"], lwd = 2.5)

  # Label the lines "D" and "S". We walk along each line from the right and
  # take the first point that lies comfortably inside the plotting box.
  # - "D" sits just to the RIGHT of the demand line, a little above the
  #   Q axis (12% of the height), where the chart is always empty.
  # - "S" sits just to the LEFT of the supply line, near the top.
  label_line <- function(intercept, slope, txt, col, y_lo, y_hi, side) {
    xs <- seq(xlim[2], xlim[1], length.out = 400)
    ys <- intercept + slope * xs
    ok <- which(ys >= y_lo & ys <= y_hi)
    if (length(ok) == 0) return(invisible(NULL))
    i <- ok[1]
    # Near the right edge there is no room on the right: put the label below
    x <- xs[i]
    if (side == 4 && x > xlim[2] - 0.06 * diff(xlim)) {
      side <- 1
      x <- xlim[2] - 0.03 * diff(xlim)       # step back so it is not cut off
      ys[i] <- intercept + slope * x
    }
    text(x, ys[i], txt, col = col, font = 2, cex = 1.2, pos = side,
         offset = 0.6)
  }
  label_line(a, -b, "D", peib_cols["demand"],
             y_lo = ylim[1] + 0.12 * diff(ylim), y_hi = ylim[2] - 0.04 * diff(ylim),
             side = 4)
  label_line(c,  d, "S", peib_cols["supply"],
             y_lo = ylim[1] + 0.04 * diff(ylim), y_hi = ylim[2] - 0.04 * diff(ylim),
             side = 2)

  # --- Dashed guide lines and value labels ----------------------------------
  # Value labels are written INSIDE the plot, next to the axes, so they never
  # collide with the axis tick numbers.
  fmt <- function(x) formatC(x, format = "f", digits = 2, drop0trailing = TRUE)
  dx <- 0.01 * diff(xlim)   # small offsets, 1% of the axis range
  dy <- 0.02 * diff(ylim)
  if (Qt > 0) {
    p_name <- if (tax > 0) "Pb" else "P*"   # buyers' price (or the equilibrium)
    q_name <- if (tax > 0) "Qt" else "Q*"
    # Horizontal guide at the price buyers pay, vertical guide down to Qt
    segments(0, Pb, Qt, Pb, lty = 2, col = "grey30")
    segments(Qt, 0, Qt, Pb, lty = 2, col = "grey30")
    text(dx, Pb, paste0(p_name, " = ", fmt(Pb)), adj = c(0, -0.4), cex = 0.8)
    text(Qt + dx, dy, paste0(q_name, " = ", fmt(Qt)), adj = c(0, 0), cex = 0.8)
    if (tax > 0) {
      # Price sellers keep, and the old no-tax quantity (dotted) for comparison
      segments(0, Ps, Qt, Ps, lty = 2, col = "grey30")
      text(dx, Ps, paste0("Ps = ", fmt(Ps)), adj = c(0, 1.4), cex = 0.8)
      if (Q0 > 0) segments(Q0, 0, Q0, out$P0, lty = 3, col = "grey50")
    }
    points(Qt, Pb, pch = 19, cex = 0.9)  # mark the (taxed) equilibrium point
  } else {
    # No trade: say so on the chart rather than showing nothing
    # (a white box behind the text keeps it readable on top of the lines)
    msg <- "No trade: buyers' highest willingness to pay\nis below sellers' cost (plus tax)"
    mx <- mean(xlim); my <- ylim[1] + 0.75 * diff(ylim)
    w <- strwidth(msg, cex = 0.95) / 2 + 0.02 * diff(xlim)
    h <- strheight(msg, cex = 0.95) / 2 + 0.03 * diff(ylim)
    rect(mx - w, my - h, mx + w, my + h, col = "white", border = "grey60")
    text(mx, my, msg, cex = 0.95, col = "grey20")
  }

  # --- Compact legend in the top margin: only list what is actually shown ----
  items <- character(0); cols <- character(0)
  add <- function(label, col) { items <<- c(items, label); cols <<- c(cols, col) }
  if (show_cs && Qt > 0)              add("Consumer surplus", fill(peib_cols["cs"]))
  if (show_ps && Qt > 0)              add("Producer surplus", fill(peib_cols["ps"]))
  if (show_tax && tax > 0 && Qt > 0)  add("Tax revenue",      fill(peib_cols["tax"]))
  if (show_tax && tax > 0 && Q0 > Qt) add("Deadweight loss",  fill(peib_cols["dwl"], 0.6))
  if (length(items) > 0) {
    do.call("clip", as.list(par("usr")))   # (legend is outside the box anyway)
    # xpd = NA allows drawing in the margin; yjust = 0 puts the legend's
    # bottom edge on the top of the plotting box.
    legend(x = mean(xlim), y = ylim[2], xjust = 0.5, yjust = 0, xpd = NA,
           legend = items, fill = cols, border = NA, bty = "n",
           ncol = 2, cex = 0.85, x.intersp = 0.6, text.width = 0.3 * diff(xlim))
  }

  invisible(out)
}
