# ***********************************************************
# Title: SEES0082 Political Economy of International Business, UCL SSEES:
#        course website with interactive diagrams (Teaching_PEIB)
#
# Purpose: Lecture 5 data figure: global cross-border financial inflows by
#          investment type, 1980-2025, % of world GDP (stacked areas), with
#          reserve accumulation as a separate line; slide, csv and notes
#       Part 1: Style list, labels, data, settings of record
#       Part 2: build_bop_fig(): one flat builder for the stacked-area figure
#       Part 3: Figures: main (1980-2025) and from 1996; PNG, PDF, SVG
#       Part 4: PowerPoint slide (editable vector graphic + PNG fallback)
#       Part 5: Figure csv and headline numbers
#       Part 6: Methodology notes (markdown, numbers pasted from the data)
#
# Authors: Florian Münch
# Requires: data/imf_bop/clean/bop_world_year.csv, bop_coverage_year.csv,
#     bop_agg_check.csv (code/bop_clean.R); data/imf_bop/raw/
#     bop_metadata.json (code/bop_import.R); Parts 1 and 2 of code/master.R
#     (paths d_bop_clean, d_bop_raw, o_out_l5, f_pptx_template; packages
#     data.table, ggplot2, scales, ragg, systemfonts, svglite, officer,
#     rvg; theme_lecture() and save_lecture_fig() from functions_lecture.R)
#         ID variables: year
# Creates: in outputs/lecture5_capital_inflows/ (committed):
#     lecture05_bop_inflows.png/.pdf/.svg          (Part 3, main figure)
#     lecture05_bop_inflows_from1996.png/.pdf/.svg (Part 3, variant)
#     lecture05_bop_inflows.pptx                   (Part 4)
#     lecture05_bop_inflows_data.csv               (Part 5, figure data)
#     lecture05_bop_headline_numbers.csv           (Part 5)
#     lecture05_bop_methodology.md                 (Part 6)
# ***********************************************************

# Explanatory notes:
  # Stacked areas with mixed signs: ggplot stacks positive and negative
  # values separately at each x, but with annual points a category that
  # changes sign between two years would be drawn crossing through the
  # others. The builder therefore interpolates every category linearly on
  # a monthly grid and stacks on that grid: the areas pinch to zero where a
  # category crosses zero. At every grid point the signed heights of the
  # ribbons add up to the total line (the sum of linear interpolations is
  # the linear interpolation of the sum); the upper edge of the positive
  # stack equals the total only in years without negative components.
  # No title in the figure: the title goes on the slide. Every number in an
  # annotation or caption is pasted from the data with sprintf().
  # Colours: the five fills are the validated categorical slots of the
  # dataviz skill palette (adjacent pairs pass the colour-blindness check);
  # lines use grey text tones. Font: Segoe UI via theme_lecture().

# Safety check: stop with a clear message if master.R Parts 1-2 have not run
if (!exists("o_out_l5") || !exists("save_lecture_fig") || !exists("d_bop_clean")) {
  stop("o_out_l5, d_bop_clean or save_lecture_fig() is missing. Run ",
       "code/master.R (at least Parts 1 and 2) instead of this script on ",
       "its own.", call. = FALSE)
}
for (f in c("bop_world_year.csv", "bop_coverage_year.csv", "bop_agg_check.csv")) {
  if (!file.exists(file.path(d_bop_clean, f))) {
    stop("Missing ", file.path(d_bop_clean, f), ". Run code/bop_clean.R ",
         "(master Part 14) first.", call. = FALSE)
  }
}
dir.create(o_out_l5, recursive = TRUE, showWarnings = FALSE)


# ***********************************************************
# Part 1: Style list, labels, data, settings of record ----
# ***********************************************************
# What: one list with the look of the figure; display labels for the
#   snake_case components; the clean data.
bop_style <- list(
  # Stack order, bottom to top, and the fill of each layer
  stack = c("fdi", "portfolio_equity", "portfolio_debt", "other", "derivatives"),
  cols  = c(fdi              = "#2a78d6",   # blue
            portfolio_equity = "#eb6834",   # orange
            portfolio_debt   = "#1baf7a",   # aqua
            other            = "#eda100",   # yellow
            derivatives      = "#e87ba4"),  # magenta
  col_total    = "grey15",   # total gross inflows line
  col_reserves = "grey35",   # reserve accumulation line (dashed)
  col_band     = "grey93",   # partial-coverage band
  col_note     = "grey35",   # annotation text
  lwd_total    = 0.8,
  lwd_reserves = 0.9,
  lwd_outline  = 0.25,       # white outline between fills ("2px gap")
  base_size    = 16,
  width        = 11,         # inches (16:9 slide body)
  height       = 5.8,
  margin_r     = 150,        # pt, room for the direct labels of the lines
  wrap_width   = 165,        # caption characters per line
  grid_step    = 1 / 12,     # monthly interpolation grid
  band_end     = NA          # set below from the data: Japan's first year - 0.5
)
component_labels <- c(
  fdi              = "Foreign direct investment",
  portfolio_equity = "Portfolio equity",
  portfolio_debt   = "Portfolio debt",
  other            = "Other investment (bank loans, deposits, trade credit)",
  derivatives      = "Financial derivatives")

world    <- fread(file.path(d_bop_clean, "bop_world_year.csv"))
coverage <- fread(file.path(d_bop_clean, "bop_coverage_year.csv"))
aggcheck <- fread(file.path(d_bop_clean, "bop_agg_check.csv"))
panel    <- fread(file.path(d_bop_clean, "bop_country_year.csv"))
meta     <- jsonlite::read_json(file.path(d_bop_raw, "bop_metadata.json"))
first_year <- min(world$year)
last_year  <- max(world$year)
bop_versions <- rbindlist(meta$dataflows)
# First and last year with FDI inflow data per economy (for the band label
# and the notes: never typed)
rep_years <- panel[!is.na(fdi), .(first = min(year), last = max(year)), by = code]
fy <- function(code_) rep_years[code == code_, first]
ly <- function(code_) rep_years[code == code_, last]
jpn_first <- fy("JPN")
bop_style$band_end <- jpn_first - 0.5   # partial coverage ends before Japan
cat("Settings of record: years", first_year, "-", last_year,
    "| IMF data downloaded", meta$downloaded, "| dataflows",
    paste(bop_versions$id, bop_versions$version, collapse = ", "), "\n")

# Numbers used in annotations, the slide and the notes (never typed)
peak     <- world[which.max(gross_inflows_pct_world_gdp), .(year, v = gross_inflows_pct_world_gdp)]
trough   <- world[year > peak$year][which.min(gross_inflows_pct_world_gdp),
                                    .(year, v = gross_inflows_pct_world_gdp)]
cov_pre  <- coverage[year < bop_style$band_end, .(lo = min(gdp_coverage_pct),
                                                  hi = max(gdp_coverage_pct))]
cov_post <- coverage[year >= bop_style$band_end, .(lo = min(gdp_coverage_pct),
                                                   hi = max(gdp_coverage_pct))]
n_rep    <- coverage[year %in% c(first_year, peak$year, last_year),
                     setNames(n_reporters, year)]
unsplit_share <- world[, 100 * sum(abs(portfolio_unsplit_usd)) /
                         sum(abs(gross_inflows_incl_unsplit_usd))]
unsplit_max   <- world[, max(abs(portfolio_unsplit_pct_world_gdp))]

# Caption (the reporter counts name the figure's first year, the peak year
# and the last year)
make_caption <- function(from_year) paste0(
  "Source: IMF Balance of Payments Statistics (country data, dataflow BOP ",
  bop_versions[id == "BOP", version], ") and World Economic Outlook (nominal ",
  "GDP in US dollars, dataflow WEO ", bop_versions[id == "WEO", version],
  "), IMF SDMX 3.0 API, downloaded ", substr(meta$downloaded, 1, 10), ". ",
  "Inflows = net incurrence of liabilities to non-residents (BPM6), summed over ",
  "all reporting economies (economies reporting FDI inflows: ",
  coverage[year == from_year, n_reporters], " in ", from_year, ", ", n_rep[[2]],
  " in ", peak$year, ", ", n_rep[[3]], " in ", last_year, "; fewer report ",
  "derivatives), in % of world GDP. ",
  "Negative values are net repayments or withdrawals. Reserve accumulation = net ",
  "acquisition of reserve assets by central banks (asset side), shown as a line, ",
  "not stacked. Portfolio flows reported without an equity/debt split (",
  sprintf("%.1f", unsplit_share), "% of gross flows) are not stacked. ",
  last_year, " is preliminary (", n_rep[[3]], " reporters).")
caption_text <- make_caption(first_year)


# ***********************************************************
# Part 2: build_bop_fig(): one flat builder for the figure ----
# ***********************************************************
# What: the stacked-area figure from from_year to the last year, with the
#   total and reserve lines, direct end labels, optional coverage band and
#   the two event annotations.
# How: monthly interpolation grid, positive and negative stacks computed
#   separately per grid point, one geom_ribbon per component.
# Used by: Part 3 (both figures) and Part 4 (slide)
build_bop_fig <- function(world, from_year, show_band, style, labels,
                          caption, x_breaks) {
  stack5 <- style$stack
  # Long table of the five components in % of world GDP
  long <- data.table::melt(
    world[year >= from_year, c("year", paste0(stack5, "_pct_world_gdp")), with = FALSE],
    id.vars = "year", variable.name = "cat", value.name = "v")
  long[, cat := sub("_pct_world_gdp", "", as.character(cat))]
  # Grid: monthly points plus the exact zero crossings of every component
  # (linear interpolation between two annual values of opposite sign), so
  # that a ribbon can end at zero height where its component changes sign
  setorder(long, cat, year)
  long[, v_next := shift(v, -1L), by = cat]
  cross <- long[!is.na(v_next) & sign(v) * sign(v_next) < 0,
                .(t0 = year + v / (v - v_next))]
  tgrid <- sort(unique(c(seq(from_year, max(world$year), by = style$grid_step),
                         cross$t0)))
  g <- long[, .(t = tgrid, v = stats::approx(year, v, xout = tgrid)$y), by = cat]
  g[abs(v) < 1e-9, v := 0]
  g[, cat := factor(cat, levels = stack5)]
  setorder(g, t, cat)
  g[, pos := pmax(v, 0)]
  g[, neg := pmin(v, 0)]
  g[, `:=`(top_pos = cumsum(pos), bottom_neg = cumsum(neg)), by = t]
  g[, ymin := fifelse(v >= 0, top_pos - pos, bottom_neg)]
  g[, ymax := fifelse(v >= 0, top_pos, bottom_neg - neg)]
  # One ribbon per run of equal sign. A zero point belongs to both the run
  # before and the run after it: the copy for the negative run sits at the
  # negative stack level, so each run pinches to zero height at the crossing.
  setorder(g, cat, t)
  g[, s := sign(v)]
  g[, run := NA_integer_]
  g[s != 0, run := data.table::rleid(s), by = cat]
  g[, run_prev := data.table::nafill(run, type = "locf"), by = cat]
  g[, run_next := data.table::nafill(run, type = "nocb"), by = cat]
  g_nonzero <- g[s != 0]
  g_zero_prev <- g[s == 0 & !is.na(run_prev)][, run := run_prev]
  g_zero_next <- g[s == 0 & !is.na(run_next) &
                   (is.na(run_prev) | run_next != run_prev)][, run := run_next]
  # The copy that opens a negative run (or closes one) sits on the negative stack
  neg_run_ids <- unique(g_nonzero[s < 0, .(cat, run)])
  for (gz in c("g_zero_prev", "g_zero_next")) {
    z <- get(gz)
    z <- merge(z, neg_run_ids[, .(cat, run, neg_run = TRUE)],
               by = c("cat", "run"), all.x = TRUE)
    z[neg_run == TRUE, `:=`(ymin = bottom_neg, ymax = bottom_neg)]
    z[is.na(neg_run), `:=`(ymin = top_pos, ymax = top_pos)]
    z[, neg_run := NULL]
    assign(gz, z)
  }
  g <- rbindlist(list(g_nonzero, g_zero_prev, g_zero_next), use.names = TRUE)
  g[, grp := paste(cat, run)]
  setorder(g, cat, run, t)
  # Lines and their end labels
  w <- world[year >= from_year]
  end_total <- w[year == max(year), gross_inflows_pct_world_gdp]
  end_res   <- w[year == max(year), reserves_pct_world_gdp]
  if (abs(end_total - end_res) < 1.6) {            # push labels apart
    shift <- (1.6 - abs(end_total - end_res)) / 2
    if (end_total >= end_res) { end_total <- end_total + shift; end_res <- end_res - shift
    } else { end_total <- end_total - shift; end_res <- end_res + shift }
  }
  y_top <- max(g$ymax) * 1.08
  pk <- w[which.max(gross_inflows_pct_world_gdp)]
  tr <- w[year > pk$year][which.min(gross_inflows_pct_world_gdp)]

  p <- ggplot2::ggplot()
  if (show_band) {
    p <- p +
      ggplot2::annotate("rect", xmin = from_year - 0.5, xmax = style$band_end,
                        ymin = -Inf, ymax = Inf, fill = style$col_band) +
      ggplot2::annotate("text", x = from_year - 0.2, y = y_top, hjust = 0, vjust = 1,
                        size = style$base_size * 0.26, colour = style$col_note,
                        lineheight = 0.95, family = theme_lecture()$text$family,
                        label = sprintf(paste0("Partial coverage before %d:\n",
                                               "reporting economies = %.0f-%.0f%% of world GDP\n",
                                               "(Japan reports from %d)"),
                                        jpn_first, cov_pre$lo, cov_pre$hi, jpn_first))
  }
  p <- p +
    ggplot2::geom_hline(yintercept = 0, colour = "grey60", linewidth = 0.4) +
    ggplot2::geom_ribbon(data = g, ggplot2::aes(x = t, ymin = ymin, ymax = ymax,
                                                 fill = cat, group = grp),
                         colour = "white", linewidth = style$lwd_outline) +
    ggplot2::geom_line(data = w, ggplot2::aes(x = year, y = gross_inflows_pct_world_gdp),
                       colour = style$col_total, linewidth = style$lwd_total) +
    ggplot2::geom_line(data = w, ggplot2::aes(x = year, y = reserves_pct_world_gdp),
                       colour = style$col_reserves, linewidth = style$lwd_reserves,
                       linetype = "22") +
    # Direct labels of the two lines, right of the last year
    ggplot2::annotate("text", x = max(w$year) + 0.6, y = end_total, hjust = 0,
                      size = style$base_size * 0.27, colour = style$col_total,
                      family = theme_lecture()$text$family, lineheight = 0.9,
                      label = "Total gross\ninflows") +
    ggplot2::annotate("text", x = max(w$year) + 0.6, y = end_res, hjust = 0,
                      size = style$base_size * 0.27, colour = style$col_reserves,
                      family = theme_lecture()$text$family, lineheight = 0.9,
                      label = "Reserve\naccumulation\n(asset side)") +
    # Peak and post-peak trough
    ggplot2::annotate("text", x = pk$year, y = pk$gross_inflows_pct_world_gdp + 1.2,
                      hjust = 0.5, vjust = 0, size = style$base_size * 0.27,
                      colour = style$col_total, family = theme_lecture()$text$family,
                      label = sprintf("%d: %.0f%% of world GDP", pk$year,
                                      pk$gross_inflows_pct_world_gdp)) +
    ggplot2::annotate("segment", x = tr$year + 1.4, xend = tr$year + 0.25,
                      y = y_top * 0.58,
                      yend = tr$gross_inflows_pct_world_gdp + 0.9,
                      colour = style$col_note, linewidth = 0.4) +
    ggplot2::annotate("text", x = tr$year + 1.5, y = y_top * 0.59,
                      hjust = 0, vjust = 0, size = style$base_size * 0.26,
                      colour = style$col_note, family = theme_lecture()$text$family,
                      lineheight = 0.95,
                      label = sprintf(paste0("%d: %.0f%% of world GDP\n",
                                             "Global financial crisis: bank lending\n",
                                             "(other investment) reverses"),
                                      tr$year, tr$gross_inflows_pct_world_gdp)) +
    ggplot2::scale_fill_manual(values = style$cols, breaks = stack5,
                               labels = labels[stack5], name = NULL,
                               guide = ggplot2::guide_legend(nrow = 2, byrow = TRUE)) +
    ggplot2::scale_x_continuous(breaks = x_breaks, expand = c(0, 0)) +
    ggplot2::scale_y_continuous(breaks = seq(-10, 30, 5),
                                labels = function(x) paste0(x, "%"),
                                expand = ggplot2::expansion(mult = c(0.04, 0.02))) +
    ggplot2::coord_cartesian(xlim = c(from_year - 0.5, max(w$year) + 0.3),
                             ylim = c(min(g$ymin, 0) - 0.5, y_top), clip = "off") +
    ggplot2::labs(x = NULL, y = "Percent of world GDP", caption = paste(
      strwrap(caption, width = style$wrap_width), collapse = "\n")) +
    theme_lecture(base_size = style$base_size) +
    ggplot2::theme(
      legend.position        = "top",
      legend.justification   = "left",
      legend.location        = "plot",
      legend.key.size        = grid::unit(0.5, "cm"),
      legend.key.spacing.x   = grid::unit(0.5, "cm"),
      legend.text            = ggplot2::element_text(size = ggplot2::rel(0.78)),
      legend.margin          = ggplot2::margin(0, 0, 2, 0),
      plot.margin            = ggplot2::margin(6, style$margin_r, 6, 8),
      axis.line.x            = ggplot2::element_blank(),
      axis.ticks.x           = ggplot2::element_line(colour = "grey60"))
  p
}


# ***********************************************************
# Part 3: Figures: main (1980-2025) and from 1996; PNG, PDF, SVG ----
# ***********************************************************
# What: lecture05_bop_inflows (with the partial-coverage band) and
#   lecture05_bop_inflows_from1996 (the years with >= 95% GDP coverage).
# How: save_lecture_fig() writes PNG (ragg, 300 dpi) and PDF; svglite adds
#   the editable SVG.
save_svg <- function(p, name, dir, width, height) {
  f_svg <- file.path(dir, paste0(name, ".svg"))
  svglite::svglite(f_svg, width = width, height = height, bg = "white")
  print(p)
  grDevices::dev.off()
  cat("Saved:", f_svg, "\n")
  invisible(f_svg)
}
fig_main <- build_bop_fig(world, from_year = first_year, show_band = TRUE,
                          style = bop_style, labels = component_labels,
                          caption = caption_text,
                          x_breaks = seq(1980, last_year, 5))
save_lecture_fig(fig_main, "lecture05_bop_inflows", o_out_l5,
                 width = bop_style$width, height = bop_style$height)
save_svg(fig_main, "lecture05_bop_inflows", o_out_l5,
         width = bop_style$width, height = bop_style$height)

fig_1996 <- build_bop_fig(world, from_year = 1996L, show_band = FALSE,
                          style = bop_style, labels = component_labels,
                          caption = make_caption(1996L),
                          x_breaks = c(1996, seq(2000, last_year, 5)))
save_lecture_fig(fig_1996, "lecture05_bop_inflows_from1996", o_out_l5,
                 width = bop_style$width, height = bop_style$height)
save_svg(fig_1996, "lecture05_bop_inflows_from1996", o_out_l5,
         width = bop_style$width, height = bop_style$height)


# ***********************************************************
# Part 4: PowerPoint slide ----
# ***********************************************************
# What: lecture05_bop_inflows.pptx with three slides: the main figure as an
#   editable vector graphic (rvg), the same as PNG (for a quick copy into
#   the lecture deck), and the 1996 variant as vector graphic. Speaker
#   notes hold the source line.
# How: the course template if it exists (layout "Title Only"), otherwise
#   officer's default 16:9 template.
slide_title <- sprintf(paste0("Global cross-border financial inflows by type, ",
                              "%d-%d (%% of world GDP)"), first_year, last_year)
if (file.exists(f_pptx_template)) {
  deck <- officer::read_pptx(f_pptx_template)
  cat("Slide template: course template", basename(f_pptx_template), "\n")
} else {
  deck <- officer::read_pptx()
  cat("Slide template: officer default (course template not found at ",
      f_pptx_template, ")\n")
}
# Drop any slides the template ships with (keep layouts and master only)
while (length(deck) > 0) deck <- officer::remove_slide(deck, 1)
ss <- officer::slide_size(deck)
fig_loc <- officer::ph_location(left = 0.45, top = 1.3, width = ss$width - 0.9,
                                height = ss$height - 1.3 - 0.45)
# A picture keeps the figure's aspect ratio: ph_with() sizes a picture by
# the location, not by external_img(width, height), so the PNG slide gets a
# location of the same width and the figure's own height.
img_loc <- officer::ph_location(left = 0.45, top = 1.3, width = ss$width - 0.9,
                                height = (ss$width - 0.9) * bop_style$height /
                                  bop_style$width)
add_fig_slide <- function(deck, value, title, notes, loc = fig_loc) {
  deck <- officer::add_slide(deck, layout = "Title Only",
                             master = officer::layout_summary(deck)$master[1])
  deck <- officer::ph_with(deck, value = title,
                           location = officer::ph_location_type("title"))
  deck <- officer::ph_with(deck, value = value, location = loc)
  deck <- officer::set_notes(deck, value = notes,
                             location = officer::notes_location_type("body"))
  deck
}
notes_text <- paste(caption_text, "Built by code/lecture05_bop_figures.R",
                    "(Teaching_PEIB, master Part 14).")
deck <- add_fig_slide(deck, rvg::dml(ggobj = fig_main, fonts = list(sans = "Segoe UI")),
                      slide_title, notes_text)
deck <- add_fig_slide(deck, officer::external_img(
  file.path(o_out_l5, "lecture05_bop_inflows.png"),
  width = img_loc$width, height = img_loc$height),
  paste(slide_title, "- PNG"), notes_text, loc = img_loc)
deck <- add_fig_slide(deck, rvg::dml(ggobj = fig_1996, fonts = list(sans = "Segoe UI")),
                      sub(sprintf("%d-", first_year), "1996-", slide_title),
                      notes_text)
f_pptx <- file.path(o_out_l5, "lecture05_bop_inflows.pptx")
print(deck, target = f_pptx)
cat("Saved:", f_pptx, "(", length(deck), "slides )\n")


# ***********************************************************
# Part 5: Figure csv and headline numbers ----
# ***********************************************************
# What: lecture05_bop_inflows_data.csv, the numbers behind the figure in
#   USD billion and % of world GDP (plus the alternative denominator and
#   the coverage columns); lecture05_bop_headline_numbers.csv for the slide
#   text.
usd_cols <- c("fdi", "portfolio_equity", "portfolio_debt", "other", "derivatives",
              "gross_inflows", "portfolio_unsplit", "reserves")
fig_data <- world[, c("year", paste0(usd_cols, "_usd"),
                      paste0(usd_cols, "_pct_world_gdp"),
                      paste0(usd_cols, "_pct_reporter_gdp"),
                      "world_gdp_usd", "reporter_gdp_usd",
                      paste0("n_", c("fdi", "portfolio_equity", "portfolio_debt",
                                     "other", "derivatives", "reserves"))),
                  with = FALSE]
for (v in c(paste0(usd_cols, "_usd"), "world_gdp_usd", "reporter_gdp_usd")) {
  fig_data[, (v) := get(v) / 1e9]
}
setnames(fig_data, c(paste0(usd_cols, "_usd"), "world_gdp_usd", "reporter_gdp_usd"),
         c(paste0(usd_cols, "_usd_bn"), "world_gdp_usd_bn", "reporter_gdp_usd_bn"))
fig_data <- merge(fig_data, coverage[, .(year, gdp_coverage_pct,
                                         inflow_weight_coverage_pct,
                                         largest_non_reporters)], by = "year")
fig_data[, preliminary := year == last_year]
fwrite(fig_data, file.path(o_out_l5, "lecture05_bop_inflows_data.csv"))

share <- function(y, v) world[year == y, 100 * get(paste0(v, "_usd")) / gross_inflows_usd]
headline <- data.table(
  item = c("peak_year", "peak_total_pct_world_gdp", "peak_total_usd_bn",
           "trough_year", "trough_total_pct_world_gdp",
           sprintf("total_%d_pct_world_gdp", first_year),
           "total_2000_pct_world_gdp",
           sprintf("total_%d_pct_world_gdp", last_year - 1),
           sprintf("total_%d_pct_world_gdp_preliminary", last_year),
           sprintf("fdi_share_of_gross_inflows_%d_pct", peak$year),
           sprintf("other_share_of_gross_inflows_%d_pct", peak$year),
           sprintf("fdi_share_of_gross_inflows_%d_pct", last_year - 1),
           "reserves_peak_year", "reserves_peak_pct_world_gdp",
           sprintf("reporters_%d", first_year), sprintf("reporters_%d", last_year),
           sprintf("gdp_coverage_%d_pct", first_year),
           sprintf("gdp_coverage_%d_pct", last_year),
           "unsplit_portfolio_share_of_gross_flows_pct",
           "fdi_country_sum_vs_imf_aggregate_median_ratio",
           "portfolio_country_sum_vs_imf_aggregate_median_ratio"),
  value = c(peak$year, peak$v, world[year == peak$year, gross_inflows_usd / 1e9],
            trough$year, trough$v,
            world[year == first_year, gross_inflows_pct_world_gdp],
            world[year == 2000, gross_inflows_pct_world_gdp],
            world[year == last_year - 1, gross_inflows_pct_world_gdp],
            world[year == last_year, gross_inflows_pct_world_gdp],
            share(peak$year, "fdi"), share(peak$year, "other"),
            share(last_year - 1, "fdi"),
            world[which.max(reserves_pct_world_gdp), year],
            world[, max(reserves_pct_world_gdp)],
            n_rep[[1]], n_rep[[3]],
            coverage[year == first_year, gdp_coverage_pct],
            coverage[year == last_year, gdp_coverage_pct],
            unsplit_share,
            aggcheck[component == "fdi", median(ratio)],
            aggcheck[component == "portfolio_total", median(ratio)]))
headline[, value := round(value, 2)]
fwrite(headline, file.path(o_out_l5, "lecture05_bop_headline_numbers.csv"))
cat("\nHeadline numbers:\n"); print(headline)


# ***********************************************************
# Part 6: Methodology notes ----
# ***********************************************************
# What: lecture05_bop_methodology.md: sources, codes, definitions,
#   construction, coverage, validation, known limitations, files. All
#   numbers are pasted from the data objects above.
cov_tab <- coverage[year %in% c(1980, 1985, 1990, 1995, 1996, 2000, 2005, 2010,
                                2015, 2020, last_year - 1, last_year)]
agg_tab <- aggcheck[, .(median_ratio = median(ratio), min_ratio = min(ratio),
                        max_ratio = max(ratio),
                        median_abs_diff_bn = median(abs(diff_usd_bn))), by = component]
bop_series <- rbindlist(meta$bop_series)
md <- c(
  "# Global cross-border financial inflows by investment type, 1980-2025: methodology notes",
  "",
  sprintf("Built on %s by `code/lecture05_bop_figures.R` (Teaching_PEIB, master Part 14) from IMF data downloaded on %s.",
          format(Sys.Date(), "%d %B %Y"), meta$downloaded),
  "",
  "## 1. What the figure shows",
  "",
  paste0("Annual gross cross-border financial inflows into all reporting economies, measured as the ",
         "net incurrence of liabilities to non-residents (BPM6 financial account), summed over ",
         "economies and expressed as a percentage of world GDP in current US dollars. The stack ",
         "distinguishes foreign direct investment, portfolio equity, portfolio debt, other investment ",
         "(mainly bank loans, deposits and trade credit) and financial derivatives. Reserve-asset ",
         "accumulation (net acquisition of reserve assets by central banks) belongs to the asset ",
         "side of the financial account and is drawn as a separate dashed line, not stacked. ",
         "The thin black line is the total of the five stacked components."),
  "",
  sprintf(paste0("Headline numbers: gross inflows rose from %.1f%% of world GDP in %d to a peak of %.1f%% ",
                 "in %d (USD %s billion), collapsed to %.1f%% in %d, and stood at %.1f%% in %d ",
                 "(%d preliminary: %.1f%%). Reserve accumulation peaked at %.1f%% of world GDP in %d."),
          world[year == first_year, gross_inflows_pct_world_gdp], first_year, peak$v, peak$year,
          format(round(world[year == peak$year, gross_inflows_usd / 1e9]), big.mark = ","),
          trough$v, trough$year, world[year == last_year - 1, gross_inflows_pct_world_gdp],
          last_year - 1, last_year, world[year == last_year, gross_inflows_pct_world_gdp],
          world[, max(reserves_pct_world_gdp)], world[which.max(reserves_pct_world_gdp), year]),
  "",
  "## 2. Data sources (all IMF, SDMX 3.0 API, R package imf.data)",
  "",
  sprintf("- API base URL: %s; R package: %s.", meta$api_base_url, meta$r_package),
  sprintf("- `IMF.STA/BOP` version %s, Balance of Payments (country data, BPM6 presentation): the series behind the figure.",
          bop_versions[id == "BOP", version]),
  sprintf("- `IMF.STA/BOP_AGG` version %s, BOP/IIP World and Country Group Aggregates: used only to validate the country sums (world total GX010 \"All Countries and International Organizations\", available 2005-%d).",
          bop_versions[id == "BOP_AGG", version], max(aggcheck$year)),
  sprintf("- `IMF.RES/WEO` version %s, World Economic Outlook: nominal GDP in US dollars (indicator NGDPD) for the world (G001) and every economy, 1980 onwards.",
          bop_versions[id == "WEO", version]),
  "",
  "All codes were discovered from the IMF code lists (dimension values of each dataflow) and are re-verified by name on every run of `code/bop_import.R`; a mismatch stops the pipeline.",
  "",
  "| Component | BOP indicator | Indicator name in the IMF code list | Accounting entry |",
  "|---|---|---|---|",
  sprintf("| %s | `%s` | %s | `%s` (%s) |", bop_series$component, bop_series$indicator,
          bop_series$indicator_name, bop_series$entry, bop_series$entry_name),
  "",
  "Unit: US dollars, annual. The API's SCALE attribute reads 6 (millions) but the returned values are plain dollars; this was anchored on China's 2007 reserve accumulation (460.7 billion USD) and world GDP 2024 (111.9 trillion USD), and the anchor is one of the checks in `code/bop_clean.R`.",
  "",
  "## 3. Construction",
  "",
  "- Economies only: the BOP country dimension also contains the euro area (G163) and the Eastern Caribbean Currency Union (G309); both are dropped because they would double count their members.",
  "- Curaçao and Sint Maarten: the IMF list carries the combined code CWX next to CUW and SXM, all reporting 2011-2023. The combined code is dropped in every year where a constituent reports and kept where it is the only reporter (2024-2025), so the territory is counted once. A general predecessor/successor check (Czechoslovakia, Yugoslavia, Netherlands Antilles, the two Yemens, the USSR, the GDR, Serbia and Montenegro) finds no other overlap; see `data/imf_bop/clean/bop_overlap_check.csv`.",
  "- Missing values: the API returns a row only where an observation exists. A missing economy-year stays NA in the panel and is simply absent from the world sum (the number of reporters per component and year is written next to every sum). No NA is replaced by zero; negative observations are kept (they are net repayments or withdrawals).",
  sprintf("- Portfolio split: equity (P_F5) and debt (P_F3) are stacked. Where an economy reports only the portfolio total (P_F) or one component, the unexplained remainder is kept in `portfolio_unsplit` and is not stacked (%.1f%% of the absolute gross flows over %d-%d; at most %.2f%% of world GDP in any year). Where total, equity and debt are all reported, total minus the components is a reporting discrepancy kept for information (`portfolio_split_gap`); the only material case is Bahrain 2024, where the IMF file repeats the total as both equity and debt (USD 3.4 billion, 0.003%% of world GDP), left as reported.",
          unsplit_share, first_year, last_year, unsplit_max),
  "- No double counting: the stack uses the five mutually exclusive components; the portfolio total, the unsplit remainder and the IMF aggregates are carried in the csv for reference only.",
  "- Denominators: world GDP is the WEO \"World\" series. The csv also gives every series in percent of the GDP of the economies reporting FDI inflows that year (`*_pct_reporter_gdp`), which corrects for the growing sample if non-reporters are assumed to resemble reporters. The figure uses world GDP as requested.",
  "",
  "## 4. Coverage, and whether 1980-2025 is feasible",
  "",
  sprintf(paste0("The IMF's own world aggregates (BOP_AGG) start in %d and do not split portfolio investment, ",
                 "so the long series has to be built from country data. Country data in the BPM6 presentation ",
                 "reach back to %d for a few economies and cover %d reporters in %d. The binding constraint ",
                 "is Japan, whose BPM6 series start in %d (no earlier data in any presentation on the API); ",
                 "Belgium and Luxembourg report from %d and %d, Austria and Ireland from %d and %d, Switzerland from %d, ",
                 "Australia from %d, Hong Kong SAR from %d, Taiwan Province of China never (not an IMF member) ",
                 "and Iran last in %d. Reporting economies therefore cover %.0f-%.0f%% of world GDP in ",
                 "%d-%d and %.0f-%.0f%% from %d. Because financial centres have small GDP but large ",
                 "flows, the csv also reports an inflow-weighted coverage (share of 2005-2015 average absolute ",
                 "gross inflows accounted for by the economies reporting in a given year; base years = ",
                 "BOP_BASE_YEARS in code/bop_clean.R): %.0f%% in %d, %.0f%% in %d, %.0f%% in %d."),
          min(aggcheck$year), panel[, min(year)], n_rep[[1]], first_year, jpn_first,
          fy("BEL"), fy("LUX"), fy("AUT"), fy("IRL"), fy("CHE"), fy("AUS"), fy("HKG"), ly("IRN"),
          cov_pre$lo, cov_pre$hi, first_year, jpn_first - 1, cov_post$lo, cov_post$hi, jpn_first,
          coverage[year == first_year, inflow_weight_coverage_pct], first_year,
          coverage[year == jpn_first, inflow_weight_coverage_pct], jpn_first,
          coverage[year == min(aggcheck$year), inflow_weight_coverage_pct], min(aggcheck$year)),
  "",
  sprintf(paste0("Verdict: %d-%d is feasible as a reporter sum, and the figure shows it, but %d-%d is a ",
                 "partial-coverage segment (shaded in the figure) and %d-%d still lacks Belgium, Luxembourg, ",
                 "Austria and Ireland, all large portfolio and FDI conduits. The series with defensible world ",
                 "coverage is %d-%d (variant `lecture05_bop_inflows_from1996`), and the IMF-consistent segment ",
                 "is %d onwards. The level in the early years is a lower bound for the world; the ratio to ",
                 "reporters' GDP (in the csv) is the better like-for-like comparison across the %d/%d break."),
          first_year, last_year, first_year, jpn_first - 1, jpn_first, max(fy("AUT"), fy("IRL")) - 1,
          jpn_first, last_year, min(aggcheck$year), jpn_first - 1, jpn_first),
  "",
  sprintf("%d is preliminary: %d economies had reported annual data at download, and the economies that reported in %d but not yet in %d accounted for %.1f%% of %d's absolute gross inflows.",
          last_year, n_rep[[3]], last_year - 1, last_year,
          coverage[year == last_year, dropped_prev_year_inflow_share_pct], last_year - 1),
  "",
  "| Year | Reporters | GDP coverage (% of world GDP) | Inflow-weighted coverage (%) | Largest non-reporters (by GDP) |",
  "|---|---|---|---|---|",
  sprintf("| %d | %d | %.1f | %.1f | %s |", cov_tab$year, cov_tab$n_reporters,
          cov_tab$gdp_coverage_pct, cov_tab$inflow_weight_coverage_pct,
          cov_tab$largest_non_reporters),
  "",
  sprintf("## 5. Validation against the IMF world aggregates (2005-%d)", max(aggcheck$year)),
  "",
  "Ratio of the country sums to the IMF's world aggregate (GX010), per component and year (`data/imf_bop/clean/bop_agg_check.csv`). The IMF aggregate includes IMF estimates for late reporters and uses series \"adjusted using IMF accounting records\" for other investment and reserves, so ratios near but not exactly 1 are expected; ratios far from 1 for derivatives and other investment occur in years when the world total is close to zero and the ratio is not informative (the median absolute difference in USD billion is the better gauge).",
  "",
  "| Component | Median ratio | Min | Max | Median abs. difference (USD bn) |",
  "|---|---|---|---|---|",
  sprintf("| %s | %.3f | %.3f | %.3f | %.1f |", agg_tab$component, agg_tab$median_ratio,
          agg_tab$min_ratio, agg_tab$max_ratio, agg_tab$median_abs_diff_bn),
  "",
  "## 6. Checks run by the pipeline (each stops the build when it fails)",
  "",
  "1. Every IMF code used matches its name in the current IMF code list.",
  "2. Nothing lost, nothing filled: the number of non-missing cells per component equals the number of rows the API returned (after the CWX correction).",
  "3. Negative observations preserved: the count of negative cells equals the raw count.",
  "4. Stack identity: the total equals the sum of the five components in every year.",
  "5. Portfolio identity: total = equity + debt + unsplit remainder + split discrepancy in every year.",
  "6. All years present once; no economy counted twice in a year; no predecessor/successor overlap.",
  "7. Units anchor (China 2007 reserves between 455 and 466 billion USD).",
  "8. FDI and portfolio country sums within 15% of the IMF world aggregate in every year 2005 onwards.",
  "",
  "## 7. Known limitations and unresolved coverage issues",
  "",
  sprintf("- Japan before %d, Belgium and Luxembourg before %d, Austria and Ireland before %d: the largest gaps; no IMF source on the SDMX 3.0 API fills them (the BPM5-era IFS presentation is not available there).",
          jpn_first, max(fy("BEL"), fy("LUX")), max(fy("AUT"), fy("IRL"))),
  sprintf("- Taiwan Province of China is never included (not an IMF member); Iran's last reported year is %d.", ly("IRN")),
  "- Reporter counts in the figure caption and the csv refer to economies reporting FDI inflows; fewer economies report financial derivatives (see the `n_*` columns in the csv), so the derivatives layer covers a smaller sample.",
  "- Financial-centre flows (Luxembourg, Ireland, Netherlands, Cayman Islands, Hong Kong SAR, Singapore) are gross cross-border positions of pass-through entities and inflate world totals relative to \"real\" financing; the figure does not net them out.",
  "- The IMF revises BOP data monthly; a fresh download (set `BOP_FORCE_DOWNLOAD <- TRUE` in the master) changes the numbers. The download date and dataflow versions are in `data/imf_bop/raw/bop_metadata.json`.",
  sprintf("- %d is preliminary (see section 4). World GDP for %d is the WEO estimate of the vintage downloaded.", last_year, last_year),
  "- The Bahrain 2024 portfolio duplicate (section 3) is left as reported.",
  "",
  "## 8. Files",
  "",
  "- `outputs/lecture5_capital_inflows/lecture05_bop_inflows.png` (300 dpi), `.pdf`, `.svg`: the main figure, 1980-2025, 11 x 5.8 in, white background, Segoe UI.",
  "- `outputs/lecture5_capital_inflows/lecture05_bop_inflows_from1996.png/.pdf/.svg`: the variant starting in 1996.",
  "- `outputs/lecture5_capital_inflows/lecture05_bop_inflows.pptx`: three slides (editable vector graphic, PNG, 1996 variant), built on the course template.",
  "- `outputs/lecture5_capital_inflows/lecture05_bop_inflows_data.csv`: the figure data by year (USD billion, % of world GDP, % of reporters' GDP, reporter counts, coverage).",
  "- `outputs/lecture5_capital_inflows/lecture05_bop_headline_numbers.csv`: numbers for the slide text.",
  "- `data/imf_bop/clean/bop_country_year.csv`: the economy-year panel (USD) behind the sums; `bop_world_year.csv`, `bop_coverage_year.csv`, `bop_agg_check.csv`, `bop_overlap_check.csv`.",
  "- Code: `code/bop_import.R`, `code/bop_clean.R`, `code/lecture05_bop_figures.R`, run from `code/master.R` Part 14.",
  ""
)
# Binary connection: LF line endings on every platform (text mode on
# Windows would write CRLF)
con_md <- file(file.path(o_out_l5, "lecture05_bop_methodology.md"), open = "wb",
               encoding = "UTF-8")
writeLines(enc2utf8(md), con_md, sep = "\n", useBytes = TRUE)
close(con_md)
cat("Saved:", file.path(o_out_l5, "lecture05_bop_methodology.md"), "\n")
rm(f, v, md, con_md, cov_tab, agg_tab, usd_cols, share, notes_text, deck, ss,
   fig_loc, img_loc, add_fig_slide, f_pptx, slide_title, save_svg, panel,
   rep_years, fy, ly)
