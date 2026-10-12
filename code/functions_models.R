# ***********************************************************
# Title: SEES0082 Political Economy of International Business, UCL SSEES:
#        course website with interactive diagrams (Teaching_PEIB)
#
# Purpose: all model and drawing functions for the course diagrams
#       Part 1: Colour palette and layout helpers shared by all diagrams
#       Part 2: Model A, the market with a per-unit tax
#               (market_outcomes(), draw_market())
#       Part 3: Model B, one price-taking firm: where the supply curve
#               comes from (draw_firm_step(), steps 1 to 6b)
#       Part 4: Model C, the market step by step: demand, equilibrium,
#               excess supply and shortage (draw_market_step())
#       Part 5: Model D, Tutorial 2: the nickel-battery value chain, two
#               markets linked by an input (chain_outcomes(),
#               nickel_market_outcomes(), elasticity_point(),
#               draw_chain_firm(), draw_chain_supply(), draw_chain_nickel(),
#               draw_chain_elasticity(), draw_chain_linked())
#
# Authors: Florian Münch
# Requires: base R only (the packages graphics and grDevices, which every
#     R session loads automatically). No input files.
# Creates: no files. Running this script only DEFINES functions and the
#     colour vector peib_cols; nothing is drawn or saved.
# ***********************************************************

# How this file is used (explanatory notes):
  # (a) By the interactive shinylive apps on the website. A shinylive app
  #     runs inside the student's browser and cannot read files from this
  #     repository. So each tutorial page lists functions_models.R as a
  #     second file of its app, and Quarto's include shortcode (pointing at
  #     ../code/functions_models.R) pastes the content of this file into the
  #     app when the site is rendered. Never write that shortcode literally
  #     in this file, or Quarto would try to include the file inside itself.
  # (b) By the static figures for the Word handouts: code/master.R sources
  #     this file (Part 2) and then runs code/tutorial01_figures.R,
  #     code/tutorial02_figures.R, ...
  # So if you change a formula or a colour here, the website and the
  # handout figures change consistently.
  #
  # Because the file is copied into the browser apps, it must stay
  # self-contained: only BASE R (no library() calls, no ggplot2: every
  # package would have to be downloaded into the student's browser by webR),
  # no file paths, and no side effects (it only defines objects).


# ***********************************************************
# Part 1: Colour palette and shared layout helpers ----
# ***********************************************************

### 1. Colour palette (colour-blind safe, based on Tableau 10) ----
# A named vector, so code below can write peib_cols["cs"] instead of a hex code.
peib_cols <- c(
  cs     = "#4C78A8",  # consumer surplus - blue
  ps     = "#F58518",  # producer surplus - orange
  tax    = "#54A24B",  # tax revenue      - green
  dwl    = "#E45756",  # deadweight loss  - red
  demand = "#1F3B5C",  # demand line      - dark blue
  supply = "#8C4A00",  # supply line      - dark orange/brown
  # Added for the one-firm diagrams (Tutorial 1, Part 1):
  tr     = "#72B7B2",  # total revenue    - teal
  tvc    = "#B279A2",  # total variable cost - purple
  profit = "#EECA3B",  # profit           - yellow
  loss   = "#E45756",  # loss             - red (same red as deadweight loss)
  fc     = "#BAB0AC",  # fixed cost       - warm grey
  avc    = "#6F3D6B",  # average variable cost line - dark purple
  atc    = "#4D4D4D"   # average total cost line    - dark grey
)


# Two small layout helpers shared by all diagrams:
#
# peib_top_margin(): the top margin in lines. With n_legend = NULL (the
# default, used by the apps) there is always room for a two-row legend, so
# the plot does not jump when areas are switched on or off. With a number
# (the handout PNGs) only the room that many legend entries need (two per
# row), so there is no empty band above the plot. 'arrows' adds room for the
# arrowheads at the axis ends (steps 1 and 2). A title adds 1.8 lines.
peib_top_margin <- function(main, n_legend = NULL, arrows = FALSE) {
  if (is.null(n_legend)) return(if (is.null(main)) 2.8 else 4.6)
  rows <- ceiling(n_legend / 2)
  top  <- if (rows == 0) (if (arrows) 1.4 else 0.6) else 0.5 + 1.1 * rows
  if (is.null(main)) top else top + 1.8
}

# peib_axes(): axes with a tick and a number at every multiple of tick_step
# (e.g. 1 for the handouts: 0, 1, 2, ..., 12). R normally leaves out axis
# numbers it thinks are too close together, without warning; gap.axis = -1
# makes it draw every one of them. The L-shaped frame is drawn as with
# plot(bty = "l").
# tick_step may also be two numbers, c(x step, y step), for axes of very
# different lengths (Tutorial 2: q 0-8 in steps of 1, P 0-120 in steps of
# 10). One number is used for both axes, exactly as before.
peib_axes <- function(xlim, ylim, tick_step, cex.axis = 0.9) {
  if (!is.numeric(tick_step) || !(length(tick_step) %in% 1:2) ||
      any(is.na(tick_step)) || any(tick_step <= 0)) {
    stop("'tick_step' must be one or two positive numbers, e.g. 1 or ",
         "c(1, 10).", call. = FALSE)
  }
  step <- rep(tick_step, length.out = 2)      # c(x step, y step)
  ticks <- function(lim, tick_step) {
    t <- seq(ceiling(lim[1] / tick_step) * tick_step, lim[2], by = tick_step)
    list(at = t, lab = format(round(t, 10), trim = TRUE, drop0trailing = TRUE))
  }
  tx <- ticks(xlim, step[1]); ty <- ticks(ylim, step[2])
  axis(1, at = tx$at, labels = tx$lab, gap.axis = -1, cex.axis = cex.axis)
  axis(2, at = ty$at, labels = ty$lab, gap.axis = -1, cex.axis = cex.axis,
       las = 1)
  box(bty = "l")
}


# ***********************************************************
# Part 2: Model A, the market with a per-unit tax ----
# ***********************************************************
# Linear demand and supply with a per-unit tax (Tutorial 1 app):
#   Demand:  P = a - b * Q   (a = highest willingness to pay, b = slope)
#   Supply:  P = c + d * Q   (c = lowest cost / reservation price, d = slope)
#   Tax:     t per unit sold. It drives a wedge between the price buyers
#            pay (Pb) and the price sellers keep (Ps = Pb - t).


### 2. check_market_inputs(): defensive checks, readable error messages ----
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


### 3. market_outcomes(): equilibrium, surpluses, tax revenue, DWL ----
# Returns a named list, e.g. out <- market_outcomes(12, 1, 2, 1); out$CS
market_outcomes <- function(a, b, c, d, tax = 0) {
  check_market_inputs(a, b, c, d, tax)

  # No-tax equilibrium: set a - b*Q = c + d*Q and solve for Q
  # If a <= c, even the keenest buyer values the good less than the cheapest
  # seller's cost: no trade happens at all (Q0 = 0).
  Q0 <- max(0, (a - c) / (b + d))
  P0 <- a - b * Q0           # price read off the demand curve

  # With a tax: buyers pay Pb, sellers keep Ps = Pb - t
  # Trade happens only while willingness to pay exceeds cost PLUS tax,
  # so we solve a - b*Q = c + d*Q + t. max(0, ...) handles "tax kills trade".
  Qt <- max(0, (a - c - tax) / (b + d))
  Pb <- a - b * Qt           # price buyers pay (on the demand curve)
  Ps <- Pb - tax             # price sellers receive

  # If no trade happens, prices are not really defined. We keep the formulas
  # above (so the plot has somewhere to draw guide lines) but flag the case.
  no_trade <- Qt <= 0

  # Welfare areas (all triangles/rectangles because the lines are straight)
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


### 4. draw_market(): the supply-and-demand diagram in base R graphics ----
# Axis limits are FIXED (xlim, ylim) so that when a slider moves, students see
# the curves move rather than the axes re-scaling.
# tick_step (e.g. 1): a tick and a number at every multiple of it; NULL (the
# default) keeps R's automatic axis numbers. fit_top = TRUE shrinks the top
# margin to the legend actually shown (handout PNGs); the default FALSE always
# keeps room for a two-row legend (the app). With the defaults the output is
# exactly as before these two arguments existed.
draw_market <- function(a = 10, b = 1, c = 2, d = 1, tax = 0,
                        show_cs = TRUE, show_ps = TRUE, show_tax = TRUE,
                        xlim = c(0, 20), ylim = c(0, 20), main = NULL,
                        tick_step = NULL, fit_top = FALSE) {
  out <- market_outcomes(a, b, c, d, tax)

  # Small helper: semi-transparent version of a colour for shaded areas
  fill <- function(col, alpha = 0.45) adjustcolor(col, alpha.f = alpha)

  # Empty canvas with our fixed axes
  # xaxs = "i" / yaxs = "i" stop R from adding 4% padding, so the axes meet
  # exactly at the origin (as in textbook diagrams).
  # mar = margins in lines (bottom, left, top, right). The top margin always
  # leaves room for a two-row legend (so the plot does not jump when areas are
  # switched on/off), plus a title line if 'main' is given.
  # (With fit_top the legend entries are counted first, using the same rules
  # as the legend at the end of this function.)
  n_leg <- NULL
  if (fit_top) {
    n_leg <- sum(show_cs && out$Qt > 0, show_ps && out$Qt > 0,
                 show_tax && tax > 0 && out$Qt > 0,
                 show_tax && tax > 0 && out$Q0 > out$Qt)
  }
  top <- peib_top_margin(main, n_leg)
  op <- par(mar = c(4.2, 4.2, top, 1), las = 1)
  on.exit(par(op))          # restore the user's settings when we finish
  plot(NA, xlim = xlim, ylim = ylim, xaxs = "i", yaxs = "i",
       xlab = "Quantity (Q)", ylab = "Price (P)",
       bty = "l", cex.lab = 1.1, axes = is.null(tick_step))
  if (!is.null(tick_step)) peib_axes(xlim, ylim, tick_step)
  if (!is.null(main)) title(main = main, line = top - 1.4)

  # clip() limits all subsequent drawing to the plotting region, so lines that
  # would run off the chart are cut neatly at the axes.
  clip(xlim[1], xlim[2], ylim[1], ylim[2])

  # Short-hands for the important numbers
  Q0 <- out$Q0; Qt <- out$Qt; Pb <- out$Pb; Ps <- out$Ps

  # Shaded welfare areas (drawn first, so the lines sit on top)
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

  # Demand and supply lines
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

  # Dashed guide lines and value labels
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

  # Compact legend in the top margin: only list what is actually shown
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


# ***********************************************************
# Part 3: Model B, one firm: where does the supply curve come from? ----
# ***********************************************************
# Steps 1-5 use a straight-line supply (= marginal cost) curve
# p = c + d * q; step 6 uses a U-shaped marginal cost.
#
# The firm is a PRICE TAKER: it is so small that it cannot influence the market
# price p*, it simply sells as many units as it likes at that price.
#
# Notation in the figures: lowercase p (price) and q (quantity) for the single
# firm; p* is the market price and q* the quantity the firm chooses (where
# p* = MC). In the code the market price argument is still called P and the
# chosen quantity Q_star.
#
# Abbreviations used below (also explained on the website):
#   MC  = marginal cost: the extra cost of producing one more unit
#   TR  = total revenue = price x quantity sold
#   TVC = total variable cost: costs that grow with output (materials, hours)
#   FC  = fixed cost: paid whatever the output (rent, machines)
#   TC  = total cost = TVC + FC
#   AVC = average variable cost = TVC / q
#   ATC = average total cost = TC / q = AVC + FC / q
#   PS  = producer surplus = TR - TVC
#   pi  = profit = TR - TC = PS - FC


### 5. check_firm_number(): one defensive check for all firm functions ----
# Stops with a plain-word message unless x is a single, non-missing number
# (and, if min is given, at least min).
check_firm_number <- function(x, nm, min = -Inf, what = NULL) {
  if (!is.numeric(x) || length(x) != 1 || is.na(x)) {
    stop("'", nm, "' must be a single number, not ", deparse(x), ".",
         call. = FALSE)
  }
  if (x < min) {
    stop("'", nm, "' must be at least ", min,
         if (!is.null(what)) paste0(" (", what, ")"), ".", call. = FALSE)
  }
  invisible(TRUE)
}


### 6. firm_linear_outcomes(): steps 1-5, straight-line marginal cost ----
# Marginal cost: MC(q) = c + shift + d * q
#   c     = cost of producing the first unit
#   d     = how fast each extra unit gets more expensive
#   shift = a parallel shift of the whole MC line (e.g. input costs rise)
# P  = market price p*, q = quantity the firm chooses to produce
# (default: the profit-maximising quantity q*), FC = fixed cost,
# q_unit = one particular unit we look at in step 5b.
# (The diagrams no longer use 'shift' or 'q': supply shifts in step 2 are
# drawn as sideways shifts by draw_firm_step(); both arguments are kept for
# the app's outcome tables.)
# Returns a named list, e.g. firm_linear_outcomes(P = 8)$PS
firm_linear_outcomes <- function(c = 2, d = 1, P = 8, q = NULL, FC = 0,
                                 shift = 0, q_unit = NULL) {
  check_firm_number(c, "c")
  check_firm_number(d, "d")
  check_firm_number(P, "P", min = 0, what = "a price cannot be negative")
  check_firm_number(FC, "FC", min = 0, what = "a fixed cost cannot be negative")
  check_firm_number(shift, "shift")
  if (d <= 0) stop("Slope 'd' must be positive (each extra unit costs more).",
                   call. = FALSE)
  if (!is.null(q)) check_firm_number(q, "q", min = 0,
                                     what = "a quantity cannot be negative")
  if (!is.null(q_unit)) check_firm_number(q_unit, "q_unit", min = 0,
                                          what = "a quantity cannot be negative")

  c_eff <- c + shift                      # intercept after any cost shift
  mc <- function(x) c_eff + d * x         # marginal cost of unit number x

  # Best quantity: produce every unit whose cost is below the price, i.e.
  # stop where P* = MC(q): P = c + d*q  =>  Q* = (P - c) / d.
  # If even the first unit costs more than P*, the firm produces nothing.
  Q_star <- max(0, (P - c_eff) / d)
  if (is.null(q)) q <- Q_star

  # G(x) = surplus earned on units 0 to x = area between the price line and
  # MC = TR(x) - TVC(x). TVC(x) is the area under MC, a trapezium:
  # c*x + d*x^2/2. So G(x) = P*x - c*x - d*x^2/2.
  G <- function(x) (P - c_eff) * x - d * x^2 / 2

  TR  <- P * q
  TVC <- c_eff * q + d * q^2 / 2
  TC  <- TVC + FC
  profit <- TR - TC

  PS <- G(Q_star) + 0                      # "+ 0" turns -0 into 0 for printing
  profit_star <- PS - FC                   # best possible profit
  # Profit given up by producing q instead of Q*. It is never negative because
  # G is largest at Q*. Units beyond Q* lose money (MC > P*); units below Q*
  # that are not produced are surplus the firm misses out on.
  gap <- profit_star - profit
  list(
    c_eff = c_eff, Q_star = Q_star, P = P, q = q,
    MC_q = mc(q),
    TR = TR, TVC = TVC, FC = FC, TC = TC, profit = profit,
    TR_star = P * Q_star, TVC_star = P * Q_star - PS,
    PS = PS, profit_star = profit_star,
    loss_extra_units  = if (q > Q_star) gap else 0,
    forgone_surplus   = if (q < Q_star) gap else 0,
    unit_cost    = if (is.null(q_unit)) NA else mc(q_unit),
    unit_surplus = if (is.null(q_unit)) NA else P - mc(q_unit),
    no_production = Q_star <= 0
  )
}


### 7. firm_cubic_cost(), firm_cubic_outcomes(): step 6, U-shaped costs ----
# Total variable cost  TVC(q) = alpha*q - beta*q^2 + gamma*q^3
# Marginal cost        MC(q)  = alpha - 2*beta*q + 3*gamma*q^2  (slope of TVC)
# Average var. cost    AVC(q) = alpha - beta*q + gamma*q^2      (TVC / q)
# Average total cost   ATC(q) = AVC(q) + FC / q
# MC first falls (early units get cheaper as work is organised better), then
# rises steeply (the plant gets crowded). MC cuts AVC at the lowest AVC.
check_cubic_params <- function(alpha, beta, gamma) {
  check_firm_number(alpha, "alpha")
  check_firm_number(beta, "beta")
  check_firm_number(gamma, "gamma")
  if (alpha <= 0 || beta <= 0 || gamma <= 0) {
    stop("'alpha', 'beta' and 'gamma' must all be positive.", call. = FALSE)
  }
  # The lowest MC is alpha - beta^2 / (3*gamma); it must stay above zero,
  # otherwise some units would have a negative cost.
  if (beta^2 >= 3 * alpha * gamma) {
    stop("With these 'alpha', 'beta', 'gamma' marginal cost would become ",
         "zero or negative; need beta^2 < 3 * alpha * gamma.", call. = FALSE)
  }
  invisible(TRUE)
}

# All cost curves at the quantities q (q can be a vector, e.g. for plotting).
# ATC is not defined at q = 0 (fixed cost spread over zero units): NA there.
firm_cubic_cost <- function(q, FC = 0, alpha = 6, beta = 1, gamma = 1/12) {
  check_cubic_params(alpha, beta, gamma)
  if (!is.numeric(q) || any(is.na(q)) || any(q < 0)) {
    stop("'q' must contain non-negative numbers only.", call. = FALSE)
  }
  check_firm_number(FC, "FC", min = 0, what = "a fixed cost cannot be negative")
  TVC <- alpha * q - beta * q^2 + gamma * q^3
  MC  <- alpha - 2 * beta * q + 3 * gamma * q^2
  AVC <- alpha - beta * q + gamma * q^2        # at q = 0 this is the limit, alpha
  ATC <- ifelse(q > 0, AVC + FC / pmax(q, 1e-12), NA)
  list(q = q, TVC = TVC, MC = MC, AVC = AVC, ATC = ATC, TC = TVC + FC)
}

firm_cubic_outcomes <- function(P = 8, FC = 10, alpha = 6, beta = 1,
                                gamma = 1/12) {
  check_cubic_params(alpha, beta, gamma)
  check_firm_number(P, "P", min = 0, what = "a price cannot be negative")
  check_firm_number(FC, "FC", min = 0, what = "a fixed cost cannot be negative")

  # Lowest AVC: set the slope of AVC (-beta + 2*gamma*q) to zero
  q_min_avc <- beta / (2 * gamma)
  min_avc   <- alpha - beta^2 / (4 * gamma)   # the SHUTDOWN PRICE
  # Lowest MC (bottom of the U)
  q_min_mc <- beta / (3 * gamma)
  min_mc   <- alpha - beta^2 / (3 * gamma)

  # Best quantity: P* = MC(q) is a quadratic equation in q,
  #   3*gamma*q^2 - 2*beta*q + (alpha - P) = 0.
  # It has two roots; the firm wants the LARGER one, on the rising part of MC
  # (at the smaller root MC is falling, so producing more would still pay).
  # Shutdown rule: if P* is below the lowest AVC, the price does not even
  # cover the variable cost of any output level: produce nothing (Q* = 0) and
  # lose only the fixed cost. (P* >= min AVC > min MC also guarantees that
  # the square root below is of a positive number.)
  shutdown <- P < min_avc
  if (shutdown) {
    Q_star <- 0
  } else {
    disc   <- 4 * beta^2 - 12 * gamma * (alpha - P)
    Q_star <- (2 * beta + sqrt(disc)) / (6 * gamma)
  }

  cost <- firm_cubic_cost(Q_star, FC, alpha, beta, gamma)
  TR  <- P * Q_star
  TVC <- cost$TVC
  PS  <- TR - TVC + 0
  profit <- PS - FC                       # = TR - TVC - FC = TR - TC
  ATC_star <- if (Q_star > 0) cost$ATC else NA
  AVC_star <- if (Q_star > 0) cost$AVC else NA
  list(
    P = P, Q_star = Q_star, TR = TR, TVC = TVC, FC = FC, TC = TVC + FC,
    PS = PS, profit = profit,
    AVC_star = AVC_star, ATC_star = ATC_star,
    # Profit drawn as a rectangle: height (P* - ATC) times width Q*
    profit_rect = if (Q_star > 0) (P - ATC_star) * Q_star else -FC,
    MC_star = if (Q_star > 0) cost$MC else NA,
    q_min_avc = q_min_avc, min_avc = min_avc,
    q_min_mc = q_min_mc, min_mc = min_mc,
    shutdown = shutdown
  )
}


### 8. Small drawing helpers for the firm diagrams ----
firm_fill <- function(col, alpha = 0.45) adjustcolor(col, alpha.f = alpha)
firm_fmt  <- function(x) formatC(x, format = "f", digits = 2, drop0trailing = TRUE)

# Empty canvas with fixed axes. By default (n_legend = NULL, the app) the
# margins are the same in every step, so the plotting area does not jump when
# the app switches steps: the top margin always leaves room for a two-row
# legend (plus a title line if 'main' is given). With n_legend = a number
# (handout PNGs) the top margin only fits that many legend entries, see
# peib_top_margin(). With numbers = FALSE (steps 1 and 2, which are purely
# visual) there are no tick marks or numbers, only two axis lines with small
# arrowheads. tick_step: a numbered tick at every multiple of it (NULL = R's
# automatic axis numbers).
firm_canvas <- function(xlim, ylim, main, ylab = "Price (p) and cost (c)",
                        numbers = TRUE, tick_step = NULL, n_legend = NULL,
                        xlab = "Quantity (q)") {
  top <- peib_top_margin(main, n_legend, arrows = !numbers)
  par(mar = c(4.2, 4.2, top, 1), las = 1)
  plot(NA, xlim = xlim, ylim = ylim, xaxs = "i", yaxs = "i",
       axes = numbers && is.null(tick_step), bty = "l", ann = FALSE)
  if (numbers && !is.null(tick_step)) peib_axes(xlim, ylim, tick_step)
  # Without tick numbers the axis titles sit closer to the axes
  title(xlab = xlab, ylab = ylab, cex.lab = 1.05,
        line = if (numbers) 3 else 1.5)
  if (!numbers) {
    # xpd = NA lets the arrowheads poke out of the plotting box a little
    arrows(xlim[1], ylim[1], xlim[2] + 0.03 * diff(xlim), ylim[1],
           length = 0.09, lwd = 1.3, xpd = NA)
    arrows(xlim[1], ylim[1], xlim[1], ylim[2] + 0.05 * diff(ylim),
           length = 0.09, lwd = 1.3, xpd = NA)
  }
  if (!is.null(main)) title(main = main, line = top - 1.4)
  clip(xlim[1], xlim[2], ylim[1], ylim[2])
}

# Width and height of a text label in axis units (with a little padding)
firm_text_size <- function(txt, cex, font = 1) {
  c(w = strwidth(txt, cex = cex, font = font) * 1.08,
    h = strheight(txt, cex = cex, font = font) +
        0.45 * strheight("M", cex = cex, font = font))
}

# Where can a label go? firm_free_spot() searches a grid of possible label
# centres inside x_rng by y_rng and returns the free centre closest to
# (x_pref, y_pref), or NULL if there is none. A centre is free if
#   - no curve passes through the label (curves(x) returns a list of curve
#     heights at the points x; a curve crosses the label if its lowest point
#     over the label's width is below the label's top and its highest point
#     is above the label's bottom),
#   - the label does not overlap a box in 'avoid' (a list of c(l, r, b, t)),
#   - ok(x, y) is TRUE (e.g. "the label lies above the MC line").
# This lets every label find a readable place for any slider values.
firm_free_spot <- function(size, x_rng, y_rng, x_pref, y_pref, curves,
                           avoid = list(), ok = function(x, y) TRUE) {
  w <- size[["w"]]; h <- size[["h"]]
  usr <- par("usr")       # labels must stay inside the plotting box
  x_rng <- c(max(x_rng[1], usr[1] + 0.005 * (usr[2] - usr[1])),
             min(x_rng[2], usr[2] - 0.005 * (usr[2] - usr[1])))
  y_rng <- c(max(y_rng[1], usr[3] + 0.005 * (usr[4] - usr[3])),
             min(y_rng[2], usr[4] - 0.005 * (usr[4] - usr[3])))
  if (diff(x_rng) < w || diff(y_rng) < h) return(NULL)
  g <- expand.grid(x = seq(x_rng[1] + w / 2, x_rng[2] - w / 2, length.out = 41),
                   y = seq(y_rng[1] + h / 2, y_rng[2] - h / 2, length.out = 31))
  # Distances are measured in shares of the axis ranges
  dist <- ((g$x - x_pref) / (usr[2] - usr[1]))^2 +
          ((g$y - y_pref) / (usr[4] - usr[3]))^2
  for (i in order(dist)) {
    x <- g$x[i]; y <- g$y[i]
    l <- x - w / 2; r <- x + w / 2; b <- y - h / 2; t <- y + h / 2
    hit <- FALSE
    for (cv in curves(seq(l, r, length.out = 25))) {
      cv <- cv[is.finite(cv)]
      if (length(cv) > 0 && max(cv) >= b && min(cv) <= t) { hit <- TRUE; break }
    }
    if (hit) next
    for (a in avoid) {
      if (l < a[["r"]] && r > a[["l"]] && b < a[["t"]] && t > a[["b"]]) {
        hit <- TRUE; break
      }
    }
    if (!hit && ok(x, y)) return(c(x = x, y = y))
  }
  NULL
}

# Draw a label at the free spot closest to (x_pref, y_pref), if there is one.
# Returns the label's box c(l, r, b, t), so later labels can avoid it, or
# NULL if the label did not fit anywhere (then nothing is drawn).
firm_place_label <- function(txt, x_rng, y_rng, x_pref, y_pref, curves,
                             avoid = list(), ok = function(x, y) TRUE,
                             cex = 0.95, font = 2, col = "black") {
  size <- firm_text_size(txt, cex, font)
  s <- firm_free_spot(size, x_rng, y_rng, x_pref, y_pref, curves, avoid, ok)
  if (is.null(s)) return(NULL)
  text(s[["x"]], s[["y"]], txt, cex = cex, font = font, col = col)
  c(l = s[["x"]] - size[["w"]] / 2, r = s[["x"]] + size[["w"]] / 2,
    b = s[["y"]] - size[["h"]] / 2, t = s[["y"]] + size[["h"]] / 2)
}

# Add a box to a list of boxes to avoid (NULL = nothing was drawn)
firm_add_box <- function(boxes, box) if (is.null(box)) boxes else c(boxes, list(box))

# Label a curve y = f(x): walk from the right and take the first point that
# lies comfortably inside the box (between 6% and 94% of the height); put the
# text on 'side' (2 = left of the point, 3 = above, 4 = right).
firm_label_curve <- function(f, txt, col, xlim, ylim, side = 2,
                             x_max = xlim[2], cex = 1) {
  xs <- seq(x_max, xlim[1] + 0.02 * diff(xlim), length.out = 400)
  ys <- f(xs)
  ok <- which(!is.na(ys) & ys >= ylim[1] + 0.06 * diff(ylim) &
                ys <= ylim[2] - 0.06 * diff(ylim))
  if (length(ok) == 0) return(invisible(NULL))
  text(xs[ok[1]], ys[ok[1]], txt, col = col, font = 2, cex = cex, pos = side,
       offset = 0.5)
}

# A straight supply (= marginal cost) line p = a0 + slope * q. It is drawn
# inside the positive quadrant and stops a little before the top (or the
# right) edge of the box, with its label just above its end, as in textbook
# diagrams. Returns the label's box (for firm_free_spot), or NULL.
firm_supply_line <- function(a0, slope, label, xlim, ylim, lty = 1,
                             col = peib_cols["supply"], cex = 1) {
  x0 <- max(xlim[1], (ylim[1] - a0) / slope)    # start: q = 0, or where p = 0
  x1 <- min(xlim[1] + 0.92 * diff(xlim),
            (ylim[1] + 0.88 * diff(ylim) - a0) / slope)    # end
  if (x1 <= x0) return(invisible(NULL))         # the line misses the box
  y0 <- a0 + slope * x0; y1 <- a0 + slope * x1
  segments(x0, y0, x1, y1, col = col, lwd = 2.5, lty = lty)
  if (is.null(label)) return(invisible(NULL))
  # Centred above the end of the line, moved left if it would be cut off
  hw <- strwidth(label, cex = cex, font = 2) / 2
  xl <- min(max(x1, xlim[1] + hw), xlim[2] - hw - 0.01 * diff(xlim))
  text(xl, y1, label, col = col, font = 2, cex = cex, pos = 3, offset = 0.4)
  hh <- strheight(label, cex = cex, font = 2)
  oy <- 0.4 * strheight("M", cex = cex)          # (approximately the offset)
  invisible(c(l = xl - hw, r = xl + hw, b = y1 + oy * 0.5,
              t = y1 + oy + hh * 1.3))
}

# White box with a message in the upper part of the chart
firm_message <- function(msg, xlim, ylim, y_frac = 0.78, cex = 0.85,
                         x_frac = 0.5) {
  mx <- xlim[1] + x_frac * diff(xlim); my <- ylim[1] + y_frac * diff(ylim)
  w <- strwidth(msg, cex = cex) / 2 + 0.02 * diff(xlim)
  h <- strheight(msg, cex = cex) / 2 + 0.03 * diff(ylim)
  rect(mx - w, my - h, mx + w, my + h, col = "white", border = "grey60")
  text(mx, my, msg, cex = cex, col = "grey20")
}

# Legend in the top margin. 'fills' for areas; 'borders' allows outline-only
# boxes (fill NA); 'density' (a number per entry, NA_real_ = solid) draws
# hatched boxes. (Careful: a plain logical density = NA would make R draw the
# outline-only boxes black, hence the default NULL.) With 'lty' the entries
# are drawn as lines instead of boxes.
firm_legend <- function(items, fills, xlim, ylim, borders = NA, lty = NULL,
                        lwd = NULL, line_cols = NULL, density = NULL) {
  if (length(items) == 0) return(invisible(NULL))
  do.call("clip", as.list(par("usr")))
  # Two columns, each as wide as the longest entry. On a narrow screen (a
  # phone) shrink the text until both columns fit across the plot.
  cex  <- 0.8
  need <- function(cx) 2 * (max(strwidth(items, cex = cx)) +
                              2.5 * strwidth("M", cex = cx))
  avail <- diff(xlim)             # the width of the plotting box
  if (need(cex) > avail) cex <- max(0.55, cex * avail / need(cex))
  tw <- max(strwidth(items, cex = cex))
  if (is.null(lty)) {
    legend(x = mean(xlim), y = ylim[2], xjust = 0.5, yjust = 0, xpd = NA,
           legend = items, fill = fills, border = borders, bty = "n",
           density = density, angle = 45,
           ncol = 2, cex = cex, x.intersp = 0.6, text.width = tw)
  } else {
    legend(x = mean(xlim), y = ylim[2], xjust = 0.5, yjust = 0, xpd = NA,
           legend = items, col = line_cols, lty = lty, lwd = lwd, bty = "n",
           ncol = 2, cex = cex, x.intersp = 0.6, seg.len = 2.5,
           text.width = tw)
  }
}

# Horizontal market price line p* with its label at the left, just above the
# line (or just below it, if 'below' is TRUE). 'name' is the price's symbol
# ("P*" in the market figures); side = "right" puts the label at the right
# end of the line instead. Returns the label's box.
firm_price_line <- function(P, xlim, ylim, below = FALSE, name = "p*",
                            side = "left") {
  if (P > ylim[2]) return(invisible(NULL))
  abline(h = P, col = "grey20", lwd = 2)
  # The label sits on a white box so that curves crossing it do not make it
  # unreadable.
  lab <- paste0(name, " = ", firm_fmt(P), " (market price)")
  w  <- strwidth(lab, cex = 0.8) * 1.04; h <- strheight(lab, cex = 0.8) * 1.5
  x0 <- if (side == "right") xlim[2] - 0.01 * diff(xlim) - w
        else xlim[1] + 0.01 * diff(xlim)
  y0 <- if (below) P - 0.012 * diff(ylim) - h else P + 0.012 * diff(ylim)
  # The box reaches down (or up) to the price line, so that no curve shows
  # through the small gap where the descenders of "p" sit.
  e <- 0.005 * diff(ylim)
  rect(x0, if (below) y0 else P + e, x0 + w, if (below) P - e else y0 + h,
       col = "white", border = NA)
  text(x0, y0, lab, adj = c(0, -0.2), cex = 0.8)
  invisible(c(l = x0, r = x0 + w, b = y0, t = y0 + h))
}

# Vertical dashed guide at q* with its value written just above the q axis,
# 'dx' (a share of the q axis) to the right of the guide. Returns the label's
# box.
firm_qstar_guide <- function(Q, P, xlim, ylim, name = "q*", dx = 0.01) {
  if (Q <= 0) return(invisible(NULL))
  segments(Q, 0, Q, P, lty = 2, col = "grey30")
  # Right of the guide line, or left of it when Q is close to the right edge
  right <- Q < xlim[2] - 0.12 * diff(xlim)
  lab <- paste0(name, " = ", firm_fmt(Q))
  x0 <- Q + (if (right) dx else -0.01) * diff(xlim)
  y0 <- ylim[1] + 0.02 * diff(ylim)
  text(x0, y0, lab, adj = c(if (right) 0 else 1, 0), cex = 0.8)
  points(Q, P, pch = 19, cex = 0.9)
  w <- strwidth(lab, cex = 0.8); h <- strheight(lab, cex = 0.8) * 1.3
  invisible(c(l = if (right) x0 else x0 - w, r = if (right) x0 + w else x0,
              b = y0, t = y0 + h))
}

# Square bracket (style "bracket") or curly brace (style "brace") just right
# of x_edge, from y0 up to y1, with a label to its right (at the free spot
# closest to the middle, or on a white box at the bracket if there is no free
# spot, e.g. when x_edge is close to the right edge). The brace is used when
# the ends lie on other lines (the q axis, the price line), where the arms of
# a square bracket would be hidden. Used for "TR = PS + TVC" (step 5a, brace)
# and "PS = Profit + FC" (step 6b, bracket). Returns the label's box.
firm_bracket <- function(x_edge, y0, y1, lab, xlim, ylim, curves,
                         avoid = list(), cex = 0.8, style = "bracket") {
  rx <- diff(xlim); ry <- diff(ylim)
  pad_x <- 0.015 * rx; pad_y <- 0.02 * ry
  xb <- x_edge + 0.012 * rx; bw <- 0.012 * rx; ym <- (y0 + y1) / 2
  if (style == "brace") {
    # Four quarter-ellipse curls joined by two straight pieces: from the
    # bottom end, out to the middle of the brace's width, up, out to the tip
    # at mid-height, and the same mirrored above
    w  <- 2 * bw
    r  <- min(0.03 * ry, (y1 - y0) / 4)
    th <- seq(0, pi / 2, length.out = 20)
    lo_x <- c(xb + w / 2 * sin(th), xb + w - w / 2 * cos(th))
    lo_y <- c(y0 + r - r * cos(th), ym - r + r * sin(th))
    lines(c(lo_x, rev(lo_x)), c(lo_y, rev(2 * ym - lo_y)), lwd = 1.8,
          col = "grey15")
  } else {
    segments(c(xb, xb + bw, xb), c(y0, y0, y1),
             c(xb + bw, xb + bw, xb + bw), c(y0, y1, y1),
             lwd = 1.8, col = "grey15")
  }
  sz <- firm_text_size(lab, cex, 2)
  xl <- xb + 2 * bw + (if (style == "brace") 0.005 * rx else 0)
  b <- firm_place_label(lab, c(xl, xlim[2] - pad_x),
                        c(max(ylim[1] + pad_y, min(y0, ym - sz[["h"]])),
                          min(ylim[2] - pad_y, max(y1, ym + sz[["h"]]))),
                        xl + sz[["w"]] / 2, ym, curves, avoid, cex = cex)
  if (is.null(b)) {
    x <- min(xl + sz[["w"]] / 2, xlim[2] - pad_x - sz[["w"]] / 2)
    b <- c(l = x - sz[["w"]] / 2, r = x + sz[["w"]] / 2,
           b = ym - sz[["h"]] / 2, t = ym + sz[["h"]] / 2)
    rect(b[["l"]], b[["b"]], b[["r"]], b[["t"]],
         col = adjustcolor("white", 0.85), border = NA)
    text(x, ym, lab, cex = cex, font = 2)
  }
  invisible(b)
}


### 9. draw_firm_step(): the step-by-step diagram, one function for all ----
# step "1":  the supply curve S                       (uses c, d)
# step "2":  shifts in supply: S moves right/left     (+ shift, in units of q;
#            one or two numbers, positive = increase in supply, e.g. c(2, -2))
# step "3":  market price p*, quantity q*, total revenue TR = p* x q*  (+ P)
# step "4":  total variable cost TVC = area under MC up to q*
# step "5a": producer surplus PS = TR - TVC
# step "5b": producer surplus, one unit at a time     (+ q_unit)
# step "6a": U-shaped costs; TVC and PS as areas      (P, FC, alpha, beta, gamma)
# step "6b": U-shaped costs; TR split into the rectangles TVC, FC and profit
# Steps 1 and 2 have no numbers on the axes (purely visual); from step 3 on
# the supply curve is also the marginal cost curve, "S = MC".
# Layout options: tick_step (e.g. 1) puts a numbered tick at every multiple
# of it on both axes from step 3 on (NULL = R's automatic axis numbers, for
# the app at phone width); fit_top = TRUE shrinks the top margin to the
# legend actually shown (handout PNGs without titles), while the default
# FALSE keeps the same margins in every step (the app).
# q (step 5a only, optional): the quantity the firm actually produces. NULL
# (the default, used by the handout PNGs) means q*, and the figure is the
# usual one. A q above q* adds the loss on the extra units (MC > p*, red); a
# q below q* shows the surplus forgone on the units from q to q* that are
# not produced (hatched). Used by the website app for the question "what if
# the firm produces q = 8 instead of q* = 6?".
# Returns the outcomes invisibly: firm_linear_outcomes() for steps 3-5b
# (in step 5a at the quantity q, if given), firm_cubic_outcomes() for steps
# 6a and 6b, list(c, d, shift) for 1 and 2.
firm_steps <- c("1", "2", "3", "4", "5a", "5b", "6a", "6b")

draw_firm_step <- function(step = "1", c = 2, d = 1, shift = c(2, -2), P = 8,
                           q_unit = 3, FC = 10,
                           alpha = 6, beta = 1, gamma = 1/12,
                           xlim = c(0, 20), ylim = c(0, 20), main = NULL,
                           tick_step = NULL, fit_top = FALSE, q = NULL) {
  step <- as.character(step)
  if (length(step) != 1 || !(step %in% firm_steps)) {
    stop("'step' must be one of ", paste(firm_steps, collapse = ", "), ".",
         call. = FALSE)
  }
  if (!is.null(q)) check_firm_number(q, "q", min = 0,
                                     what = "a quantity cannot be negative")
  op <- par(c("mar", "las"))  # firm_canvas() changes these two settings;
  on.exit(par(op))            # restore them when we finish
  if (step %in% c("6a", "6b")) {
    out <- draw_firm_cubic(P, FC, alpha, beta, gamma, xlim, ylim, main,
                           version = if (step == "6a") "areas" else "rectangles",
                           tick_step = tick_step, fit_top = fit_top)
  } else if (step %in% c("1", "2")) {
    out <- draw_firm_supply(step, c, d, shift, xlim, ylim, main,
                            fit_top = fit_top)
  } else {
    out <- draw_firm_linear(step, c, d, P, q_unit, xlim, ylim, main,
                            tick_step = tick_step, fit_top = fit_top, q = q)
  }
  invisible(out)
}

# Steps 1 and 2 (called by draw_firm_step): the supply curve and its shifts
draw_firm_supply <- function(step, c, d, shift, xlim, ylim, main,
                             fit_top = FALSE) {
  check_firm_number(c, "c")
  check_firm_number(d, "d")
  if (d <= 0) stop("Slope 'd' must be positive (supply slopes up).",
                   call. = FALSE)
  if (step == "2" && (!is.numeric(shift) || length(shift) < 1 ||
                      length(shift) > 2 || any(is.na(shift)))) {
    stop("'shift' must be one or two numbers of units, e.g. 2 or c(2, -2).",
         call. = FALSE)
  }
  rx <- diff(xlim); ry <- diff(ylim)
  firm_canvas(xlim, ylim, main, ylab = "Price (p)", numbers = FALSE,
              n_legend = if (fit_top) 0 else NULL)

  if (step == "1") {
    firm_supply_line(c, d, "S", xlim, ylim)
    return(list(c = c, d = d, shift = 0))
  }

  # Step 2: the whole curve moves sideways along the quantity axis
  # A shift by s units: at every price, sellers offer s more units (s > 0,
  # "increase in supply", curve moves right) or s fewer (s < 0, "decrease",
  # curve moves left). New curve: p = c + d * (q - s).
  shifts <- shift[shift != 0]
  firm_supply_line(c, d, "S0", xlim, ylim)
  for (i in seq_along(shifts)) {
    firm_supply_line(c - d * shifts[i], d, paste0("S", i), xlim, ylim, lty = 2)
  }
  if (length(shifts) == 0) return(list(c = c, d = d, shift = shift))

  # Arrows at one price level, about 57% up the price axis, moved if needed
  # so that both arrows stay inside the box.
  s_right <- max(0, shifts); s_left <- max(0, -shifts)
  lo <- c + d * (xlim[1] + s_left + 0.12 * rx)
  hi <- min(ylim[1] + 0.8 * ry, c + d * (xlim[1] + 0.8 * rx - s_right))
  p_arr <- min(max(round(ylim[1] + 0.57 * ry), lo), hi)
  x_s0  <- (p_arr - c) / d          # where S0 is at that price
  gap   <- 0.012 * rx
  for (s in shifts) {
    x_tip <- x_s0 + s
    if (abs(s) > 2.5 * gap) {
      arrows(x_s0 + sign(s) * gap, p_arr, x_tip - sign(s) * gap, p_arr,
             length = 0.09, lwd = 1.8, col = "grey20")
    }
    # The label goes on the far side of the new curve, at the arrow tip:
    # below-right of a curve that moved right, above-left of one that moved
    # left. As the curves slope up, both places are always empty.
    if (x_tip <= xlim[1] || x_tip >= xlim[2]) next   # tip outside the box
    lab <- if (s > 0) "Increase\nin supply" else "Decrease\nin supply"
    w <- strwidth(lab, cex = 0.8)
    if (s > 0) {
      x <- min(x_tip + 0.03 * rx, xlim[2] - 0.01 * rx - w)
      text(x, p_arr - 0.045 * ry, lab, adj = c(0, 1), cex = 0.8)
    } else {
      x <- max(x_tip - 0.03 * rx, xlim[1] + 0.01 * rx + w)
      text(x, p_arr + 0.045 * ry, lab, adj = c(1, 0), cex = 0.8)
    }
  }
  list(c = c, d = d, shift = shift)
}

# Steps 3, 4, 5a and 5b (called by draw_firm_step): straight-line MC.
# q: step 5a only, the quantity actually produced (NULL = q*), see
# draw_firm_step(). Everything that q adds sits in "if (has_q)" blocks, so
# with q = NULL the figure is exactly the same as before q existed.
draw_firm_linear <- function(step, c, d, P, q_unit, xlim, ylim, main,
                             tick_step = NULL, fit_top = FALSE, q = NULL) {
  q_5a <- if (step == "5a") q else NULL
  out <- firm_linear_outcomes(c = c, d = d, P = P, q = q_5a, q_unit = q_unit)
  mc <- function(x) c + d * x
  Qs <- out$Q_star
  rx <- diff(xlim); ry <- diff(ylim)
  pad_x <- 0.015 * rx; pad_y <- 0.02 * ry
  # Does the firm produce a quantity other than q*? (step 5a only)
  has_q <- !is.null(q_5a) && abs(q_5a - Qs) > 1e-9
  # PS and TVC are shaded from 0 to q_end: q* as usual, or q if the firm
  # stops before q* (the units from q to q* are not produced)
  q_end <- if (has_q && q_5a < Qs) q_5a else Qs

  # With fit_top, count the legend entries first (same rules as below: PS
  # and TVC in steps 5a and 5b, plus the two parts of the unit bar in 5b;
  # with q, the loss or forgone area, and TVC if q* = 0)
  n_leg <- NULL
  if (fit_top) {
    n_leg <- (if (Qs > 0 && step %in% c("5a", "5b")) 2 else 0) +
             (if (step == "5b") (if (mc(q_unit) != P) 2 else 1) else 0)
    if (has_q) n_leg <- n_leg + 1 + (if (Qs <= 0) 1 else 0)
  }
  firm_canvas(xlim, ylim, main, tick_step = tick_step, n_legend = n_leg)
  items <- character(0); fills <- character(0); borders <- character(0)
  dens <- numeric(0)          # hatching density per legend entry (NA = solid)
  add <- function(label, col, border = NA, density = NA_real_) {
    items <<- c(items, label); fills <<- c(fills, col)
    borders <<- c(borders, border); dens <<- c(dens, density)
  }
  # Labels must not cross the MC line or the price line
  curves <- function(x) list(mc(x), rep(P, length(x)))
  above_mc <- function(x, y) y > mc(x)
  below_mc <- function(x, y) y < mc(x)
  # Shaded areas are lighter in step 5b, so the single unit stands out
  a_area <- if (step == "5b") 0.2 else 0.45

  # Shaded areas first (lines go on top)
  xs <- seq(0, max(q_end, 0), length.out = 101)
  m  <- pmax(0, mc(xs))            # MC, cut at zero (no negative costs drawn)
  if (Qs > 0) {
    if (step == "3") {
      # Total revenue: price x quantity, a rectangle
      rect(0, 0, Qs, P, col = firm_fill(peib_cols["tr"], 0.3),
           border = peib_cols["tr"], lwd = 1.5)
    }
    if (step %in% c("4", "5a", "5b")) {
      # Total variable cost: the area under MC from 0 to q*
      polygon(c(0, xs, q_end), c(0, m, 0),
              col = firm_fill(peib_cols["tvc"], a_area), border = NA)
    }
    if (step %in% c("5a", "5b")) {
      # Producer surplus: the area between the price line and MC
      polygon(c(xs, rev(xs)), c(rep(P, length(xs)), rev(m)),
              col = firm_fill(peib_cols["ps"], a_area), border = NA)
      add("Producer surplus (PS)", firm_fill(peib_cols["ps"], a_area))
      add("Total variable cost (TVC)", firm_fill(peib_cols["tvc"], a_area))
    }
  }

  # Step 5a with a quantity q other than q*
  if (has_q && q_5a > Qs) {
    # Units beyond q* cost more than they earn (MC > p*). Revenue covers the
    # part of their cost below p* (TVC, purple); the part above p* is a loss
    # (red): profit falls by this triangle.
    xl <- seq(Qs, q_5a, length.out = 101)
    if (P > 0) rect(Qs, 0, q_5a, P, col = firm_fill(peib_cols["tvc"], a_area),
                    border = NA)
    polygon(c(xl, rev(xl)), c(pmax(mc(xl), P), rep(P, length(xl))),
            col = firm_fill(peib_cols["loss"], 0.6), border = NA)
    if (Qs <= 0) add("Total variable cost (TVC)",
                     firm_fill(peib_cols["tvc"], a_area))
    add("Loss on extra units (MC > p*)", firm_fill(peib_cols["loss"], 0.6))
  }
  if (has_q && q_5a < Qs) {
    # The units from q to q* are not produced: the surplus they would have
    # earned (between p* and MC) is forgone. Hatched, in the colour of PS.
    xf <- seq(q_5a, Qs, length.out = 101)
    polygon(c(xf, rev(xf)), c(rep(P, length(xf)), rev(pmax(0, mc(xf)))),
            col = peib_cols["ps"], border = peib_cols["ps"], density = 20,
            angle = 45)
    add("Forgone surplus (units not made)", peib_cols["ps"], peib_cols["ps"],
        density = 30)
  }

  # Step 5b: one unit, drawn as a thin bar
  # Its cost (purple, up to MC) and the surplus on it (orange, from MC up to
  # p*; red if MC is above p*, i.e. the unit loses money)
  avoid <- list()
  if (step == "5b") {
    w  <- 0.012 * rx
    uc <- mc(q_unit)
    nm <- firm_fmt(q_unit)
    rect(q_unit - w, 0, q_unit + w, max(0, min(uc, P)),
         col = firm_fill(peib_cols["tvc"], 0.9), border = NA)
    if (uc < P) {
      rect(q_unit - w, max(0, uc), q_unit + w, P,
           col = firm_fill(peib_cols["ps"], 0.95), border = NA)
      add(paste0("Surplus on unit ", nm, " (p* - MC)"),
          firm_fill(peib_cols["ps"], 0.95))
    } else if (uc > P) {
      rect(q_unit - w, P, q_unit + w, uc,
           col = firm_fill(peib_cols["loss"], 0.95), border = NA)
      add(paste0("Loss on unit ", nm, " (MC > p*)"),
          firm_fill(peib_cols["loss"], 0.95))
    }
    add(paste0("Cost of unit ", nm, " (its MC)"), firm_fill(peib_cols["tvc"], 0.9))
    avoid <- list(c(l = q_unit - w, r = q_unit + w, b = 0, t = max(uc, P)))
  }

  # The supply (= marginal cost) line, price line and q*
  avoid <- firm_add_box(avoid, firm_supply_line(c, d, "S = MC", xlim, ylim))
  # With q > q*, the red loss area lies just above the price line. If it
  # reaches under the price label (q* close to 0), the label goes below the
  # line, if there is room (as in the U-shaped cost figures).
  p_below <- FALSE
  if (has_q && q_5a > Qs) {
    lab_r <- xlim[1] + 0.01 * rx +
      1.04 * strwidth(paste0("p* = ", firm_fmt(P), " (market price)"), cex = 0.8)
    p_below <- Qs < lab_r && mc(min(q_5a, lab_r)) - P > 0.02 * ry &&
      P > ylim[1] + 0.1 * ry
  }
  avoid <- firm_add_box(avoid, firm_price_line(P, xlim, ylim, below = p_below))
  # (in step 5a the q* label moves right, to leave room for the brace)
  avoid <- firm_add_box(avoid, firm_qstar_guide(
    Qs, P, xlim, ylim, dx = if (step == "5a" && !has_q) 0.035 else 0.01))
  if (Qs > 0) avoid <- firm_add_box(avoid, c(l = Qs, r = Qs, b = 0, t = P))
  if (has_q) {
    # Dashed guide at the quantity produced, labelled just above the q axis
    # (on a second row if the first row is taken, e.g. by the q* label)
    top_q <- max(P, mc(q_5a))
    segments(q_5a, 0, q_5a, top_q, lty = 2, col = "grey30")
    avoid <- firm_add_box(avoid, c(l = q_5a, r = q_5a, b = 0, t = top_q))
    lab <- paste0("q = ", firm_fmt(q_5a))
    b <- peib_q_label(q_5a, lab, xlim, ylim, avoid)
    if (is.null(b)) {
      sz <- firm_text_size(lab, 0.8)
      b <- firm_place_label(lab, q_5a + c(-1, 1) * (sz[["w"]] + 0.02 * rx),
                            ylim[1] + c(0.06, 0.06 + 2.5 * sz[["h"]] / ry) * ry,
                            q_5a + 0.01 * rx + sz[["w"]] / 2,
                            ylim[1] + 0.06 * ry + sz[["h"]] / 2, curves, avoid,
                            cex = 0.8, font = 1)
    }
    avoid <- firm_add_box(avoid, b)
  }

  # Labels inside the areas (only where they fit)
  in_x <- c(xlim[1] + pad_x, Qs - pad_x)          # inside the areas: 0 to q*
  in_a <- c(xlim[1] + pad_x, q_end - pad_x)       # PS and TVC: 0 to q_end
  if (step == "3" && Qs > 0) {
    # Preferably in the upper-left part, above the MC line (the part below MC
    # becomes TVC in step 4); otherwise anywhere inside the rectangle
    lab <- "TR = p* x q*"
    sz  <- firm_text_size(lab, 0.9, 2)
    b <- firm_place_label(lab, in_x, c(ylim[1] + pad_y, P - pad_y),
                          xlim[1] + pad_x + sz[["w"]] / 2,
                          P - pad_y - sz[["h"]] / 2, curves, avoid,
                          ok = above_mc, cex = 0.9)
    if (is.null(b)) {
      b <- firm_place_label(lab, in_x, c(ylim[1] + pad_y, P - pad_y),
                            Qs / 2, 0.25 * P, curves, avoid, cex = 0.9)
    }
    if (is.null(b)) {          # too small to hold the label: use the legend
      add("Total revenue (TR = p* x q*)", firm_fill(peib_cols["tr"], 0.3),
          peib_cols["tr"])
    }
  }

  if (step %in% c("4", "5a") && Qs > 0) {
    b <- firm_place_label("TVC", in_a, c(ylim[1] + pad_y, P), q_end / 2,
                          0.4 * mc(q_end / 2), curves, avoid, ok = below_mc)
    if (is.null(b) && step == "4") {
      add("Total variable cost (TVC)", firm_fill(peib_cols["tvc"], a_area))
    }
    avoid <- firm_add_box(avoid, b)
  }
  if (step == "5a" && Qs > 0) {
    b <- firm_place_label("PS", in_a, c(ylim[1], P - pad_y), q_end / 3,
                          (max(0, mc(0)) + 2 * P) / 3, curves, avoid,
                          ok = above_mc)
    # Total revenue = the whole rectangle from 0 to p*: a brace on its right
    # edge (an outline would hide under the axes and guide lines). Only at
    # q = q*: with another q, TR is p* x q (see the app's table).
    if (!has_q) {
      firm_bracket(Qs, 0, P, "TR = PS + TVC", xlim, ylim, curves, avoid,
                   style = "brace")
    } else {
      avoid <- firm_add_box(avoid, b)
    }
  }
  if (has_q && q_5a > Qs) {
    # "Loss" inside the red triangle (left out if it does not fit)
    firm_place_label("Loss", c(Qs + pad_x, q_5a - pad_x),
                     c(P, min(mc(q_5a), ylim[2])), (Qs + 2 * q_5a) / 3,
                     (2 * P + min(mc(q_5a), ylim[2])) / 3, curves, avoid,
                     ok = function(x, y) y > P && y < mc(x), cex = 0.8)
  }

  if (step == "4") {
    # What MC means, written next to the line above the price line
    lab <- "MC = the cost of producing\none more unit"
    sz  <- firm_text_size(lab, 0.75)
    y_p <- P + 0.45 * (ylim[2] - P)
    firm_place_label(lab, c(xlim[1] + pad_x, xlim[2] - pad_x),
                     c(P + pad_y, ylim[2] - pad_y),
                     (y_p - sz[["h"]] / 2 - c) / d - sz[["w"]] / 2 - 0.005 * rx,
                     y_p, curves, avoid, ok = above_mc, cex = 0.75, font = 3,
                     col = "grey25")
  }

  if (step == "5b") {
    # Value labels right beside the bar, at mid-height of each part: left of
    # the bar if there is room (the MC line is lower there for the surplus
    # part and higher for the cost part), otherwise right of it; on two lines
    # if one line does not fit. If none fits, the label is left out (the
    # legend still names both parts).
    uc <- mc(q_unit); w <- 0.012 * rx
    bar_label <- function(lab, y_mid) {
      for (txt in c(lab, sub(" = ", "\n= ", lab, fixed = TRUE))) {
        sz <- firm_text_size(txt, 0.8, 2)
        y_rng <- y_mid + c(-1, 1) * sz[["h"]] * 0.7
        gap <- 0.01 * rx; reach <- sz[["w"]] + 0.03 * rx  # stay next to the bar
        b <- firm_place_label(txt, q_unit - w - gap - c(reach, 0), y_rng,
                              q_unit - w - gap - sz[["w"]] / 2, y_mid, curves,
                              avoid, cex = 0.8)
        if (is.null(b)) {
          b <- firm_place_label(txt, q_unit + w + gap + c(0, reach), y_rng,
                                q_unit + w + gap + sz[["w"]] / 2, y_mid, curves,
                                avoid, cex = 0.8)
        }
        if (!is.null(b)) return(b)
      }
      NULL
    }
    if (uc != P) {
      top <- min(max(uc, P), ylim[2]); bot <- max(min(uc, P), ylim[1])
      lab <- paste0(if (uc < P) "surplus = " else "loss = ", firm_fmt(abs(P - uc)))
      avoid <- firm_add_box(avoid, bar_label(lab, (top + bot) / 2))
    }
    if (min(uc, P) > 0) {
      avoid <- firm_add_box(avoid, bar_label(paste0("cost = ", firm_fmt(uc)),
                                             min(uc, P, ylim[2]) / 2))
    }
    if (Qs > 0) {
      # Area labels, preferably between the bar and q*
      x_r <- if (q_unit < Qs) (q_unit + Qs) / 2 else Qs / 2
      avoid <- firm_add_box(avoid, firm_place_label(
        "PS", in_x, c(ylim[1], P - pad_y), (2 * min(q_unit, Qs) + Qs) / 3,
        (mc(min(q_unit, Qs)) + 2 * P) / 3, curves, avoid, ok = above_mc))
      avoid <- firm_add_box(avoid, firm_place_label(
        "TVC", in_x, c(ylim[1] + pad_y, P), x_r, 0.45 * mc(x_r), curves,
        avoid, ok = below_mc))
      # The message of this step, above the price line on the left, i.e.
      # just above the PS area it describes
      lab <- "PS = the sum of the surpluses\non all units from 0 to q*"
      sz  <- firm_text_size(lab, 0.75, 3)
      firm_place_label(lab, c(xlim[1] + pad_x, xlim[2] - pad_x),
                       c(P + 0.1 * ry, ylim[2] - pad_y),
                       xlim[1] + pad_x + sz[["w"]] / 2,
                       P + 0.4 * (ylim[2] - P), curves, avoid,
                       ok = above_mc, cex = 0.75, font = 3, col = "grey25")
    }
  }

  if (out$no_production) {
    firm_message(paste0("No production: the market price (", firm_fmt(P),
                        ") is below\nthe cost of the first unit (",
                        firm_fmt(c), ")"), xlim, ylim)
  }

  # (density only if an entry is hatched; otherwise the same call as before)
  firm_legend(items, fills, xlim, ylim, borders = borders,
              density = if (any(!is.na(dens))) dens else NULL)
  out
}

# Steps 6a and 6b (called by draw_firm_step): U-shaped marginal cost.
# version "areas":      TVC = area under MC, PS = area between p* and MC
# version "rectangles": TR = p* x q* split into three stacked rectangles,
#                       TVC = AVC x q*, FC = (ATC - AVC) x q* and
#                       profit = (p* - ATC) x q*, so PS = profit + FC
draw_firm_cubic <- function(P, FC, alpha, beta, gamma, xlim, ylim, main,
                            version = "areas", tick_step = NULL,
                            fit_top = FALSE) {
  out <- firm_cubic_outcomes(P, FC, alpha, beta, gamma)
  Qs  <- out$Q_star
  cf  <- function(x) firm_cubic_cost(x, FC, alpha, beta, gamma)
  qq  <- seq(xlim[1] + 1e-3 * diff(xlim), xlim[2], length.out = 500)
  cc  <- cf(qq)
  rx <- diff(xlim); ry <- diff(ylim)
  pad_x <- 0.015 * rx; pad_y <- 0.02 * ry

  # Do the first units cost more than p*? (MC starts above the price; only
  # possible when p* is below MC at q = 0)
  xs <- seq(0, max(Qs, 0), length.out = 300)
  sliver <- Qs > 0 && any(cf(xs)$MC > P + 1e-9)
  # With fit_top, count the legend entries first (same rules as below)
  n_leg <- NULL
  if (fit_top) {
    n_leg <- if (Qs <= 0) 0 else if (version == "areas") 2 + sliver else 3
  }
  firm_canvas(xlim, ylim, main, tick_step = tick_step, n_legend = n_leg)
  items <- character(0); fills <- character(0); borders <- character(0)
  dens <- numeric(0)
  add <- function(label, col, border = NA, density = NA_real_) {
    items <<- c(items, label); fills <<- c(fills, col)
    borders <<- c(borders, border); dens <<- c(dens, density)
  }
  # Curves that labels must not cross, read off the grid above (approx()
  # interpolates between grid points; rule = 2 extends the end values)
  curves <- function(x) list(approx(qq, cc$MC,  x, rule = 2)$y,
                             approx(qq, cc$AVC, x, rule = 2)$y,
                             approx(qq, cc$ATC, x, rule = 2)$y,
                             rep(P, length(x)))
  mc_at <- function(x) approx(qq, cc$MC, x, rule = 2)$y
  is_profit <- TRUE

  # Shaded areas
  if (Qs > 0 && version == "areas") {
    m  <- cf(xs)$MC
    polygon(c(0, xs, Qs), c(0, m, 0), col = firm_fill(peib_cols["tvc"]),
            border = NA)
    polygon(c(xs, rev(xs)), c(rep(P, length(xs)), rev(pmin(m, P))),
            col = firm_fill(peib_cols["ps"]), border = NA)
    add("Producer surplus (PS)", firm_fill(peib_cols["ps"]))
    add("Total variable cost (TVC)", firm_fill(peib_cols["tvc"]))
    if (sliver) {
      # The first units cost more than the price (MC starts above p*): this
      # surplus is negative and is subtracted from PS. Hatched in red.
      polygon(c(xs, rev(xs)), c(pmax(m, P), rep(P, length(xs))),
              col = peib_cols["loss"], border = NA, density = 25, angle = 45)
      add("Loss on the first units (MC > p*)", peib_cols["loss"],
          peib_cols["loss"], density = 30)
    }
  }
  if (Qs > 0 && version == "rectangles") {
    avc <- out$AVC_star; atc <- out$ATC_star
    is_profit <- P >= atc
    rect(0, 0, Qs, avc, col = firm_fill(peib_cols["tvc"]), border = NA)
    rect(0, avc, Qs, atc, col = firm_fill(peib_cols["fc"], 0.7), border = NA)
    add("Total variable cost (TVC)", firm_fill(peib_cols["tvc"]))
    add("Fixed cost (FC)", firm_fill(peib_cols["fc"], 0.7))
    if (is_profit) {
      rect(0, atc, Qs, P, col = firm_fill(peib_cols["profit"], 0.7), border = NA)
      add("Profit", firm_fill(peib_cols["profit"], 0.7))
    } else {
      # Price below ATC: the top part of the fixed cost is not covered
      rect(0, P, Qs, atc, col = firm_fill(peib_cols["loss"], 0.75), border = NA)
      add("Loss", firm_fill(peib_cols["loss"], 0.75))
    }
  }

  # Curves: ATC, AVC, MC, and the supply curve (thick part of MC)
  lines(qq, cc$ATC, col = peib_cols["atc"], lwd = 2, lty = 4)
  lines(qq, cc$AVC, col = peib_cols["avc"], lwd = 2, lty = 2)
  lines(qq, cc$MC,  col = peib_cols["supply"], lwd = 1.5)
  on_supply <- qq >= out$q_min_avc
  lines(qq[on_supply], cc$MC[on_supply], col = peib_cols["supply"], lwd = 5)
  # The lowest point of AVC = shutdown price
  points(out$q_min_avc, out$min_avc, pch = 21, bg = "white",
         col = peib_cols["avc"], cex = 1.3, lwd = 2)
  if (Qs > 0 && version == "rectangles") {
    # The heights of the rectangles are read off the curves at q*
    points(c(Qs, Qs), c(out$AVC_star, out$ATC_star), pch = 19, cex = 0.6)
  }
  avoid <- list()

  # "Firm supply curve" label with an arrow to the thick part of MC
  y_arr <- out$min_avc + 0.55 * (ylim[2] - out$min_avc)
  disc  <- 4 * beta^2 - 12 * gamma * (alpha - y_arr)
  if (disc > 0) {
    x_arr <- (2 * beta + sqrt(disc)) / (6 * gamma)
    if (x_arr < xlim[2]) {
      x_txt <- x_arr - 0.30 * rx; y_txt <- y_arr + 0.12 * ry
      arrows(x_txt + 0.06 * rx, y_txt - 0.03 * ry,
             x_arr - 0.012 * rx, y_arr, length = 0.08, col = "grey20")
      lab <- "Firm supply curve\n(MC above lowest AVC)"
      text(x_txt, y_txt, lab, cex = 0.8, font = 2, col = peib_cols["supply"],
           adj = c(0.5, 0))
      sz <- firm_text_size(lab, 0.8, 2)
      avoid <- firm_add_box(avoid, c(l = x_txt - sz[["w"]] / 2,
                                     r = x_txt + sz[["w"]] / 2,
                                     b = y_txt, t = y_txt + sz[["h"]]))
    }
  }

  # Curve labels. AVC: at its right-hand end, BELOW the curve. ATC: high up
  # on the left, to the right of its falling part (the right-hand end is
  # kept free for the PS label of version "rectangles"), at the first height
  # where it does not overlap the "Firm supply curve" label. MC: near the top.
  xr <- xlim[2] - 0.02 * rx
  y_avc <- cf(xr)$AVC
  avc_lab <- if (FC > 0) "AVC" else "AVC = ATC"
  if (y_avc > ylim[1] && y_avc < ylim[2] - 0.04 * ry) {
    # The label's top sits a little below the curve at the label's LEFT end
    # (AVC rises to the right, so that is where the curve is lowest)
    ww <- strwidth(avc_lab, cex = 0.9, font = 2)
    hh <- strheight(avc_lab, cex = 0.9, font = 2)
    y_top <- min(y_avc, cf(xr - ww)$AVC) - 0.5 * hh
    text(xr, y_top, avc_lab, col = peib_cols["avc"], font = 2, cex = 0.9,
         adj = c(1, 1))
    avoid <- firm_add_box(avoid, c(l = xr - ww, r = xr, b = y_top - 1.2 * hh,
                                   t = y_top))
  }
  if (FC > 0) {
    sz <- firm_text_size("ATC", 0.9, 2)
    for (f in c(0.85, 0.75, 0.65, 0.92)) {
      y_atc <- ylim[1] + f * ry
      i <- which(cc$ATC <= y_atc)[1]       # first point below that height
      if (is.na(i) || qq[i] >= out$q_min_avc) next
      x_l <- qq[i] + 0.4 * strwidth("M", cex = 0.9)
      box <- c(l = x_l, r = x_l + sz[["w"]], b = y_atc - sz[["h"]] / 2,
               t = y_atc + sz[["h"]] / 2)
      clash <- any(vapply(avoid, function(a) box[["l"]] < a[["r"]] &&
                            box[["r"]] > a[["l"]] && box[["b"]] < a[["t"]] &&
                            box[["t"]] > a[["b"]], logical(1)))
      if (!clash) {
        text(qq[i], y_atc, "ATC", col = peib_cols["atc"], font = 2, cex = 0.9,
             pos = 4, offset = 0.4)
        avoid <- firm_add_box(avoid, box)
        break
      }
    }
  }
  firm_label_curve(function(x) cf(pmax(x, out$q_min_avc))$MC, "MC",
                   peib_cols["supply"], xlim, ylim, side = 2)

  # Price, q*, shutdown price
  # If a red area lies just ABOVE the price line (a loss), the price label
  # goes below the line to keep that area visible.
  below <- sliver || (Qs > 0 && version == "rectangles" && !is_profit)
  avoid <- firm_add_box(avoid, firm_price_line(P, xlim, ylim, below = below))
  # Below and to the right of the lowest AVC point (MC is above it there)
  lab <- paste0("lowest AVC = ", firm_fmt(out$min_avc), "\n(shutdown price)")
  x0 <- out$q_min_avc + 0.015 * rx; y0 <- out$min_avc - 0.025 * ry
  text(x0, y0, lab, adj = c(0, 1), cex = 0.75, col = peib_cols["avc"])
  sz <- firm_text_size(lab, 0.75)
  avoid <- firm_add_box(avoid, c(l = x0, r = x0 + sz[["w"]],
                                 b = y0 - sz[["h"]], t = y0))
  if (Qs > 0) {
    # The q* label normally sits just right of the q* guide (as drawn by
    # firm_qstar_guide). On wider axes (the app) it can run into the shutdown
    # price label; only then it moves to the nearest free spot just above
    # the q axis. (The box below is the one firm_qstar_guide would use.)
    lab_q <- paste0("q* = ", firm_fmt(Qs))
    right <- Qs < xlim[2] - 0.12 * rx
    w_q <- strwidth(lab_q, cex = 0.8); h_q <- strheight(lab_q, cex = 0.8) * 1.3
    x_q <- Qs + (if (right) 0.01 else -0.01) * rx; y_q <- ylim[1] + 0.02 * ry
    box_q <- c(l = if (right) x_q else x_q - w_q, r = if (right) x_q + w_q else x_q,
               b = y_q, t = y_q + h_q)
    if (!peib_overlaps(box_q, avoid)) {
      avoid <- firm_add_box(avoid, firm_qstar_guide(Qs, P, xlim, ylim))
    } else {
      segments(Qs, 0, Qs, P, lty = 2, col = "grey30")
      points(Qs, P, pch = 19, cex = 0.9)
      avoid <- firm_add_box(avoid, c(l = Qs, r = Qs, b = ylim[1], t = P))
      sz <- firm_text_size(lab_q, 0.8)
      avoid <- firm_add_box(avoid, firm_place_label(
        lab_q, Qs + c(-3, 3) * sz[["w"]], c(ylim[1], ylim[1] + 0.15 * ry),
        Qs + 0.01 * rx + sz[["w"]] / 2, y_q + sz[["h"]] / 2, curves, avoid,
        cex = 0.8, font = 1))
    }
  } else {
    # Placed left of centre, below the "Firm supply curve" label
    firm_message(paste0("Shutdown: the price (", firm_fmt(P), ") is below\n",
                        "the lowest AVC (", firm_fmt(out$min_avc), "). The firm ",
                        "produces\nnothing and loses its fixed cost (",
                        firm_fmt(FC), ")."), xlim, ylim, y_frac = 0.6,
                 x_frac = 0.38, cex = 0.8)
  }

  # Labels inside the areas (only where they fit)
  in_x <- c(xlim[1] + pad_x, Qs - pad_x)
  low_y <- ylim[1] + 0.08 * ry           # TVC label: low down, below the U
  if (Qs > 0 && version == "areas") {
    avoid <- firm_add_box(avoid, firm_place_label(
      "TVC", in_x, c(ylim[1] + pad_y, P), Qs / 2, low_y, curves, avoid,
      ok = function(x, y) y < mc_at(x)))
    firm_place_label("PS", in_x, c(ylim[1], P - pad_y), 0.65 * Qs,
                     P - 0.3 * (P - out$min_mc), curves, avoid,
                     ok = function(x, y) y > mc_at(x))
  }
  if (Qs > 0 && version == "rectangles") {
    avc <- out$AVC_star; atc <- out$ATC_star
    top <- max(P, atc); mid <- min(P, atc)
    # One label per rectangle, each kept inside its own band. TVC goes on the
    # left, with a note beside it: TVC is the same total as in 6a (the area
    # under MC up to q*), only its shape differs.
    avoid <- firm_add_box(avoid, firm_place_label(
      "TVC", in_x, c(ylim[1] + pad_y, avc), 0.25 * Qs, low_y, curves, avoid))
    avoid <- firm_add_box(avoid, firm_place_label(
      "Same TVC as in 6a,\nnow drawn as AVC x q*", in_x,
      c(ylim[1] + pad_y, avc - pad_y), 0.55 * Qs, low_y, curves, avoid,
      cex = 0.75, font = 3, col = "grey25"))
    # (with a loss, the top of the FC band is covered by the red loss area,
    # so the label goes into the grey part that is still visible)
    avoid <- firm_add_box(avoid, firm_place_label(
      "FC", in_x, c(avc, mid), 0.55 * Qs, (avc + mid) / 2, curves, avoid,
      cex = 0.8))
    avoid <- firm_add_box(avoid, firm_place_label(
      if (is_profit) "Profit" else "Loss", in_x, c(mid, top), 0.6 * Qs,
      (mid + top) / 2, curves, avoid, cex = 0.9))

    # Bracket on the right edge of the rectangles, from AVC(q*) up to p*:
    # this height times q* is the producer surplus
    firm_bracket(Qs, avc, P,
                 if (is_profit) "PS =\nProfit + FC" else "PS =\nFC - Loss",
                 xlim, ylim, curves, avoid)
  }

  firm_legend(items, fills, xlim, ylim, borders = borders,
              density = if (length(dens) > 0) dens else NULL)
  out
}


# ***********************************************************
# Part 4: Model C, the market step by step (Tutorial 1) ----
# ***********************************************************
# Demand, equilibrium, and what happens at a price above or below the
# equilibrium.
#
# Market figures use CAPITAL letters: P and Q, P* and Q* in equilibrium, P2
# for a second price (the single firm in Part 3 uses lowercase p and q).
#   Demand: P = a - b * Q   (a = the highest willingness to pay)
#   Supply: P = c + d * Q   (the same line as the firm's MC in Part 3)
# Each point on the demand curve is one buyer's willingness to pay (W2P) for
# that unit: the benefit of one more unit to buyers, i.e. the marginal
# benefit MB. So the demand curve is "D = MB", as the supply curve is "S = MC".


### 10. market_step_outcomes(): equilibrium, one unit, a second price ----
# q_unit: the unit whose buyer we look at (demand figure);
# P2: a second price, above or below P* (excess supply and shortage figures).
# Returns a named list, e.g. market_step_outcomes(P2 = 11)$excess_supply
market_step_outcomes <- function(a = 14, b = 1, c = 2, d = 1, q_unit = 3,
                                 P2 = NULL) {
  eq <- market_outcomes(a, b, c, d)          # also checks a, b, c and d
  check_firm_number(q_unit, "q_unit", min = 0,
                    what = "a quantity cannot be negative")
  W2P <- a - b * q_unit                      # willingness to pay for that unit
  out <- list(P_star = eq$P0, Q_star = eq$Q0, CS = eq$CS, PS = eq$PS,
              q_unit = q_unit, W2P = W2P,
              # (negative: that buyer values the unit less than P*, no purchase)
              unit_surplus = W2P - eq$P0,
              no_trade = eq$no_trade_ever)
  if (!is.null(P2)) {
    check_firm_number(P2, "P2", min = 0, what = "a price cannot be negative")
    Qd <- max(0, (a - P2) / b)               # quantity demanded at P2
    Qs <- max(0, (P2 - c) / d)               # quantity supplied at P2
    out <- c(out, list(P2 = P2, Qd = Qd, Qs = Qs,
                       excess_supply = max(0, Qs - Qd),
                       shortage = max(0, Qd - Qs)))
  }
  out
}


### 11. draw_market_step(): the four market figures, one function ----
# step "demand":        demand curve D, market price P*, consumer surplus CS,
#                       and one unit: its buyer's W2P = price paid + surplus
# step "equilibrium":   S = MC and D = MB meet at P* = MC = MB; CS and PS
# step "excess_supply": at a price P2 above P*, more is supplied than demanded
# step "shortage":      at a price P2 below P*, more is demanded than supplied
# For the last two, P2 defaults to P* + 3 and P* - 3. (The label always
# follows the numbers: a P2 below P* in "excess_supply" shows a shortage.)
# tick_step and fit_top work as in draw_firm_step().
# Returns market_step_outcomes() invisibly.
market_steps <- c("demand", "equilibrium", "excess_supply", "shortage")

draw_market_step <- function(step = "demand", a = 14, b = 1, c = 2, d = 1,
                             q_unit = 3, P2 = NULL,
                             xlim = c(0, 20), ylim = c(0, 20), main = NULL,
                             tick_step = NULL, fit_top = FALSE) {
  step <- as.character(step)
  if (length(step) != 1 || !(step %in% market_steps)) {
    stop("'step' must be one of ", paste(market_steps, collapse = ", "), ".",
         call. = FALSE)
  }
  out <- market_step_outcomes(a, b, c, d, q_unit)        # checks the inputs
  two_prices <- step %in% c("excess_supply", "shortage")
  if (two_prices) {
    if (is.null(P2)) {
      P2 <- max(0, out$P_star + if (step == "excess_supply") 3 else -3)
    }
    out <- market_step_outcomes(a, b, c, d, q_unit, P2)
  }
  op <- par(c("mar", "las"))   # firm_canvas() changes these two settings;
  on.exit(par(op))             # restore them when we finish

  Pst <- out$P_star; Qst <- out$Q_star
  dem <- function(x) a - b * x
  sup <- function(x) c + d * x
  rx <- diff(xlim); ry <- diff(ylim)
  pad_x <- 0.015 * rx; pad_y <- 0.02 * ry
  trade <- Qst > 0

  # Legend entries (counted first, for fit_top)
  items <- character(0); fills <- character(0)
  add <- function(label, col) {
    items <<- c(items, label); fills <<- c(fills, col)
  }
  nm <- firm_fmt(q_unit)
  # Is the unit bought? Yes if W2P >= P* (at W2P = P*, the last unit, Q*,
  # the buyer is indifferent and the surplus on it is 0)
  bought <- out$W2P >= Pst - 1e-9
  if (step == "demand") {
    if (trade) add("Consumer surplus (CS)", firm_fill(peib_cols["cs"], 0.3))
    if (bought) {
      add(paste0("Price paid for unit ", nm, " (P*)"),
          firm_fill(peib_cols["tr"], 0.9))
      add(paste0("Surplus on unit ", nm, " (W2P - P*)"),
          firm_fill(peib_cols["cs"], 0.9))
    } else {
      add(paste0("W2P for unit ", nm, " (below P*: not bought)"),
          firm_fill("grey60", 0.9))
    }
  }
  if (step == "equilibrium" && trade) {
    add("Consumer surplus (CS)", firm_fill(peib_cols["cs"]))
    add("Producer surplus (PS)", firm_fill(peib_cols["ps"]))
  }

  firm_canvas(xlim, ylim, main, ylab = "Price (P)", xlab = "Quantity (Q)",
              tick_step = tick_step,
              n_legend = if (fit_top) length(items) else NULL)

  # Labels must not cross the curves (and, in the demand figure, the price
  # line); boxes of labels already drawn go into 'avoid'
  curves <- function(x) {
    l <- list(dem(x))
    if (step != "demand") l <- c(l, list(sup(x)))
    if (step == "demand") l <- c(l, list(rep(Pst, length(x))))
    l
  }
  avoid <- list()

  # Shaded areas first (lines go on top)
  if (trade && step == "demand") {
    polygon(c(0, 0, Qst), c(Pst, a, Pst), col = firm_fill(peib_cols["cs"], 0.3),
            border = NA)
  }
  if (trade && step == "equilibrium") {
    polygon(c(0, 0, Qst), c(Pst, a, Pst), col = firm_fill(peib_cols["cs"]),
            border = NA)
    polygon(c(0, 0, Qst), c(max(c, 0), Pst, Pst),
            col = firm_fill(peib_cols["ps"]), border = NA)
  }

  # Demand figure: one unit as a thin bar
  # Its full height is that buyer's willingness to pay W2P = D(q_unit): the
  # lower part (up to P*) is the price paid, the upper part the surplus.
  w <- 0.012 * rx
  if (step == "demand") {
    W2P <- out$W2P
    if (bought) {
      rect(q_unit - w, 0, q_unit + w, Pst, col = firm_fill(peib_cols["tr"], 0.9),
           border = NA)
      rect(q_unit - w, Pst, q_unit + w, W2P, col = firm_fill(peib_cols["cs"], 0.9),
           border = NA)
    } else {
      rect(q_unit - w, 0, q_unit + w, max(0, W2P), col = firm_fill("grey60", 0.9),
           border = NA)
    }
    avoid <- list(c(l = q_unit - w, r = q_unit + w, b = 0, t = max(W2P, Pst)))
  }

  # The curves
  lab_s <- if (step == "equilibrium") "S = MC" else "S"
  lab_d <- if (step == "equilibrium") "D = MB" else "D"
  if (step != "demand") {
    avoid <- firm_add_box(avoid, firm_supply_line(c, d, lab_s, xlim, ylim))
  }
  avoid <- firm_add_box(avoid, market_demand_line(a, -b, lab_d, xlim, ylim))

  if (!trade) {
    firm_message("No trade: buyers' highest willingness to pay\nis below sellers' cost",
                 xlim, ylim)
    firm_legend(items, fills, xlim, ylim)
    return(invisible(out))
  }

  # Demand figure: price line, Q*, labels
  if (step == "demand") {
    # (label at the right end of the price line: the left end lies in the
    # CS area)
    avoid <- firm_add_box(avoid, firm_price_line(Pst, xlim, ylim, name = "P*",
                                                 side = "right"))
    avoid <- firm_add_box(avoid, firm_qstar_guide(Qst, Pst, xlim, ylim,
                                                  name = "Q*"))
    above_d <- function(x, y) y > dem(x)
    in_cs   <- function(x, y) y < dem(x) && y > Pst
    if (bought) {
      # W2P at the top of the bar, on its right (above the demand curve)
      # (spelled out once: most students have no economics background)
      lab <- paste0("Willingness to pay (W2P) = ", firm_fmt(W2P))
      sz  <- firm_text_size(lab, 0.8, 2)
      x_l <- q_unit + w + 0.01 * rx
      b1 <- firm_place_label(lab, c(x_l, x_l + sz[["w"]] + 0.05 * rx),
                             c(W2P - 0.2 * sz[["h"]], W2P + 2 * sz[["h"]]),
                             x_l + sz[["w"]] / 2, W2P + 0.6 * sz[["h"]],
                             curves, avoid, ok = above_d, cex = 0.8)
      avoid <- firm_add_box(avoid, b1)
      avoid <- firm_add_box(avoid, peib_bar_label(
        paste0("surplus = ", firm_fmt(W2P - Pst)), q_unit, w, (Pst + min(W2P, ylim[2])) / 2,
        curves, avoid, xlim))
      avoid <- firm_add_box(avoid, peib_bar_label(
        paste0("price paid = ", firm_fmt(Pst)), q_unit, w, Pst / 2,
        curves, avoid, xlim))
    } else {
      avoid <- firm_add_box(avoid, peib_bar_label(
        paste0("W2P = ", firm_fmt(W2P), " < P*"), q_unit, w, max(W2P, 0) / 2,
        curves, avoid, xlim))
    }
    # "CS" inside the triangle, preferably between the bar and Q*
    qx <- min(q_unit, Qst)
    avoid <- firm_add_box(avoid, firm_place_label(
      "CS", c(xlim[1] + pad_x, Qst - pad_x), c(Pst + pad_y, ylim[2]),
      (2 * qx + Qst) / 3, (dem(qx) + 2 * Pst) / 3, curves, avoid, ok = in_cs))
    # The message of this figure, just above the demand curve
    lab <- "CS = the sum of the surpluses\non all units from 0 to Q*"
    sz  <- firm_text_size(lab, 0.75, 3)
    y_p <- Pst + 0.75 * (ylim[2] - Pst)
    firm_place_label(lab, c(xlim[1] + pad_x, xlim[2] - pad_x),
                     c(Pst + pad_y, ylim[2] - pad_y),
                     (a - y_p) / b + sz[["w"]] / 2 + 0.03 * rx, y_p, curves,
                     avoid, ok = above_d, cex = 0.75, font = 3, col = "grey25")
  }

  # Equilibrium figure: P* = MC = MB, dotted guides, CS and PS labels
  if (step == "equilibrium") {
    avoid <- c(avoid, peib_eq_guides(Pst, Qst, xlim, ylim))
    points(Qst, Pst, pch = 19, cex = 1)
    lab <- "P* = MC = MB"
    sz  <- firm_text_size(lab, 0.85, 2)
    avoid <- firm_add_box(avoid, firm_place_label(
      lab, c(Qst + 0.015 * rx, xlim[2] - pad_x),
      c(Pst - 2 * sz[["h"]], Pst + 2 * sz[["h"]]),
      Qst + 0.02 * rx + sz[["w"]] / 2, Pst, curves, avoid, cex = 0.85))
    firm_place_label("CS", c(xlim[1] + pad_x, Qst - pad_x), c(Pst, ylim[2]),
                     Qst / 3, (a + 2 * Pst) / 3, curves, avoid,
                     ok = function(x, y) y < dem(x))
    firm_place_label("PS", c(xlim[1] + pad_x, Qst - pad_x), c(ylim[1], Pst),
                     Qst / 3, (max(c, 0) + 2 * Pst) / 3, curves, avoid,
                     ok = function(x, y) y > sup(x))
  }

  # Excess supply and shortage figures
  if (two_prices) {
    # Equilibrium in light grey, for comparison
    avoid <- c(avoid, peib_eq_guides(Pst, Qst, xlim, ylim, col = "grey55"))
    points(Qst, Pst, pch = 21, bg = "white", col = "grey45", cex = 1)
    Qd <- out$Qd; Qs <- out$Qs; P2 <- out$P2
    # The second price: dotted line from the P axis to the farther point
    segments(xlim[1], P2, max(Qd, Qs), P2, lty = 3, lwd = 1.6, col = "grey15")
    if (abs(P2 - Pst) > 0.04 * ry) {   # (otherwise it would sit on "P* = ...")
      text(xlim[1] + 0.01 * rx, P2, paste0("P2 = ", firm_fmt(P2)),
           adj = c(0, -0.4), cex = 0.8)
    }
    # Quantity demanded (on D) and supplied (on S) at P2, with dotted guides
    for (k in c("d", "s")) {
      q <- if (k == "d") Qd else Qs
      if (q <= 0 || q > xlim[2]) next
      segments(q, ylim[1], q, P2, lty = 3, lwd = 1.3, col = "grey30")
      points(q, P2, pch = 19, cex = 1)
      avoid <- firm_add_box(avoid, c(l = q, r = q, b = ylim[1], t = P2))
    }
    for (k in c("d", "s")) {
      q <- if (k == "d") Qd else Qs
      if (q <= 0 || q > xlim[2]) next
      lab <- if (k == "d") paste0("Qd = ", firm_fmt(q), "\n(demanded)")
             else paste0("Qs = ", firm_fmt(q), "\n(supplied)")
      avoid <- firm_add_box(avoid, peib_q_label(q, lab, xlim, ylim, avoid))
    }
    # The gap between the two quantities, marked by a brace on the side of
    # the P2 line where the curves leave room: above it for excess supply
    # (both curves are below P2 between Qd and Qs), below it for a shortage
    gap <- Qs - Qd
    if (abs(gap) > 1e-9 && min(Qd, Qs) < xlim[2]) {
      # The label spells out the gap, e.g. "= Qs - Qd = 9 - 3 = 6 units";
      # on two lines when one line would be much wider than the brace
      unit_word <- if (abs(abs(gap) - 1) < 1e-9) " unit" else " units"
      lab <- if (gap > 0) {
        paste0("Excess supply (overproduction) = Qs - Qd = ", firm_fmt(Qs),
               " - ", firm_fmt(Qd), " = ", firm_fmt(gap), unit_word)
      } else {
        paste0("Shortage (excess demand) = Qd - Qs = ", firm_fmt(Qd),
               " - ", firm_fmt(Qs), " = ", firm_fmt(-gap), unit_word)
      }
      if (strwidth(lab, cex = 0.8, font = 2) > 1.1 * abs(gap)) {
        lab <- sub(") = ", ")\n= ", lab, fixed = TRUE)
      }
      peib_hbrace(min(Qd, Qs), min(max(Qd, Qs), xlim[2]), P2, lab, xlim, ylim,
                  up = gap > 0)
    } else if (abs(gap) <= 1e-9) {
      firm_message(paste0("At P2 = P* = ", firm_fmt(Pst),
                          " the quantity demanded equals the quantity supplied"),
                   xlim, ylim)
    }
  }

  firm_legend(items, fills, xlim, ylim)
  invisible(out)
}

### 12. Small helpers for the market figures ----

# A straight demand line P = a0 + slope * Q (slope < 0), from the price axis
# (or from the top edge, if a0 is above it) down to 92% of the quantity range
# (or 12% of the price range), with its label just below its end. Returns the
# label's box.
market_demand_line <- function(a0, slope, label, xlim, ylim,
                               col = peib_cols["demand"], cex = 1) {
  rx <- diff(xlim); ry <- diff(ylim)
  x0 <- max(xlim[1], (ylim[2] - a0) / slope)          # start
  x1 <- min(xlim[1] + 0.92 * rx, (ylim[1] + 0.12 * ry - a0) / slope)   # end
  if (x1 <= x0) return(invisible(NULL))               # the line misses the box
  y0 <- a0 + slope * x0; y1 <- a0 + slope * x1
  segments(x0, y0, x1, y1, col = col, lwd = 2.5)
  # Below the end of the line (the line is higher to the left, so that space
  # is free), moved left if it would be cut off at the right edge
  hw <- strwidth(label, cex = cex, font = 2) / 2
  hh <- strheight(label, cex = cex, font = 2)
  xl <- min(max(x1, xlim[1] + hw), xlim[2] - hw - 0.01 * rx)
  text(xl, y1, label, col = col, font = 2, cex = cex, pos = 1, offset = 0.4)
  oy <- 0.4 * strheight("M", cex = cex)
  invisible(c(l = xl - hw, r = xl + hw, b = y1 - oy - hh * 1.3,
              t = y1 - oy * 0.5))
}

# Do two boxes c(l, r, b, t) overlap? (TRUE if 'box' overlaps any box in 'avoid')
peib_overlaps <- function(box, avoid) {
  any(vapply(avoid, function(a) box[["l"]] < a[["r"]] && box[["r"]] > a[["l"]] &&
               box[["b"]] < a[["t"]] && box[["t"]] > a[["b"]], logical(1)))
}

# Guides from the equilibrium point to both axes, labelled "P* = ..." just
# above the horizontal guide at the P axis and "Q* = ..." just above the Q
# axis. Both guides are dashed, as the q* guide in the firm figures and the
# Q* guide in the demand figure (the P2 lines are dotted, to tell them apart).
# Returns a list of boxes (labels and guide lines) to avoid.
peib_eq_guides <- function(Pst, Qst, xlim, ylim, col = "grey30") {
  rx <- diff(xlim)
  segments(xlim[1], Pst, Qst, Pst, lty = 2, col = col)
  segments(Qst, ylim[1], Qst, Pst, lty = 2, col = col)
  lab <- paste0("P* = ", firm_fmt(Pst))
  txt_col <- if (col == "grey30") "black" else "grey35"
  text(xlim[1] + 0.01 * rx, Pst, lab, adj = c(0, -0.4), cex = 0.8, col = txt_col)
  sz <- firm_text_size(lab, 0.8)
  boxes <- list(c(l = xlim[1], r = xlim[1] + 0.01 * rx + sz[["w"]], b = Pst,
                  t = Pst + 1.4 * sz[["h"]]),
                c(l = xlim[1], r = Qst, b = Pst, t = Pst),
                c(l = Qst, r = Qst, b = ylim[1], t = Pst))
  b <- peib_q_label(Qst, paste0("Q* = ", firm_fmt(Qst)), xlim, ylim, boxes,
                    col = txt_col)
  firm_add_box(boxes, b)
}

# A value label just above the Q axis, right of a vertical guide at q (or left
# of it if there is no room on the right, or the spot is taken). Returns its
# box, or NULL if it fits nowhere.
peib_q_label <- function(q, lab, xlim, ylim, avoid = list(), cex = 0.8,
                         col = "black") {
  rx <- diff(xlim)
  sz <- firm_text_size(lab, cex)
  y  <- ylim[1] + 0.015 * diff(ylim)
  for (side in c(1, -1)) {
    l <- if (side == 1) q + 0.01 * rx else q - 0.01 * rx - sz[["w"]]
    box <- c(l = l, r = l + sz[["w"]], b = y, t = y + sz[["h"]])
    if (box[["l"]] >= xlim[1] && box[["r"]] <= xlim[2] &&
        !peib_overlaps(box, avoid)) {
      text(l, y, lab, adj = c(0, 0), cex = cex, col = col)
      return(box)
    }
  }
  NULL
}

# Value label beside a thin vertical bar at x (half-width w), at height y_mid:
# left of the bar if there is room, otherwise right of it, on two lines if one
# line does not fit; left out if it fits nowhere. Returns its box.
peib_bar_label <- function(lab, x, w, y_mid, curves, avoid, xlim, cex = 0.8) {
  rx <- diff(xlim)
  for (txt in c(lab, sub(" = ", "\n= ", lab, fixed = TRUE))) {
    sz <- firm_text_size(txt, cex, 2)
    y_rng <- y_mid + c(-1, 1) * sz[["h"]] * 0.7
    gap <- 0.01 * rx; reach <- sz[["w"]] + 0.03 * rx   # stay next to the bar
    b <- firm_place_label(txt, x - w - gap - c(reach, 0), y_rng,
                          x - w - gap - sz[["w"]] / 2, y_mid, curves, avoid,
                          cex = cex)
    if (is.null(b)) {
      b <- firm_place_label(txt, x + w + gap + c(0, reach), y_rng,
                            x + w + gap + sz[["w"]] / 2, y_mid, curves, avoid,
                            cex = cex)
    }
    if (!is.null(b)) return(b)
  }
  NULL
}

# Horizontal curly brace from x0 to x1 just above (up = TRUE) or below the
# height y, with its label beyond the tip, on a white box so that dotted
# guide lines behind it do not cut through the text. Returns the label's box.
peib_hbrace <- function(x0, x1, y, lab, xlim, ylim, up = TRUE, cex = 0.8) {
  rx <- diff(xlim); ry <- diff(ylim); s <- if (up) 1 else -1
  h  <- 0.04 * ry                            # depth of the brace
  r  <- min(0.025 * rx, (x1 - x0) / 4)       # length of each curl along Q
  xm <- (x0 + x1) / 2; yb <- y + s * 0.012 * ry
  # Two quarter-ellipse curls on each half, joined by straight pieces: from
  # the left end out to half the depth, along, out to the tip in the middle
  th <- seq(0, pi / 2, length.out = 20)
  lo_x <- c(x0 + r - r * cos(th), xm - r + r * sin(th))
  lo_y <- yb + s * c(h / 2 * sin(th), h - h / 2 * cos(th))
  lines(c(lo_x, rev(2 * xm - lo_x)), c(lo_y, rev(lo_y)), lwd = 1.8,
        col = "grey15")
  sz <- firm_text_size(lab, cex, 2)
  xc <- min(max(xm, xlim[1] + sz[["w"]] / 2), xlim[2] - sz[["w"]] / 2)
  yc <- yb + s * (h + 0.012 * ry + sz[["h"]] / 2)
  box <- c(l = xc - sz[["w"]] / 2, r = xc + sz[["w"]] / 2,
           b = yc - sz[["h"]] / 2, t = yc + sz[["h"]] / 2)
  rect(box[["l"]], box[["b"]], box[["r"]], box[["t"]],
       col = adjustcolor("white", 0.9), border = NA)
  text(xc, yc, lab, cex = cex, font = 2)
  invisible(box)
}


# ***********************************************************
# Part 5: Model D, Tutorial 2: the nickel-battery value chain ----
# ***********************************************************
# Two perfectly competitive industries linked by an input: nickel producers
# (upstream) sell nickel to battery producers (downstream), who sell
# batteries to final users. Each battery needs exactly one unit of nickel,
# so the quantities traded in the two markets are equal: Q_N = Q_B = Q.
#
#   Battery demand (final users):         P_B = A - b * Q
#   Other marginal cost of batteries:     c + g * Q   (labour, energy, ...)
#   Battery supply, for a given P_N:      P_B = P_N + c + g * Q
#   Nickel supply:                        P_N = u + s * Q
#   The innovation lowers nickel marginal cost by k at every Q: u -> u - k
#   Derived demand for nickel:            P_N = (A - c) - (b + g) * Q
#     (what a battery producer can pay for the Q-th unit of nickel: the
#     price of the Q-th battery minus the other cost of making it)
#
# Handout numbers (Tutorial 2): A = 220, b = 1, c = 50, g = 1, u = 50,
# s = 1, k = 30, 10 firms in each industry, fixed cost 20 per firm:
#   E0 (before): Q = 40, P_N = 90, P_B = 180
#   E1 (after):  Q = 50, P_N = 70, P_B = 170
# One firm: an industry curve P = u + s*Q made of n identical firms means
# that each firm's marginal cost is u + (s*n)*q (with s = 1 and n = 10:
# MC = 50 + 10q, the handout's TC = 20 + 50q + 5q^2).
#
# Notation in the figures: capital P and Q for markets (P_N, Q_N for
# nickel, P_B, Q_B for batteries), lowercase q for one firm. Areas are
# labelled with plain names: TVC, PS, CS_N, PS_N, CS_B, PS_B.
#
# Every drawing function below has the same layout arguments as Parts 3
# and 4 (xlim, ylim, main, tick_step, fit_top) plus
#   version = "tutor":   numbers printed in the areas, E1 labelled, arrows
#                        with their sizes (the tutor handout and the website)
#   version = "student": the same curves, but areas without numbers and no
#                        E1 label (students find E1 themselves)
# and returns its outcomes invisibly (for the app tables and answer key).


### 13. Small helpers for the value-chain figures ----

# Numbers in labels: at most 'digits' decimals, a comma for thousands
# (1,600), never "-0"
chain_fmt <- function(x, digits = 2) {
  if (length(x) != 1 || is.na(x)) return("n/a")
  if (!is.finite(x)) return(if (x > 0) "infinite" else "minus infinite")
  formatC(round(x, digits) + 0, format = "f", digits = digits,
          drop0trailing = TRUE, big.mark = ",")
}

# tick_step of a two-panel figure: NULL (R's automatic axis numbers, the
# app), one number or c(x, y) for both panels, or a list of two such
# vectors, one per panel (left, right), e.g. list(c(1, 10), c(10, 10)).
chain_tick_step <- function(tick_step, panel) {
  if (is.null(tick_step)) return(NULL)
  if (is.list(tick_step)) {
    if (length(tick_step) != 2) {
      stop("'tick_step' as a list needs two entries, one per panel ",
           "(left, right).", call. = FALSE)
    }
    return(tick_step[[panel]])
  }
  tick_step
}

# A straight line P = a0 + slope * Q, cut to the plotting box: rising (or
# flat) lines stop at 88% of the price range and carry their label just
# above their end, as firm_supply_line(); falling lines start at the top
# edge, stop at 12% of the price range and carry their label just below
# their end, as market_demand_line(). Unlike those two helpers it also
# draws FLAT lines (slope 0), which the app's sliders can produce (a
# horizontal demand curve when b = 0, a flat supply curve when s = 0).
# Every line stops at 92% of the quantity range. Returns the label's box.
chain_line <- function(a0, slope, label, xlim, ylim, lty = 1,
                       col = peib_cols["supply"], lwd = 2.5, cex = 1) {
  rx <- diff(xlim); ry <- diff(ylim)
  falling <- slope < 0
  y_lo <- if (falling) ylim[1] + 0.12 * ry else ylim[1]
  y_hi <- if (falling) ylim[2] else ylim[1] + 0.88 * ry
  x0 <- xlim[1]; x1 <- xlim[1] + 0.92 * rx
  if (slope != 0) {
    # where the line enters and leaves the band y_lo to y_hi
    xa <- (y_lo - a0) / slope; xb <- (y_hi - a0) / slope
    x0 <- max(x0, min(xa, xb)); x1 <- min(x1, max(xa, xb))
  } else if (a0 < ylim[1] || a0 > ylim[2]) {
    # (a flat line is drawn wherever it lies inside the box: a flat demand
    # curve high up, e.g. at 220 on a 0-240 axis, must not disappear)
    return(invisible(NULL))                 # a flat line outside the box
  }
  if (x1 <= x0) return(invisible(NULL))     # the line misses the box
  y0 <- a0 + slope * x0; y1 <- a0 + slope * x1
  segments(x0, y0, x1, y1, col = col, lwd = lwd, lty = lty)
  if (is.null(label)) return(invisible(NULL))
  hw <- strwidth(label, cex = cex, font = 2) / 2
  hh <- strheight(label, cex = cex, font = 2)
  oy <- 0.4 * strheight("M", cex = cex)
  # centred on the end of the line, moved left if it would be cut off
  xl <- min(max(x1, xlim[1] + hw), xlim[2] - hw - 0.01 * rx)
  text(xl, y1, label, col = col, font = 2, cex = cex,
       pos = if (falling) 1 else 3, offset = 0.4)
  box <- if (falling) {
    c(l = xl - hw, r = xl + hw, b = y1 - oy - hh * 1.3, t = y1 - oy * 0.5)
  } else {
    c(l = xl - hw, r = xl + hw, b = y1 + oy * 0.5, t = y1 + oy + hh * 1.3)
  }
  invisible(box)
}

# Put a label at the free spot closest to (x_pref, y_pref) inside x_rng by
# y_rng (see firm_free_spot(): it never crosses a curve or a box in
# 'avoid'). If the label does not fit on one line, the versions in 'alts'
# are tried (default: broken before " (" or after "="). If nothing fits
# and fallback = TRUE, the label goes on a white box at the preferred spot
# (readable, though it may cover a line). Returns the label's box or NULL.
chain_label_near <- function(lab, x_rng, y_rng, x_pref, y_pref, curves,
                             avoid = list(), ok = function(x, y) TRUE,
                             cex = 0.8, font = 2, col = "black",
                             alts = NULL, fallback = TRUE) {
  if (is.null(alts)) {
    alts <- unique(c(lab, sub(" (", "\n(", lab, fixed = TRUE),
                     sub(" = ", "\n= ", lab, fixed = TRUE)))
  }
  for (txt in alts) {
    b <- firm_place_label(txt, x_rng, y_rng, x_pref, y_pref, curves, avoid,
                          ok, cex = cex, font = font, col = col)
    if (!is.null(b)) return(b)
  }
  if (!fallback) return(NULL)
  sz <- firm_text_size(lab, cex, font); usr <- par("usr")
  x <- min(max(x_pref, usr[1] + sz[["w"]] / 2), usr[2] - sz[["w"]] / 2)
  y <- min(max(y_pref, usr[3] + sz[["h"]] / 2), usr[4] - sz[["h"]] / 2)
  box <- c(l = x - sz[["w"]] / 2, r = x + sz[["w"]] / 2,
           b = y - sz[["h"]] / 2, t = y + sz[["h"]] / 2)
  rect(box[["l"]], box[["b"]], box[["r"]], box[["t"]],
       col = adjustcolor("white", 0.85), border = NA)
  text(x, y, lab, cex = cex, font = font, col = col)
  box
}

# Size of an arrowhead (inches): at most 0.07, smaller on short arrows so
# that the two heads of a double arrow do not overlap
chain_head <- function(len_user, horizontal = FALSE) {
  usr <- par("usr"); pin <- par("pin")
  inch <- if (horizontal) len_user / (usr[2] - usr[1]) * pin[1]
          else len_user / (usr[4] - usr[3]) * pin[2]
  max(0.025, min(0.07, 0.3 * abs(inch)))
}

# Double-headed VERTICAL arrow at x from y0 to y1 (e.g. "-30 (cost)"), with
# its label beside it: on the side(s) in 'sides' (1 = right, -1 = left),
# in that order of preference, broken onto two lines if needed; y_pref
# (default: the arrow's middle) is the preferred height of the label.
# Returns 'avoid' with the arrow and its label added.
chain_varrow <- function(x, y0, y1, lab, curves, avoid = list(), cex = 0.8,
                         sides = c(1, -1), code = 3, y_pref = NULL) {
  if (abs(y1 - y0) < 1e-9) return(avoid)
  usr <- par("usr"); rx <- usr[2] - usr[1]; ry <- usr[4] - usr[3]
  arrows(x, y0, x, y1, code = code, length = chain_head(y1 - y0),
         lwd = 1.6, col = "grey15")
  avoid <- firm_add_box(avoid, c(l = x - 0.004 * rx, r = x + 0.004 * rx,
                                 b = min(y0, y1), t = max(y0, y1)))
  if (is.null(lab)) return(avoid)
  ym <- (y0 + y1) / 2; gap <- 0.012 * rx
  sz <- firm_text_size(lab, cex, 2)
  y_rng <- ym + c(-1, 1) * (abs(y1 - y0) / 2 + 3 * sz[["h"]])
  if (!is.null(y_pref)) ym <- y_pref
  # The label on one line first, then broken onto two lines; the preferred
  # spot uses the width of the version tried, so that a two-line label
  # also starts right next to the arrow
  alts <- unique(c(lab, sub(" (", "\n(", lab, fixed = TRUE),
                   sub(" = ", "\n= ", lab, fixed = TRUE)))
  for (sd in sides) {
    x_rng <- if (sd > 0) c(x + gap, x + gap + 1.3 * sz[["w"]] + 0.04 * rx)
             else c(x - gap - 1.3 * sz[["w"]] - 0.04 * rx, x - gap)
    for (txt in alts) {
      w_t <- firm_text_size(txt, cex, 2)[["w"]]
      b <- chain_label_near(txt, x_rng, y_rng, x + sd * (gap + w_t / 2), ym,
                            curves, avoid, cex = cex, alts = txt,
                            fallback = FALSE)
      if (!is.null(b)) return(firm_add_box(avoid, b))
    }
  }
  firm_add_box(avoid, chain_label_near(
    lab, c(usr[1], usr[2]), y_rng, x + sides[1] * (gap + sz[["w"]] / 2), ym,
    curves, avoid, cex = cex))
}

# Double-headed HORIZONTAL arrow at height y from x0 to x1 (e.g. "+30
# units"), with its label above it (sides = 1) or below it (-1), in that
# order of preference. Returns 'avoid' with the arrow and label added.
chain_harrow <- function(x0, x1, y, lab, curves, avoid = list(), cex = 0.8,
                         sides = c(1, -1)) {
  if (abs(x1 - x0) < 1e-9) return(avoid)
  usr <- par("usr"); rx <- usr[2] - usr[1]; ry <- usr[4] - usr[3]
  arrows(x0, y, x1, y, code = 3, length = chain_head(x1 - x0, TRUE),
         lwd = 1.6, col = "grey15")
  avoid <- firm_add_box(avoid, c(l = min(x0, x1), r = max(x0, x1),
                                 b = y - 0.006 * ry, t = y + 0.006 * ry))
  if (is.null(lab)) return(avoid)
  xm <- (x0 + x1) / 2; gap <- 0.015 * ry
  sz <- firm_text_size(lab, cex, 2)
  x_rng <- xm + c(-1, 1) * (abs(x1 - x0) / 2 + sz[["w"]])
  for (sd in sides) {
    y_rng <- if (sd > 0) c(y + gap, y + gap + 2.5 * sz[["h"]])
             else c(y - gap - 2.5 * sz[["h"]], y - gap)
    b <- chain_label_near(lab, x_rng, y_rng, xm,
                          y + sd * (gap + sz[["h"]] / 2), curves, avoid,
                          cex = cex, fallback = FALSE)
    if (!is.null(b)) return(firm_add_box(avoid, b))
  }
  firm_add_box(avoid, chain_label_near(
    lab, x_rng, c(usr[3], usr[4]), xm, y + sides[1] * (gap + sz[["h"]] / 2),
    curves, avoid, cex = cex))
}

# Dashed guides from a point (Q, P) to both axes. full = TRUE draws the
# vertical guide over the whole height (Figure 6: the same Q in both
# panels). Returns the guides as thin boxes to avoid.
chain_guides <- function(Q, P, xlim, ylim, full = FALSE, col = "grey30") {
  if (!is.finite(Q) || !is.finite(P)) return(list())
  segments(xlim[1], P, Q, P, lty = 2, col = col)
  segments(Q, ylim[1], Q, if (full) ylim[2] else P, lty = 2, col = col)
  list(c(l = xlim[1], r = Q, b = P, t = P),
       c(l = Q, r = Q, b = ylim[1], t = if (full) ylim[2] else P))
}

# An equilibrium point with its label ("E0", or "E0 = (40, 90)" in the
# tutor version) at the free spot closest to the preferred side
# ('dir' = c(dx, dy): +1/-1 for right/left and above/below). Returns
# 'avoid' with the label added.
chain_point <- function(Q, P, lab, curves, avoid, dir = c(1, 1), cex = 0.85,
                        alts = NULL) {
  points(Q, P, pch = 19, cex = 1)
  usr <- par("usr"); rx <- usr[2] - usr[1]; ry <- usr[4] - usr[3]
  sz <- firm_text_size(lab, cex, 2)
  x_pref <- Q + dir[1] * (0.02 * rx + sz[["w"]] / 2)
  y_pref <- P + dir[2] * (0.03 * ry + sz[["h"]] / 2)
  avoid <- firm_add_box(avoid, c(l = Q - 0.01 * rx, r = Q + 0.01 * rx,
                                 b = P - 0.015 * ry, t = P + 0.015 * ry))
  firm_add_box(avoid, chain_label_near(
    lab, Q + c(-0.45, 0.45) * rx, P + c(-0.25, 0.25) * ry, x_pref, y_pref,
    curves, avoid, cex = cex, alts = alts))
}

# Legend across the whole figure (two-panel figures), centred on the
# device just above the plotting boxes. Call it while a panel is active.
# It shrinks the text if the legend would be wider than the device.
chain_fig_legend <- function(items, fills, ncol = length(items), cex = 0.8,
                             density = NULL, borders = NA) {
  if (length(items) == 0) return(invisible(NULL))
  dev_x <- grconvertX(c(0, 1), "ndc", "user")
  dev_y <- grconvertY(c(0, 1), "ndc", "user")
  do.call("clip", as.list(c(dev_x, dev_y)))
  x <- grconvertX(0.5, "ndc", "user"); y <- par("usr")[4]
  for (i in 1:5) {
    lg <- legend(x = x, y = y, xjust = 0.5, yjust = 0, legend = items,
                 fill = fills, ncol = ncol, cex = cex, x.intersp = 0.6,
                 plot = FALSE)
    if (lg$rect$w <= 0.96 * diff(dev_x) || cex <= 0.55) break
    cex <- max(0.55, cex * 0.96 * diff(dev_x) / lg$rect$w)
  }
  legend(x = x, y = y, xjust = 0.5, yjust = 0, xpd = NA, legend = items,
         fill = fills, border = borders, bty = "n", density = density,
         angle = 45, ncol = ncol, cex = cex, x.intersp = 0.6)
}

# Title over a two-panel figure (apps only; the handouts have no titles).
# The panels were drawn with main = "" so that their top margin has room.
chain_fig_title <- function(main, top) {
  if (is.null(main)) return(invisible(NULL))
  dev_x <- grconvertX(c(0, 1), "ndc", "user")
  do.call("clip", as.list(c(dev_x, grconvertY(c(0, 1), "ndc", "user"))))
  mtext(main, side = 3, line = top - 1.4, at = grconvertX(0.5, "ndc", "user"),
        font = 2, cex = 1.2)
}


### 14. chain_outcomes(): the two linked markets, before and after ----
# All the numbers of Exercises 1-3 (and the website's linked-markets app)
# from the general model above. Returns a named list:
#   $before, $after: Q, P_N, P_B, per-firm output, surpluses (CS_N, PS_N,
#     CS_B, PS_B), net social benefit NSB = PS_N + PS_B + CS_B, the
#     resource-cost check (value to final users minus the real cost of
#     nickel and of the other inputs) and the four elasticities
#   $dQ, $dP_N, $dP_B: changes (direct difference and formula versions)
#   $rho_N, $rho_B, $rho_total: the three pass-through rates
#   flags: $indeterminate (b + g + s = 0), $before$no_trade, ...
# k may be negative (a cost INCREASE, e.g. a tax of -k per unit).
chain_outcomes <- function(A = 220, b = 1, c = 50, g = 1, u = 50, s = 1,
                           k = 30, n_N = 10, n_B = 10, FC = 20) {
  check_firm_number(A, "A", min = 0, what = "willingness to pay")
  check_firm_number(c, "c", min = 0, what = "a cost cannot be negative")
  check_firm_number(u, "u", min = 0, what = "a cost cannot be negative")
  check_firm_number(b, "b", min = 0, what = "battery demand cannot slope up")
  check_firm_number(g, "g", min = 0,
                    what = "other marginal cost cannot fall with output")
  check_firm_number(s, "s", min = 0, what = "nickel supply cannot slope down")
  check_firm_number(k, "k")
  check_firm_number(FC, "FC", min = 0, what = "a fixed cost cannot be negative")
  for (nm in c("n_N", "n_B")) {
    n <- get(nm)
    check_firm_number(n, nm, min = 1, what = "at least one firm")
    if (n != round(n)) stop("'", nm, "' must be a whole number of firms.",
                            call. = FALSE)
  }
  if (k > u) {
    stop("The cost reduction 'k' (", k, ") is larger than the marginal cost ",
         "of the first unit of nickel ('u' = ", u, "): some units would ",
         "cost less than nothing. Use k <= u.", call. = FALSE)
  }
  denom <- b + g + s
  # With all three slopes zero every curve is flat: either nothing or an
  # unlimited quantity is traded, so the equilibrium is not determined.
  indeterminate <- denom <= 0

  # One equilibrium, for nickel supply intercept u_t (u before, u - k after)
  state <- function(u_t) {
    na <- NA_real_
    if (indeterminate) {
      return(list(u = u_t, Q = na, P_N = na, P_B = na, no_trade = NA))
    }
    # Market clearing: derived nickel demand = nickel supply,
    # (A - c) - (b + g) Q = u_t + s Q  =>  Q = (A - c - u_t) / (b + g + s).
    # No trade if even the first battery is worth less than the cost of
    # making it (A <= c + u_t).
    Q <- max(0, (A - c - u_t) / denom)
    no_trade <- Q <= 0
    P_N <- if (no_trade) na else u_t + s * Q        # on nickel supply
    P_B <- if (no_trade) na else A - b * Q          # on battery demand
    # Surpluses are triangles (all curves are straight lines):
    #   CS_B between battery demand and P_B:            b Q^2 / 2
    #   PS_B between P_B and battery supply (P_N + c + gQ): g Q^2 / 2
    #   PS_N between P_N and nickel supply:              s Q^2 / 2
    #   CS_N between derived nickel demand and P_N:  (b + g) Q^2 / 2
    CS_B <- 0.5 * b * Q^2; PS_B <- 0.5 * g * Q^2; PS_N <- 0.5 * s * Q^2
    CS_N <- 0.5 * (b + g) * Q^2
    # Resource-cost check: value to final users (area under battery demand)
    # minus the real cost of the nickel (area under nickel MC) and of the
    # other inputs (area under c + gQ). Nickel payments P_N x Q are a
    # transfer between the two industries and do not appear.
    value      <- A * Q - 0.5 * b * Q^2
    cost_N     <- u_t * Q + 0.5 * s * Q^2
    cost_other <- c * Q + 0.5 * g * Q^2
    # Point elasticities (direct form dQ/dP times P/Q); a zero slope of the
    # drawn (inverse) curve means an infinitely elastic curve
    el <- function(dQdP, P) if (no_trade) na else dQdP * P / Q
    list(u = u_t, Q = Q, P_N = P_N, P_B = P_B, no_trade = no_trade,
         q_N = Q / n_N, q_B = Q / n_B,
         CS_N = CS_N, PS_N = PS_N, CS_B = CS_B, PS_B = PS_B,
         TS_N = CS_N + PS_N, NSB = PS_N + PS_B + CS_B,
         wrong_sum = CS_N + PS_N + CS_B + PS_B,     # counts CS_N twice
         value = value, cost_N = cost_N, cost_other = cost_other,
         NSB_resource = value - cost_N - cost_other,
         # One firm (identical firms, so 1/n of the industry's surplus)
         PS_firm_N = PS_N / n_N, profit_firm_N = PS_N / n_N - FC,
         PS_firm_B = PS_B / n_B, profit_firm_B = PS_B / n_B - FC,
         eps_D_N = el(-1 / (b + g), P_N), eps_S_N = el(1 / s, P_N),
         eps_D_B = el(-1 / b, P_B), eps_S_B = el(1 / g, P_B))
  }
  before <- state(u); after <- state(u - k)

  # Changes: the direct difference, and the tutor-note formulae (valid when
  # trade happens in both equilibria)
  dQ   <- after$Q - before$Q
  dP_N <- after$P_N - before$P_N
  dP_B <- after$P_B - before$P_B
  f <- function(x) if (indeterminate) NA_real_ else x
  list(A = A, b = b, c = c, g = g, u = u, s = s, k = k, n_N = n_N, n_B = n_B,
       FC = FC,
       before = before, after = after,
       dQ = dQ, dP_N = dP_N, dP_B = dP_B,
       dQ_formula   = f(k / denom),
       dP_N_formula = f(-k * (b + g) / denom),
       dP_B_formula = f(-k * b / denom),
       # Pass-through: the share of a cost change that reaches the price
       rho_N     = f((b + g) / denom),                 # upstream
       rho_B     = if (b + g > 0) b / (b + g) else NA_real_,   # downstream
       rho_total = f(b / denom),                       # whole chain
       dNSB = after$NSB - before$NSB,
       indeterminate = indeterminate)
}


### 15. nickel_market_outcomes(): the nickel market on its own (Fig. 4) ----
# Exercise 2 and the Figure 4 app: inverse demand P = A - bQ and supply
# P = u + sQ, with A and u chosen so that the curves PIVOT around
# E0 = (Q0, P0) when the slopes b and s change (A = P0 + b*Q0,
# u = P0 - s*Q0), so that the starting point always stays at (40, 90).
# k = cost reduction. Pass-through rho = b / (b + s): b = 0 (flat demand)
# gives 0, s = 0 (flat supply) gives 1, b + s = 0 is not determined.
nickel_market_outcomes <- function(b = 2, s = 1, k = 30, E0 = c(40, 90)) {
  check_firm_number(b, "b", min = 0, what = "demand cannot slope up")
  check_firm_number(s, "s", min = 0, what = "supply cannot slope down")
  check_firm_number(k, "k")
  if (!is.numeric(E0) || length(E0) != 2 || any(is.na(E0)) || any(E0 <= 0)) {
    stop("'E0' must be two positive numbers, c(Q0, P0).", call. = FALSE)
  }
  Q0 <- E0[1]; P0 <- E0[2]
  A <- P0 + b * Q0; u <- P0 - s * Q0
  na <- NA_real_
  indeterminate <- b + s <= 0
  if (indeterminate) {
    Q1 <- na; P1 <- na
  } else {
    # A - bQ = u - k + sQ  =>  Q1 = Q0 + k / (b + s), and P1 on demand
    Q1 <- max(0, Q0 + k / (b + s))
    P1 <- if (Q1 > 0) A - b * Q1 else na
  }
  el <- function(dQdP, P, Q) if (is.na(Q) || Q <= 0) na else dQdP * P / Q
  list(A = A, u = u, u1 = u - k, b = b, s = s, k = k,
       Q0 = Q0, P0 = P0, Q1 = Q1, P1 = P1,
       dQ = Q1 - Q0, dP = P1 - P0,
       rho = if (indeterminate) na else b / (b + s),
       CS0 = 0.5 * b * Q0^2, PS0 = 0.5 * s * Q0^2,
       CS1 = if (is.na(Q1)) na else 0.5 * b * Q1^2,
       PS1 = if (is.na(Q1)) na else 0.5 * s * Q1^2,
       eps_D0 = el(-1 / b, P0, Q0), eps_S0 = el(1 / s, P0, Q0),
       eps_D1 = el(-1 / b, P1, Q1), eps_S1 = el(1 / s, P1, Q1),
       indeterminate = indeterminate,
       # (supply after the innovation starts below zero: the first units
       # would cost less than nothing; possible with a steep s in the app)
       negative_cost = u - k < 0)
}


### 16. elasticity_point(): slope versus elasticity at one point (Fig. 5) ----
# Demand in direct form Q = intercept_Q + slope_dQdP * P. At the price P:
# the quantity, the factor P/Q, the point elasticity (dQ/dP) x (P/Q) and a
# word for it. E.g. elasticity_point(-0.5, 85, 90)$elasticity = -1.125.
elasticity_point <- function(slope_dQdP, intercept_Q, P) {
  check_firm_number(slope_dQdP, "slope_dQdP")
  check_firm_number(intercept_Q, "intercept_Q")
  check_firm_number(P, "P", min = 0, what = "a price cannot be negative")
  Q <- intercept_Q + slope_dQdP * P
  if (Q <= 0) {
    return(list(P = P, Q = max(Q, 0), slope = slope_dQdP, P_over_Q = NA_real_,
                elasticity = NA_real_, word = "not defined (Q = 0)"))
  }
  e <- slope_dQdP * P / Q
  word <- if (abs(abs(e) - 1) < 1e-9) "unit elastic"
          else if (abs(e) > 1) "elastic" else "inelastic"
  list(P = P, Q = Q, slope = slope_dQdP, P_over_Q = P / Q, elasticity = e,
       word = word)
}


### 17. draw_chain_firm(): one nickel producer (Figure 2) ----
# Marginal cost MC = c0 + d*q ("MC = supply curve of the firm"), the market
# price P_N, the firm's choice q* (P_N = MC), and the areas TVC (under MC
# from 0 to q*) and PS (between the price line and MC). The tutor version
# prints the numbers in the areas (TVC = 280, PS = 80) and q* = 4; the
# student version only names them.
# q (app slider, optional): a quantity other than q*. Above q* the extra
# units lose money (red: MC > P_N); below q* the units from q to q* are not
# made and their surplus is forgone (hatched), as Tutorial 1 Figure 5a.
draw_chain_firm <- function(P = 90, q = NULL, c0 = 50, d = 10, FC = 20,
                            xlim = c(0, 8), ylim = c(0, 120), main = NULL,
                            tick_step = NULL, fit_top = FALSE,
                            version = c("tutor", "student")) {
  version <- match.arg(version)
  tutor <- version == "tutor"
  if (!is.null(q)) check_firm_number(q, "q", min = 0,
                                     what = "a quantity cannot be negative")
  out <- firm_linear_outcomes(c = c0, d = d, P = P, q = q, FC = FC)
  mc <- function(x) c0 + d * x
  Qs <- out$Q_star
  rx <- diff(xlim); ry <- diff(ylim); pad_x <- 0.015 * rx; pad_y <- 0.02 * ry
  has_q <- !is.null(q) && abs(q - Qs) > 1e-9
  q_end <- if (has_q && q < Qs) q else Qs     # PS and TVC are shaded to here
  over  <- has_q && q > Qs                    # extra units beyond q*

  # Legend entries (counted before the canvas is drawn, for fit_top)
  items <- character(0); fills <- character(0); borders <- character(0)
  dens <- numeric(0)
  add <- function(label, col, border = NA, density = NA_real_) {
    items <<- c(items, label); fills <<- c(fills, col)
    borders <<- c(borders, border); dens <<- c(dens, density)
  }
  if (q_end > 0) add("Producer surplus (PS)", firm_fill(peib_cols["ps"]))
  if (q_end > 0 || over) add("Total variable cost (TVC)",
                             firm_fill(peib_cols["tvc"]))
  if (over) add("Loss on extra units (MC > P_N)",
                firm_fill(peib_cols["loss"], 0.6))
  if (has_q && q < Qs) add("Forgone surplus (units not made)",
                           peib_cols["ps"], peib_cols["ps"], density = 30)

  op <- par(c("mar", "las")); on.exit(par(op))
  firm_canvas(xlim, ylim, main, ylab = "Price (P_N) and cost",
              xlab = "Quantity of one firm (q)", tick_step = tick_step,
              n_legend = if (fit_top) length(items) else NULL)
  curves <- function(x) list(mc(x), rep(P, length(x)))

  # Shaded areas first (lines go on top)
  xs <- seq(0, max(q_end, 0), length.out = 101)
  m  <- pmax(0, mc(xs))
  if (q_end > 0) {
    # TVC: the area under MC from 0 to q*; PS: between P_N and MC
    polygon(c(0, xs, q_end), c(0, m, 0), col = firm_fill(peib_cols["tvc"]),
            border = NA)
    polygon(c(xs, rev(xs)), c(rep(P, length(xs)), rev(m)),
            col = firm_fill(peib_cols["ps"]), border = NA)
  }
  if (over) {
    # Units beyond q*: revenue covers the cost below P_N (purple), the
    # cost above P_N is a loss (red)
    xl <- seq(Qs, q, length.out = 101)
    if (P > 0) rect(Qs, 0, q, P, col = firm_fill(peib_cols["tvc"]), border = NA)
    polygon(c(xl, rev(xl)), c(pmax(mc(xl), P), rep(P, length(xl))),
            col = firm_fill(peib_cols["loss"], 0.6), border = NA)
  }
  if (has_q && q < Qs) {
    xf <- seq(q, Qs, length.out = 101)
    polygon(c(xf, rev(xf)), c(rep(P, length(xf)), rev(pmax(0, mc(xf)))),
            col = peib_cols["ps"], border = peib_cols["ps"], density = 20,
            angle = 45)
  }

  # MC line, price line, q*
  avoid <- list()
  avoid <- firm_add_box(avoid, chain_line(c0, d, "MC = supply curve of the firm",
                                          xlim, ylim, cex = 0.85))
  avoid <- firm_add_box(avoid, firm_price_line(P, xlim, ylim, name = "P_N"))
  if (Qs > 0) {
    if (tutor) {
      avoid <- firm_add_box(avoid, firm_qstar_guide(Qs, P, xlim, ylim))
    } else {
      # Student version: the guide is labelled "q*" without its value
      # (students calculate q* = 4 in Question 1.1c)
      segments(Qs, 0, Qs, P, lty = 2, col = "grey30")
      points(Qs, P, pch = 19, cex = 0.9)
      avoid <- firm_add_box(avoid, peib_q_label(Qs, "q*", xlim, ylim, avoid))
    }
    avoid <- firm_add_box(avoid, c(l = Qs, r = Qs, b = 0, t = P))
  }
  if (has_q) {
    top_q <- max(P, mc(q))
    segments(q, 0, q, top_q, lty = 2, col = "grey30")
    avoid <- firm_add_box(avoid, c(l = q, r = q, b = 0, t = top_q))
    avoid <- firm_add_box(avoid, peib_q_label(q, paste0("q = ", firm_fmt(q)),
                                              xlim, ylim, avoid))
  }

  # Area labels: plain names, with the numbers in the tutor version
  num <- function(name, x) if (tutor) paste0(name, " = ", chain_fmt(x)) else name
  tvc_val <- if (has_q && q < Qs) out$TVC else out$TVC_star
  ps_val  <- if (has_q && q < Qs) out$TR - out$TVC else out$PS
  if (q_end > 0) {
    avoid <- firm_add_box(avoid, chain_label_near(
      num("TVC", tvc_val), c(xlim[1] + pad_x, q_end - pad_x),
      c(ylim[1] + pad_y, P), q_end / 2, 0.4 * mc(q_end / 2), curves, avoid,
      ok = function(x, y) y < mc(x), cex = 0.9, fallback = FALSE))
    avoid <- firm_add_box(avoid, chain_label_near(
      num("PS", ps_val), c(xlim[1] + pad_x, q_end - pad_x),
      c(ylim[1], P - pad_y), q_end / 3, (max(0, c0) + 2 * P) / 3, curves,
      avoid, ok = function(x, y) y > mc(x), cex = 0.9, fallback = FALSE))
  }
  if (over) {
    firm_place_label(num("Loss", out$loss_extra_units),
                     c(Qs + pad_x, q - pad_x), c(P, min(mc(q), ylim[2])),
                     (Qs + 2 * q) / 3, (2 * P + min(mc(q), ylim[2])) / 3,
                     curves, avoid, ok = function(x, y) y > P && y < mc(x),
                     cex = 0.8)
  }
  if (out$no_production) {
    firm_message(paste0("No production: the price (", chain_fmt(P),
                        ") is below\nthe cost of the first unit (",
                        chain_fmt(c0), ")"), xlim, ylim)
  }
  firm_legend(items, fills, xlim, ylim, borders = borders,
              density = if (any(!is.na(dens))) dens else NULL)
  invisible(out)
}


### 18. draw_chain_supply(): from the firm to the industry (Figures 3, 3b) ----
# Two panels with the same price axis: left one firm (q), right the
# industry of n_firms identical firms (Q). Industry supply adds the firms'
# QUANTITIES at each price (horizontal summation): P = c0 + (d / n) * Q.
# what = "firm_industry" (Figure 3): the firm's MC and the industry supply
#   curve, with guides at the prices in 'prices' (90: q = 4, Q = 40;
#   120: q = 7, Q = 70) and the note "10 firms x 4 = 40". show_entry adds
#   the curve with one more firm (dashed, Question 1.3c).
# what = "innovation" (Figure 3b): before (solid) and after (dashed) the
#   cost reduction k: both curves shift DOWN by k (vertical arrows); at
#   P = prices[1] the firm supplies k/d more (3 units) and the industry
#   n*k/d more (30 units) (horizontal arrows). No demand curve here.
# tick_step: see chain_tick_step(), e.g. list(c(1, 10), c(10, 10)).
draw_chain_supply <- function(what = c("firm_industry", "innovation"),
                              c0 = 50, d = 10, n_firms = 10, k = 30,
                              prices = c(90, 120), show_entry = FALSE,
                              xlim_firm = c(0, 8), xlim_industry = c(0, 80),
                              ylim = c(0, 140), main = NULL, tick_step = NULL,
                              fit_top = FALSE,
                              version = c("tutor", "student")) {
  what <- match.arg(what)
  version <- match.arg(version)
  tutor <- version == "tutor"
  check_firm_number(c0, "c0", min = 0, what = "a cost cannot be negative")
  check_firm_number(d, "d")
  if (d <= 0) stop("Slope 'd' must be positive (each extra unit costs more).",
                   call. = FALSE)
  check_firm_number(n_firms, "n_firms", min = 1, what = "at least one firm")
  if (n_firms != round(n_firms)) {
    stop("'n_firms' must be a whole number.", call. = FALSE)
  }
  check_firm_number(k, "k")
  if (!is.numeric(prices) || length(prices) < 1 || length(prices) > 2 ||
      any(is.na(prices)) || any(prices < 0)) {
    stop("'prices' must be one or two non-negative prices, e.g. c(90, 120).",
         call. = FALSE)
  }
  # Supply in direct form: one firm q(P) = (P - a0) / d, zero below a0
  q_of <- function(P, a0) max(0, (P - a0) / d)
  out <- list(q = sapply(prices, q_of, a0 = c0),
              Q = n_firms * sapply(prices, q_of, a0 = c0),
              q_after = q_of(prices[1], c0 - k),
              Q_after = n_firms * q_of(prices[1], c0 - k),
              Q_entry = (n_firms + 1) * q_of(prices[1], c0),
              industry_slope = d / n_firms,
              shift_vertical = k, shift_firm = k / d,
              shift_industry = n_firms * k / d)

  op <- par(c("mfrow", "mar", "las")); on.exit(par(op))
  par(mfrow = c(1, 2))
  n_leg <- if (fit_top) 0 else NULL
  pm <- if (is.null(main)) NULL else ""     # room for a figure title
  for (i in 1:2) {
    firm <- i == 1
    xl <- if (firm) xlim_firm else xlim_industry
    rx <- diff(xl); ry <- diff(ylim)
    slope <- if (firm) d else d / n_firms
    n_txt <- paste0(n_firms, " firms")
    firm_canvas(xl, ylim, pm, ylab = "Price (P_N) and cost",
                xlab = if (firm) "Quantity of one firm (q)"
                       else "Quantity of the industry (Q_N)",
                tick_step = chain_tick_step(tick_step, i), n_legend = n_leg)
    avoid <- list()
    if (what == "firm_industry") {
      curves <- function(x) {
        l <- list(c0 + slope * x)
        if (!firm && show_entry) l <- c(l, list(c0 + d / (n_firms + 1) * x))
        l
      }
      avoid <- firm_add_box(avoid, chain_line(
        c0, slope, if (firm) "MC = firm supply" else paste0("S (", n_txt, ")"),
        xl, ylim, cex = 0.9))
      if (!firm && show_entry) {
        avoid <- firm_add_box(avoid, chain_line(
          c0, d / (n_firms + 1), paste0("S (", n_firms + 1, " firms)"), xl,
          ylim, lty = 2, cex = 0.8))
      }
      # Guides at each price: across to the curve, then down to the axis
      for (j in seq_along(prices)) {
        x <- if (firm) out$q[j] else out$Q[j]
        P <- prices[j]
        if (x <= 0 || x > xl[2] || P > ylim[2]) next
        avoid <- c(avoid, chain_guides(x, P, xl, ylim))
        points(x, P, pch = 19, cex = 0.9)
        if (tutor) avoid <- firm_add_box(avoid, peib_q_label(
          x, paste0(if (firm) "q = " else "Q = ", chain_fmt(x)), xl, ylim,
          avoid))
      }
      if (!firm && tutor && out$Q[1] > 0 && out$Q[1] < xl[2]) {
        # "10 firms x 4 = 40": below the curve, right of the first guide
        lab <- paste0(n_txt, " x ", chain_fmt(out$q[1]), " = ",
                      chain_fmt(out$Q[1]))
        sz <- firm_text_size(lab, 0.85, 2)
        avoid <- firm_add_box(avoid, chain_label_near(
          lab, c(out$Q[1] + 0.01 * rx, xl[2]),
          c(ylim[1] + 0.08 * ry, prices[1]),
          out$Q[1] + 0.03 * rx + sz[["w"]] / 2, prices[1] - 0.15 * ry,
          curves, avoid, ok = function(x, y) y < c0 + slope * x, cex = 0.85))
      }
      if (!firm && show_entry && out$Q_entry > out$Q[1]) {
        avoid <- chain_harrow(out$Q[1], min(out$Q_entry, xl[2]), prices[1],
                              if (tutor) paste0("+", chain_fmt(out$Q_entry -
                                                               out$Q[1]))
                              else NULL, curves, avoid)
      }
    } else {
      # Innovation: before (solid) and after (dashed, shifted down by k)
      curves <- function(x) list(c0 + slope * x, c0 - k + slope * x)
      avoid <- firm_add_box(avoid, chain_line(
        c0, slope, if (firm) "MC0" else "S0", xl, ylim, cex = 0.9))
      avoid <- firm_add_box(avoid, chain_line(
        c0 - k, slope, if (firm) "MC1" else "S1", xl, ylim, lty = 2, cex = 0.9))
      P  <- prices[1]
      x0 <- if (firm) out$q[1] else out$Q[1]
      x1 <- if (firm) out$q_after else out$Q_after
      if (x0 > 0 && x0 < xl[2] && P < ylim[2]) {
        # The price line at P and the two quantities on it
        segments(xl[1], P, min(x1, xl[2]), P, lty = 2, col = "grey30")
        segments(x0, ylim[1], x0, P, lty = 2, col = "grey30")
        avoid <- c(avoid, list(c(l = xl[1], r = min(x1, xl[2]), b = P, t = P),
                               c(l = x0, r = x0, b = ylim[1], t = P)))
        points(x0, P, pch = 19, cex = 0.9)
        if (x1 < xl[2]) {
          segments(x1, ylim[1], x1, P, lty = 2, col = "grey30")
          avoid <- c(avoid, list(c(l = x1, r = x1, b = ylim[1], t = P)))
          points(x1, P, pch = 19, cex = 0.9)
        }
        # Vertical shift: the cost of the same quantity falls by k
        avoid <- chain_varrow(x0, P, P - k,
                              if (tutor) paste0("-", chain_fmt(k), " (cost)")
                              else "cost falls", curves, avoid)
        # Horizontal shift: at the same price, more is supplied
        h <- x1 - x0
        avoid <- chain_harrow(x0, min(x1, xl[2]), P,
                              if (tutor) paste0("+", chain_fmt(h), " units")
                              else "more supplied", curves, avoid)
      }
    }
  }
  chain_fig_title(main, peib_top_margin(pm, n_leg))
  invisible(out)
}


### 19. draw_chain_nickel(): the nickel market before and after (Fig. 4) ----
# Demand P_N = A - b*Q, supply before S0: P_N = u + s*Q and after S1:
# P_N = u - k + s*Q (dashed), with A and u from nickel_market_outcomes()
# (handout: 170 - 2Q, 50 + Q, 20 + Q). panel = "before" shades CS_N and
# PS_N at E0 (Figure 4a), "after" at E1 (Figure 4b). E0 is marked with
# dashed guides in both versions; the tutor version also labels E1 and adds
# the arrows "-30 (cost)" (between S0 and S1 at Q0) and "-20 (price)" (on
# the price axis, from P0 to P1). The student version draws S1 but does not
# mark E1 (Question 2.1b).
draw_chain_nickel <- function(panel = c("before", "after"), b = 2, s = 1,
                              k = 30, E0 = c(40, 90),
                              xlim = c(0, 90), ylim = c(0, 180), main = NULL,
                              tick_step = NULL, fit_top = FALSE,
                              version = c("tutor", "student"),
                              show_cs = TRUE, show_ps = TRUE) {
  panel <- match.arg(panel)
  version <- match.arg(version)
  tutor <- version == "tutor"
  out <- nickel_market_outcomes(b, s, k, E0)
  A <- out$A; u <- out$u
  rx <- diff(xlim); ry <- diff(ylim); pad_x <- 0.015 * rx; pad_y <- 0.02 * ry
  dem <- function(x) A - b * x
  s0  <- function(x) u + s * x
  s1  <- function(x) u - k + s * x
  after <- panel == "after"
  Q <- if (after) out$Q1 else out$Q0
  P <- if (after) out$P1 else out$P0
  u_t <- if (after) u - k else u
  inside <- function(x, y) !is.na(x) && !is.na(y) && x > 0 && x < xlim[2] &&
    y > ylim[1] && y < ylim[2]
  shade <- inside(Q, P)

  items <- character(0); fills <- character(0)
  add <- function(label, col) { items <<- c(items, label); fills <<- c(fills, col) }
  if (shade && show_cs) add("Consumer surplus (CS_N)", firm_fill(peib_cols["cs"]))
  if (shade && show_ps) add("Producer surplus (PS_N)", firm_fill(peib_cols["ps"]))

  op <- par(c("mar", "las")); on.exit(par(op))
  firm_canvas(xlim, ylim, main, ylab = "Price of nickel (P_N)",
              xlab = "Quantity of nickel (Q_N)", tick_step = tick_step,
              n_legend = if (fit_top) length(items) else NULL)
  curves <- function(x) list(dem(x), s0(x), s1(x))

  # Shaded areas first: triangles between the price line and the curves
  # (clip() cuts them at the axes if an intercept lies outside the box)
  if (shade && show_cs) polygon(c(0, 0, Q), c(P, A, P),
                                col = firm_fill(peib_cols["cs"]), border = NA)
  if (shade && show_ps) polygon(c(0, 0, Q), c(P, u_t, P),
                                col = firm_fill(peib_cols["ps"]), border = NA)

  # Curves: S1 dashed, then S0 and D
  avoid <- list()
  avoid <- firm_add_box(avoid, chain_line(u - k, s, "S1", xlim, ylim, lty = 2))
  avoid <- firm_add_box(avoid, chain_line(u, s, "S0", xlim, ylim))
  avoid <- firm_add_box(avoid, chain_line(A, -b, "D", xlim, ylim,
                                          col = peib_cols["demand"]))

  if (out$indeterminate) {
    firm_message(paste0("Both curves are flat (b = s = 0): the new ",
                        "equilibrium\nis not determined"), xlim, ylim)
    firm_legend(items, fills, xlim, ylim)
    return(invisible(out))
  }

  # E0 (both versions) and E1 (tutor version) with dashed guides
  e_lab <- function(nm, x, y) {
    if (tutor) paste0(nm, " = (", chain_fmt(x), ", ", chain_fmt(y), ")") else nm
  }
  e_alt <- function(nm, x, y) {
    if (tutor) c(e_lab(nm, x, y), paste0(nm, "\n(", chain_fmt(x), ", ",
                                         chain_fmt(y), ")")) else nm
  }
  avoid <- c(avoid, chain_guides(out$Q0, out$P0, xlim, ylim))
  if (tutor && inside(out$Q1, out$P1)) {
    avoid <- c(avoid, chain_guides(out$Q1, out$P1, xlim, ylim))
  }
  # Area labels first, so that the arrow labels find room around them
  if (shade) {
    cs <- if (after) out$CS1 else out$CS0
    ps <- if (after) out$PS1 else out$PS0
    num <- function(nm, x) if (tutor) paste0(nm, " = ", chain_fmt(x)) else nm
    if (show_cs) avoid <- firm_add_box(avoid, chain_label_near(
      num("CS_N", cs), c(xlim[1] + pad_x, Q - pad_x), c(P, ylim[2]), Q / 3,
      (min(A, ylim[2]) + 2 * P) / 3, curves, avoid,
      ok = function(x, y) y < dem(x) && y > P, cex = 0.9, fallback = FALSE))
    if (show_ps) avoid <- firm_add_box(avoid, chain_label_near(
      num("PS_N", ps), c(xlim[1] + pad_x, Q - pad_x), c(ylim[1], P), Q / 3,
      (max(u_t, ylim[1]) + 2 * P) / 3, curves, avoid,
      ok = function(x, y) y > u_t + s * x && y < P, cex = 0.9,
      fallback = FALSE))
  }
  # Arrows (tutor): the cost shift at Q0 and the price change on the axis
  if (tutor) {
    avoid <- chain_varrow(out$Q0, out$P0, out$P0 - k,
                          paste0("-", chain_fmt(k), " (cost)"), curves, avoid,
                          sides = c(1, -1))
    if (inside(out$Q1, out$P1) && abs(out$dP) > 1e-9) {
      dp <- out$dP
      # (label just above the arrow in 4a, just below it in 4b: the
      # middle of the arrow lies inside the PS_N area of 4a)
      avoid <- chain_varrow(xlim[1] + 0.03 * rx, out$P0, out$P1,
                            paste0(if (dp < 0) "-" else "+",
                                   chain_fmt(abs(dp)), " (price)"),
                            curves, avoid, sides = 1,
                            y_pref = if (after) min(out$P0, out$P1) - 0.04 * ry
                                     else max(out$P0, out$P1) + 0.04 * ry)
    }
  }
  avoid <- chain_point(out$Q0, out$P0, e_lab("E0", out$Q0, out$P0), curves,
                       avoid, dir = c(1, 1), alts = e_alt("E0", out$Q0, out$P0))
  if (tutor && inside(out$Q1, out$P1)) {
    avoid <- chain_point(out$Q1, out$P1, e_lab("E1", out$Q1, out$P1), curves,
                         avoid, dir = c(1, -1),
                         alts = e_alt("E1", out$Q1, out$P1))
  }

  if (!inside(out$Q1, out$P1) && after) {
    firm_message("The new equilibrium lies outside the axes", xlim, ylim)
  }
  firm_legend(items, fills, xlim, ylim)
  invisible(out)
}


### 20. draw_chain_elasticity(): slope versus elasticity (Figure 5) ----
# A demand curve in direct form Q = intercept_Q + slope * P, drawn as usual
# with P on the vertical axis, a point at the price P (app slider) with its
# guides, a fixed second marker, and a box with dQ/dP (the same at every
# point), P/Q and the elasticity (different at every point).
# curve = "nickel":  Q = 85 - 0.5P, point at E0 (P = 90), marker E1 (P = 70)
# curve = "example": Q = 100 - 2P (technical box), point at P = 20, marker
#                    at P = 40
draw_chain_elasticity <- function(curve = c("nickel", "example"), P = NULL,
                                  show_marker = TRUE, xlim = NULL, ylim = NULL,
                                  main = NULL, tick_step = NULL,
                                  fit_top = FALSE,
                                  version = c("tutor", "student")) {
  curve <- match.arg(curve)
  version <- match.arg(version)
  par_c <- if (curve == "nickel") {
    list(slope = -0.5, icpt = 85, P = 90, P2 = 70, name2 = "E1",
         xlim = c(0, 90), ylim = c(0, 180))
  } else {
    list(slope = -2, icpt = 100, P = 20, P2 = 40, name2 = "P = 40",
         xlim = c(0, 100), ylim = c(0, 50))
  }
  if (is.null(P)) P <- par_c$P
  if (is.null(xlim)) xlim <- par_c$xlim
  if (is.null(ylim)) ylim <- par_c$ylim
  out <- elasticity_point(par_c$slope, par_c$icpt, P)
  P_max <- -par_c$icpt / par_c$slope            # price at which Q = 0
  dem <- function(x) P_max + x / par_c$slope    # inverse form P(Q)
  rx <- diff(xlim); ry <- diff(ylim)

  op <- par(c("mar", "las")); on.exit(par(op))
  firm_canvas(xlim, ylim, main, ylab = "Price (P)", xlab = "Quantity (Q)",
              tick_step = tick_step, n_legend = if (fit_top) 0 else NULL)
  curves <- function(x) list(dem(x))
  avoid <- list()
  avoid <- firm_add_box(avoid, chain_line(P_max, 1 / par_c$slope, "D", xlim,
                                          ylim, col = peib_cols["demand"]))
  # The fixed second marker (hollow), then the movable point
  if (show_marker) {
    m2 <- elasticity_point(par_c$slope, par_c$icpt, par_c$P2)
    if (m2$Q > 0 && m2$Q < xlim[2]) {
      points(m2$Q, par_c$P2, pch = 21, bg = "white", cex = 1.1, lwd = 1.5)
      avoid <- firm_add_box(avoid, chain_label_near(
        paste0(par_c$name2, ": elasticity ", chain_fmt(m2$elasticity, 3)),
        m2$Q + c(-0.4, 0.4) * rx, par_c$P2 + c(-0.2, 0.2) * ry,
        m2$Q + 0.17 * rx, par_c$P2 + 0.03 * ry, curves, avoid, cex = 0.75,
        font = 1, col = "grey25"))
    }
  }
  if (out$Q > 0 && out$Q < xlim[2]) {
    avoid <- c(avoid, chain_guides(out$Q, P, xlim, ylim))
    avoid <- chain_point(out$Q, P, paste0("(Q, P) = (", chain_fmt(out$Q), ", ",
                                          chain_fmt(P), ")"), curves, avoid,
                         dir = c(1, 1))
  }
  # The box with the numbers, at the top right (above the demand curve)
  lines_txt <- c(
    paste0("Slope of the demand curve: dQ/dP = ", chain_fmt(par_c$slope, 3),
           " (the same at every point)"),
    if (is.na(out$elasticity)) "At this point Q = 0: elasticity not defined"
    else c(paste0("P/Q at this point = ", chain_fmt(P), "/", chain_fmt(out$Q),
                  " = ", chain_fmt(out$P_over_Q, 3)),
           paste0("Elasticity = ", chain_fmt(par_c$slope, 3), " x ",
                  chain_fmt(out$P_over_Q, 3), " = ",
                  chain_fmt(out$elasticity, 3), " (", out$word, ")")))
  txt <- paste(lines_txt, collapse = "\n")
  w <- strwidth(txt, cex = 0.8) + 0.03 * rx
  h <- strheight(txt, cex = 0.8) + 0.05 * ry
  x1 <- xlim[2] - 0.01 * rx; y1 <- ylim[2] - 0.02 * ry
  rect(x1 - w, y1 - h, x1, y1, col = "white", border = "grey60")
  text(x1 - w + 0.015 * rx, y1 - h / 2, txt, adj = c(0, 0.5), cex = 0.8)
  invisible(out)
}


### 21. draw_chain_linked(): the two linked markets (Figures 6, 7, 7b) ----
# Left panel: the nickel market (derived demand, S0, S1); right panel: the
# battery market (final demand, battery supply at the nickel price of each
# equilibrium). Both panels share the quantity axis, because Q_N = Q_B.
# show = "curves" (Figure 6): before and after curves in both panels, E0
#   and E1, dashed vertical lines at Q0 and Q1 across both panels, and
#   (tutor) the arrows "-20 (price)" (nickel), "input cost -20 (nickel
#   price)" (the battery supply curve shifts down by the nickel price
#   fall) and "-10 (price)" (batteries). (A curved arrow from one panel to
#   the other was tried and dropped: it has to cross the battery panel's
#   axis title.)
# show = "welfare" (Figures 7 and 7b, at = "before" or "after"): one set of
#   curves and the surplus areas. The auxiliary dashed line
#   P_N = (P_B - c) - g*Q, i.e. what the battery firm can pay for nickel at
#   the actual battery price, splits CS_N into an upper part (= CS_B, blue)
#   and a lower part (= PS_B, orange); PS_N is teal. The right panel uses
#   the same two colours for CS_B and PS_B, so CS_N = CS_B + PS_B is visible.
# Model arguments as chain_outcomes(); the app sliders are k, b, g and s.
draw_chain_linked <- function(show = c("curves", "welfare"),
                              at = c("before", "after"),
                              A = 220, b = 1, c = 50, g = 1, u = 50, s = 1,
                              k = 30, xlim = c(0, 90), ylim_N = c(0, 180),
                              ylim_B = c(0, 240), main = NULL,
                              tick_step = NULL, fit_top = FALSE,
                              version = c("tutor", "student")) {
  show <- match.arg(show)
  at <- match.arg(at)
  version <- match.arg(version)
  tutor <- version == "tutor"
  out <- chain_outcomes(A = A, b = b, c = c, g = g, u = u, s = s, k = k)
  e0 <- out$before; e1 <- out$after
  rx <- diff(xlim); pad_x <- 0.015 * rx
  welfare <- show == "welfare"
  ok_eq <- function(e, ylim) !out$indeterminate && !isTRUE(e$no_trade) &&
    e$Q < xlim[2] && e$P_N < ylim_N[2] && e$P_B < ylim_B[2] && e$P_N > 0
  st <- if (at == "after") e1 else e0
  shade <- welfare && ok_eq(st)
  num <- function(nm, x) if (tutor) paste0(nm, " = ", chain_fmt(x)) else nm
  e_lab <- function(nm, x, y) {
    if (tutor) paste0(nm, " = (", chain_fmt(x), ", ", chain_fmt(y), ")") else nm
  }
  e_alt <- function(nm, x, y) {
    if (tutor) c(e_lab(nm, x, y), paste0(nm, "\n(", chain_fmt(x), ", ",
                                         chain_fmt(y), ")")) else nm
  }

  # Legend across the figure (welfare figures): same colour = same amount
  items <- character(0); fills <- character(0)
  if (shade) {
    items <- c("CS_B (= upper part of CS_N)", "PS_B (= lower part of CS_N)",
               "PS_N")
    fills <- c(firm_fill(peib_cols["cs"]), firm_fill(peib_cols["ps"]),
               firm_fill(peib_cols["tr"], 0.6))
  }
  n_leg <- if (fit_top) 2 * ceiling(length(items) / 3) else NULL
  pm <- if (is.null(main)) NULL else ""

  op <- par(c("mfrow", "mar", "las")); on.exit(par(op))
  par(mfrow = c(1, 2))

  for (i in 1:2) {
    nickel <- i == 1
    ylim <- if (nickel) ylim_N else ylim_B
    ry <- diff(ylim); pad_y <- 0.02 * ry
    firm_canvas(xlim, ylim, pm,
                ylab = if (nickel) "Price of nickel (P_N)"
                       else "Price of batteries (P_B)",
                xlab = if (nickel) "Quantity of nickel (Q_N)"
                       else "Quantity of batteries (Q_B)",
                tick_step = chain_tick_step(tick_step, i), n_legend = n_leg)
    # The curves of this panel: demand intercept and slope, supply
    # intercepts before and after (battery supply: P_N + c + g*Q)
    if (nickel) {
      dA <- A - c; dB <- b + g; sl <- s
      i0 <- u; i1 <- u - k
      P0 <- e0$P_N; P1 <- e1$P_N
    } else {
      dA <- A; dB <- b; sl <- g
      i0 <- e0$P_N + c; i1 <- e1$P_N + c
      P0 <- e0$P_B; P1 <- e1$P_B
    }
    dem <- function(x) dA - dB * x
    show0 <- !welfare || at == "before"
    show1 <- !welfare || at == "after"
    curves <- function(x) {
      l <- list(dem(x))
      if (show0 && is.finite(i0)) l <- c(l, list(i0 + sl * x))
      if (show1 && is.finite(i1)) l <- c(l, list(i1 + sl * x))
      l
    }
    avoid <- list()

    # Welfare areas first
    if (shade) {
      Q <- st$Q; P <- if (nickel) st$P_N else st$P_B
      i_t <- if (at == "after") i1 else i0
      if (nickel) {
        # The split line: P_N = (P_B - c) - g*Q, from (0, P_N + g*Q) to E
        top_split <- P + g * Q
        polygon(c(0, 0, Q), c(top_split, dA, P),
                col = firm_fill(peib_cols["cs"]), border = NA)
        polygon(c(0, 0, Q), c(P, top_split, P),
                col = firm_fill(peib_cols["ps"]), border = NA)
        polygon(c(0, 0, Q), c(P, i_t, P),
                col = firm_fill(peib_cols["tr"], 0.6), border = NA)
        segments(0, top_split, Q, P, lty = 2, lwd = 1.6, col = "grey15")
        # Outline of the whole CS_N triangle, so that it reads as one area
        polygon(c(0, 0, Q), c(P, dA, P), border = peib_cols["demand"],
                lwd = 1.2)
      } else {
        polygon(c(0, 0, Q), c(P, dA, P), col = firm_fill(peib_cols["cs"]),
                border = NA)
        polygon(c(0, 0, Q), c(P, i_t, P), col = firm_fill(peib_cols["ps"]),
                border = NA)
      }
    }

    # Curves
    if (show1 && is.finite(i1)) {
      avoid <- firm_add_box(avoid, chain_line(
        i1, sl, "S1", xlim, ylim, lty = if (welfare) 1 else 2))
    }
    if (show0 && is.finite(i0)) {
      avoid <- firm_add_box(avoid, chain_line(i0, sl, "S0", xlim, ylim))
    }
    avoid <- firm_add_box(avoid, chain_line(dA, -dB, "D", xlim, ylim,
                                            col = peib_cols["demand"]))

    if (out$indeterminate || isTRUE(e0$no_trade)) {
      firm_message(if (out$indeterminate)
                     "All slopes are zero (b = g = s = 0):\nthe equilibrium is not determined"
                   else "No trade: the first battery is worth less\nthan the cost of making it",
                   xlim, ylim)
      next
    }

    if (!welfare) {
      # Figure 6: E0 (and E1, tutor) with guides; vertical lines over the
      # whole height at Q0 and Q1, so that Q_N = Q_B is visible
      has1 <- tutor && ok_eq(e1)
      avoid <- c(avoid, chain_guides(e0$Q, P0, xlim, ylim, full = TRUE))
      if (has1) avoid <- c(avoid, chain_guides(e1$Q, P1, xlim, ylim, full = TRUE))
      if (tutor) {
        if (nickel && has1) {
          # The nickel price falls (on the price axis)
          avoid <- chain_varrow(xlim[1] + 0.03 * rx, P0, P1,
                                paste0(chain_fmt(P1 - P0), " (price)"),
                                curves, avoid, sides = 1)
        }
        if (!nickel && has1) {
          # The battery supply curve shifts down by the nickel price change
          # (its intercept is P_N + c), and the battery price falls
          avoid <- chain_varrow(xlim[1] + 0.03 * rx, i0, i1,
                                paste0("input cost ", chain_fmt(i1 - i0),
                                       " (nickel price)"),
                                curves, avoid, sides = 1,
                                y_pref = min(i0, i1) - 0.07 * ry)
          avoid <- chain_varrow(xlim[1] + 0.03 * rx, P0, P1,
                                paste0(chain_fmt(P1 - P0), " (price)"),
                                curves, avoid, sides = 1)
        }
      }
      # (battery panel: the two-line label first, it fits closer to E0)
      alt0 <- e_alt("E0", e0$Q, P0)
      if (!nickel) alt0 <- rev(alt0)
      avoid <- chain_point(e0$Q, P0, e_lab("E0", e0$Q, P0), curves, avoid,
                           dir = c(-1, 1), alts = alt0)
      if (has1) {
        avoid <- chain_point(e1$Q, P1, e_lab("E1", e1$Q, P1), curves, avoid,
                             dir = c(1, -1), alts = e_alt("E1", e1$Q, P1))
      }
      if (tutor && !has1 && !ok_eq(e1)) {
        firm_message("The new equilibrium lies outside the axes", xlim, ylim)
      }
      if (!ok_eq(e0)) {
        firm_message("The equilibrium lies outside the axes", xlim, ylim,
                     y_frac = 0.6)
      }
    } else if (shade) {
      # Figures 7 and 7b: one equilibrium, its guides and the area labels
      Q <- st$Q; P <- if (nickel) st$P_N else st$P_B
      i_t <- if (at == "after") i1 else i0
      nm <- if (at == "after") "E1" else "E0"
      avoid <- c(avoid, chain_guides(Q, P, xlim, ylim))
      avoid <- chain_point(Q, P, e_lab(nm, Q, P), curves, avoid,
                           dir = c(1, 1), alts = e_alt(nm, Q, P))
      if (nickel) {
        top_split <- P + g * Q
        split <- function(x) top_split - g * x
        curves_n <- function(x) c(curves(x), list(split(x)))
        lab_up <- if (tutor) paste0(chain_fmt(st$CS_B), " (= CS_B)")
                  else "(= CS_B)"
        b_up <- chain_label_near(
          lab_up, c(xlim[1] + pad_x, Q - pad_x), c(P, ylim[2]), Q / 4,
          (dA + top_split) / 2, curves_n, avoid,
          ok = function(x, y) y > split(x) && y < dem(x), cex = 0.8,
          fallback = FALSE)
        if (is.null(b_up)) {
          # The upper part is usually too thin for its label: put the label
          # just above the demand curve, with a leader line to a dot in
          # the middle of the blue triangle (its centroid)
          cx <- Q / 3; cy <- (dA + top_split + P) / 3
          sz <- firm_text_size(lab_up, 0.8, 2)
          b_up <- chain_label_near(
            lab_up, c(cx, xlim[2]), c(cy, ylim[2]),
            (dA - cy) / dB + 0.04 * rx + sz[["w"]] / 2, cy + 0.06 * ry,
            curves_n, avoid, ok = function(x, y) y - sz[["h"]] / 2 > dem(x),
            cex = 0.8, fallback = FALSE)
          if (!is.null(b_up)) {
            segments(cx, cy, b_up[["l"]], (b_up[["b"]] + b_up[["t"]]) / 2,
                     col = "grey15", lwd = 1.2)
            points(cx, cy, pch = 19, cex = 0.5, col = "grey15")
          }
        }
        avoid <- firm_add_box(avoid, b_up)
        avoid <- firm_add_box(avoid, chain_label_near(
          if (tutor) paste0(chain_fmt(st$PS_B), " (= PS_B)") else "(= PS_B)",
          c(xlim[1] + pad_x, Q - pad_x), c(P, top_split), Q / 4,
          (top_split + 2 * P) / 3, curves_n, avoid,
          ok = function(x, y) y < split(x) && y > P, cex = 0.8,
          fallback = FALSE))
        avoid <- firm_add_box(avoid, chain_label_near(
          num("PS_N", st$PS_N), c(xlim[1] + pad_x, Q - pad_x), c(i_t, P),
          Q / 3, (max(i_t, ylim[1]) + 2 * P) / 3, curves_n, avoid,
          ok = function(x, y) y < P && y > i_t + sl * x, cex = 0.85,
          fallback = FALSE))
        # The name of the whole outlined triangle, just above demand
        lab <- num("CS_N", st$CS_N)
        sz <- firm_text_size(lab, 0.9, 2)
        x_d <- Q * 0.35
        avoid <- firm_add_box(avoid, chain_label_near(
          lab, c(x_d, xlim[2]), c(P, ylim[2]),
          x_d + 0.03 * rx + sz[["w"]] / 2, dem(x_d) + 0.02 * ry, curves_n,
          avoid, ok = function(x, y) y > dem(x), cex = 0.9,
          col = peib_cols["demand"]))
      } else {
        avoid <- firm_add_box(avoid, chain_label_near(
          num("CS_B", st$CS_B), c(xlim[1] + pad_x, Q - pad_x), c(P, ylim[2]),
          Q / 3, (min(dA, ylim[2]) + 2 * P) / 3, curves, avoid,
          ok = function(x, y) y < dem(x) && y > P, cex = 0.85,
          fallback = FALSE))
        avoid <- firm_add_box(avoid, chain_label_near(
          num("PS_B", st$PS_B), c(xlim[1] + pad_x, Q - pad_x), c(i_t, P),
          Q / 3, (max(i_t, ylim[1]) + 2 * P) / 3, curves, avoid,
          ok = function(x, y) y < P && y > i_t + sl * x, cex = 0.85,
          fallback = FALSE))
      }
    } else {
      firm_message("The equilibrium lies outside the axes", xlim, ylim)
    }
  }
  chain_fig_legend(items, fills, ncol = min(3, max(1, length(items))))
  chain_fig_title(main, peib_top_margin(pm, n_leg))
  invisible(out)
}
