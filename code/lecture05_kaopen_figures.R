# ***********************************************************
# Title: SEES0082 Political Economy of International Business, UCL SSEES:
#        course website with interactive diagrams (Teaching_PEIB)
#
# Purpose: Lecture 5 data figures: financial openness (Chinn-Ito index) by
#          World Bank region, 1970-2023
#       Part 1: Style list, display labels and caption text
#       Part 2: Figure F1, seven regions, all countries
#       Part 3: Figure F1b, seven regions, balanced panel
#       Part 4: Figure F2, small multiples with interquartile bands
#       Part 5: Headline numbers (csv for the slides)
#
# Authors: Florian Münch
# Requires: data/kaopen/clean/kaopen_regions.csv (code/kaopen_clean.R);
#     Parts 1 and 2 of code/master.R (paths d_kaopen_clean, o_fig_l5;
#     packages data.table, ggplot2, ggrepel, scales, ragg, systemfonts;
#     theme_lecture() and save_lecture_fig() from code/functions_lecture.R)
#         ID variables: sample-region-year
# Creates: in figures/lecture5/ (committed), PNG (300 dpi) and PDF each:
#     lecture05_kaopen_regions           (Part 2)
#     lecture05_kaopen_regions_balanced  (Part 3)
#     lecture05_kaopen_regions_facets    (Part 4)
#     lecture05_kaopen_headline_numbers.csv (Part 5)
#         ID variables: sample-region
# ***********************************************************

# Explanatory notes:
  # No titles in the figures: the title goes on the slide. Every number in
  # a caption is pasted from the data with sprintf(), never typed, so the
  # captions stay right when the data are updated.
  # The figures are 10 x 5.6 inches (16:9 slide body); insert the PNG in
  # PowerPoint at full slide width, or the PDF in LaTeX.
  # End labels: ggrepel places the region names to the right of 2023; the
  # fixed seed and max.time = Inf make the placement the same on every run.
  # Regions: the seven World Bank regions (code/kaopen_clean.R, Part 2).

# Safety check: stop with a clear message if master.R Parts 1-2 have not run
if (!exists("o_fig_l5") || !exists("save_lecture_fig")) {
  stop("o_fig_l5 or save_lecture_fig() is missing. Run code/master.R (at ",
       "least Parts 1 and 2) instead of this script on its own.",
       call. = FALSE)
}
f_regions <- file.path(d_kaopen_clean, "kaopen_regions.csv")
if (!file.exists(f_regions)) {
  stop("Missing ", f_regions, ". Run code/kaopen_clean.R (master Part 13) ",
       "first.", call. = FALSE)
}


# ***********************************************************
# Part 1: Style list, display labels and caption text ----
# ***********************************************************
# What: one list with the look of the figure family; display labels for
#   the snake_case regions; caption sentences shared by all figures.
# How: change colours, widths or the label seed here, not in the Parts.
kaopen_style <- list(
  # Seven regions, colours from the repo palette peib_cols
  cols = c(east_asia_pacific   = "#B279A2",   # purple
           europe_central_asia = "#4C78A8",   # blue
           lac                 = "#54A24B",   # green
           mena                = "#E45756",   # red
           north_america       = "#1F3B5C",   # dark blue
           south_asia          = "#F58518",   # orange
           ssa                 = "#72B7B2"),  # teal
  grey        = "#9A9A9A",   # world mean
  lwd_region  = 1.1,         # line width of a region mean
  lwd_world   = 0.7,         # line width of the world mean (dashed)
  label_size  = 4.6,         # end labels (mm, ggplot units)
  label_seed  = 20261105,    # ggrepel seed (date of Lecture 5)
  # End labels all start at the same x, right of the last year, so a leader
  # line ends at its own label and never runs through another one
  label_nudge = 4,           # years between the last data point and labels
  label_xlim  = c(2027, 2045),  # where end labels may go (data units)
  margin_r    = 165,         # right plot margin (pt) that holds the labels
  base_size   = 16,          # theme_lecture() base size
  wrap_width  = 158          # caption characters per line
)

region_labels <- c(
  east_asia_pacific   = "East Asia\n& Pacific",
  europe_central_asia = "Europe &\nCentral Asia",
  lac                 = "Latin America\n& Caribbean",
  mena                = "Middle East\n& North Africa",
  north_america       = "North America",
  south_asia          = "South Asia",
  ssa                 = "Sub-Saharan\nAfrica",
  world               = "World"
)
# One-line versions for captions and facet strips
region_labels_1line <- gsub("\n", " ", region_labels)
regions_seven <- names(kaopen_style$cols)

kaopen_regions <- fread(f_regions)
yr_min <- min(kaopen_regions$year)
yr_max <- max(kaopen_regions$year)
# Every 10 years plus the last year; a decade tick closer than 5 years to
# the last year is dropped (2020 and 2023 overlap at slide size)
x_breaks <- c(seq(yr_min, yr_max - 5, by = 10), yr_max)

# Caption pieces (numbers from the data)
cap_source <- paste0(
  "Source: Chinn-Ito index of financial openness, 2023 update (January ",
  "2026), web.pdx.edu/~ito/Chinn-Ito_website.htm; Chinn, M. D. & Ito, H. ",
  "(2006), Journal of Development Economics 81(1), 163-192.")
cap_def <- paste0(
  "Index: de jure openness (legal restrictions, not actual capital ",
  "flows), first principal component of four IMF AREAER indicators ",
  "(restrictions on capital and current account transactions, multiple ",
  "exchange rates, surrender of export proceeds), normalised from 0 (most ",
  "closed) to 1 (most open).")
cap_mean <- "Lines: unweighted country means (one country, one vote)."
cap_regions <- paste0(
  "Regions: World Bank classification; East Asia & Pacific pools East and ",
  "South East Asia with the Pacific islands.")

# n countries with data in a given year, per region, as "East Asia & Pacific 24, ..."
n_text <- function(dt, smp, regs, yr) {
  n <- dt[sample == smp & year == yr & region %in% regs,
          .(region, n_countries)]
  n <- n[match(regs, region)]
  n[, region := regs]
  n[is.na(n_countries), n_countries := 0L]
  paste(sprintf("%s %d", region_labels_1line[n$region], n$n_countries),
        collapse = ", ")
}
wrap_caption <- function(parts, width) {
  paste(strwrap(paste(parts, collapse = " "), width = width),
        collapse = "\n")
}

# Builder for the line figures F1 and F1b: region means over time in their
# colours, world mean dashed grey, end labels right of the last year.
build_fig_regions <- function(dt, smp, regions_show, caption, style) {
  d <- dt[sample == smp & region %in% c(regions_show, "world")]
  d[, col := fifelse(region == "world", style$grey, style$cols[region])]
  d[, label := region_labels[region]]
  # North America (always at 1) is drawn first, so it hides no region that
  # reaches 1; the others follow in the order of the style list.
  d[, draw_group := factor(region, levels = unique(c("north_america",
                                                     regions_show)))]
  ends <- d[, .SD[year == max(year)], by = region]
  ggplot2::ggplot() +
    ggplot2::geom_line(
      data = d[region == "world"],
      ggplot2::aes(year, mean_ka_open),
      colour = style$grey, linewidth = style$lwd_world,
      linetype = "dashed") +
    ggplot2::geom_line(
      data = d[region != "world"],
      ggplot2::aes(year, mean_ka_open, group = draw_group, colour = col),
      linewidth = style$lwd_region) +
    ggrepel::geom_text_repel(
      data = ends,
      ggplot2::aes(year, mean_ka_open, label = label, colour = col),
      size = style$label_size, hjust = 0, direction = "y",
      xlim = style$label_xlim, nudge_x = style$label_nudge,
      segment.size = 0.3,
      segment.colour = "grey70", min.segment.length = 0,
      box.padding = 0.25, lineheight = 0.85,
      family = theme_lecture()$text$family,
      seed = style$label_seed, max.time = Inf, max.iter = 1e5) +
    ggplot2::scale_colour_identity() +
    ggplot2::scale_x_continuous(breaks = x_breaks,
                                expand = ggplot2::expansion(add = c(1, 0))) +
    ggplot2::scale_y_continuous(limits = c(0, 1),
                                breaks = seq(0, 1, by = 0.2),
                                expand = ggplot2::expansion(add = 0.02)) +
    ggplot2::coord_cartesian(xlim = c(yr_min, yr_max), clip = "off") +
    ggplot2::labs(
      x = NULL,
      y = "Chinn-Ito index, normalised\n(0 = most closed, 1 = most open)",
      caption = caption) +
    theme_lecture(base_size = style$base_size) +
    ggplot2::theme(plot.margin = ggplot2::margin(10, style$margin_r, 8, 8))
}


# ***********************************************************
# Part 2: Figure F1, seven regions, all countries ----
# ***********************************************************
# What: lecture05_kaopen_regions.png/.pdf.
# How: sample "all": every country with data in each year.
reg_all <- fread(f_regions)
cap_f1 <- wrap_caption(c(
  cap_source, cap_def, cap_mean, cap_regions,
  sprintf(paste0("Sample: all countries with data in each year ",
                 "(composition changes, e.g. post-Soviet states enter in ",
                 "the early 1990s); world: %d countries in %d."),
          reg_all[sample == "all" & region == "world" & year == yr_max,
                  n_countries], yr_max),
  sprintf("Countries with data in %d: %s.", yr_max,
          n_text(reg_all, "all", regions_seven, yr_max))),
  kaopen_style$wrap_width)
fig_f1 <- build_fig_regions(reg_all, "all", regions_seven, cap_f1,
                            kaopen_style)
save_lecture_fig(fig_f1, "lecture05_kaopen_regions", o_fig_l5)


# ***********************************************************
# Part 3: Figure F1b, seven regions, balanced panel ----
# ***********************************************************
# What: lecture05_kaopen_regions_balanced.png/.pdf.
# How: sample "balanced": only countries with data in every year, so the
#   lines move only because policies change, not because countries enter.
reg_bal <- fread(f_regions)
cap_f1b <- wrap_caption(c(
  cap_source, cap_def, cap_mean, cap_regions,
  sprintf(paste0("Sample: balanced panel, the %d countries with data in ",
                 "every year %d-%d."),
          reg_bal[sample == "balanced" & region == "world" & year == yr_max,
                  n_countries], yr_min, yr_max),
  sprintf("Countries per region: %s.",
          n_text(reg_bal, "balanced", regions_seven, yr_max))),
  kaopen_style$wrap_width)
fig_f1b <- build_fig_regions(reg_bal, "balanced", regions_seven, cap_f1b,
                             kaopen_style)
save_lecture_fig(fig_f1b, "lecture05_kaopen_regions_balanced", o_fig_l5)


# ***********************************************************
# Part 4: Figure F2, small multiples with interquartile bands ----
# ***********************************************************
# What: lecture05_kaopen_regions_facets.png/.pdf: one panel per region
#   (seven regions) plus a "World" panel, 2 x 4.
# How: mean line in the region colour, light ribbon from the 25th to the
#   75th percentile; world mean as a dashed grey reference in the seven
#   region panels; the World panel shows the world mean (grey) with its
#   own interquartile band across all countries. Sample "all".
reg_fac <- fread(f_regions)
panels_eight <- c(regions_seven, "world")
d_fac <- reg_fac[sample == "all" & region %in% panels_eight]
d_fac[, col := fifelse(region == "world", kaopen_style$grey,
                       kaopen_style$cols[region])]
d_fac[, panel := factor(region, levels = panels_eight,
                        labels = region_labels_1line[panels_eight])]
# The dashed world reference, repeated in each of the seven region panels
# only (a facet_wrap layer without the panel column would also draw it in
# the World panel)
d_world_ref <- reg_fac[sample == "all" & region == "world",
                       .(year, mean_ka_open)]
d_world_ref <- d_world_ref[rep(seq_len(.N), times = length(regions_seven))]
d_world_ref[, panel := factor(rep(region_labels_1line[regions_seven],
                                  each = .N / length(regions_seven)),
                              levels = levels(d_fac$panel))]
cap_f2 <- wrap_caption(c(
  cap_source, cap_def,
  paste0("Solid line: unweighted country mean; band: 25th to 75th ",
         "percentile across countries; dashed grey line: world mean."),
  cap_regions,
  "Sample: all countries with data in each year.",
  sprintf("Countries with data in %d: %s.", yr_max,
          n_text(reg_fac, "all", panels_eight, yr_max))),
  kaopen_style$wrap_width)
# x ticks every 20 years plus the last year, not every 10 as in the other
# figures: a panel is about a quarter of the figure width, and seven year
# labels would collide there. A 20-year tick closer than 13 years to the
# last year is dropped (here: 1970, 1990, 2010, 2023).
fac_breaks <- c(seq(yr_min, yr_max - 13, by = 20), yr_max)
fig_f2 <- ggplot2::ggplot(d_fac, ggplot2::aes(year)) +
  ggplot2::geom_ribbon(ggplot2::aes(ymin = p25_ka_open, ymax = p75_ka_open,
                                    fill = col), alpha = 0.22) +
  ggplot2::geom_line(data = d_world_ref, ggplot2::aes(year, mean_ka_open),
                     colour = kaopen_style$grey,
                     linewidth = kaopen_style$lwd_world,
                     linetype = "dashed") +
  ggplot2::geom_line(ggplot2::aes(y = mean_ka_open, colour = col),
                     linewidth = kaopen_style$lwd_region) +
  ggplot2::facet_wrap(~ panel, nrow = 2) +
  ggplot2::scale_colour_identity() +
  ggplot2::scale_fill_identity() +
  ggplot2::scale_x_continuous(breaks = fac_breaks) +
  ggplot2::scale_y_continuous(limits = c(0, 1),
                              breaks = seq(0, 1, by = 0.2)) +
  ggplot2::labs(
    x = NULL,
    y = "Chinn-Ito index, normalised\n(0 = most closed, 1 = most open)",
    caption = cap_f2) +
  theme_lecture(base_size = 13) +
  ggplot2::theme(panel.spacing.x = ggplot2::unit(1.2, "lines"),
                 plot.margin = ggplot2::margin(8, 14, 8, 8))
save_lecture_fig(fig_f2, "lecture05_kaopen_regions_facets", o_fig_l5)


# ***********************************************************
# Part 5: Headline numbers (csv for the slides) ----
# ***********************************************************
# What: lecture05_kaopen_headline_numbers.csv: per sample and region (plus
#   world) the mean ka_open and the number of countries in 1970, 1990,
#   2008 and 2023, one row per sample-region.
reg_head <- fread(f_regions)
head_years <- c(1970, 1990, 2008, 2023)
headline <- data.table::dcast(
  reg_head[year %in% head_years],
  sample + region ~ year,
  value.var = c("mean_ka_open", "n_countries"))
num_cols <- grep("^mean_ka_open", names(headline), value = TRUE)
headline[, (num_cols) := lapply(.SD, round, 4), .SDcols = num_cols]
headline[, region := factor(region, levels = names(region_labels))]
setorder(headline, sample, region)
headline[, region := as.character(region)]
fwrite(headline, file.path(o_fig_l5, "lecture05_kaopen_headline_numbers.csv"),
       eol = "\n")   # LF line endings on every OS
cat("Written:", file.path(o_fig_l5, "lecture05_kaopen_headline_numbers.csv"),
    "\n")
print(headline[sample == "all"])
