# ***********************************************************
# Title: SEES0082 Political Economy of International Business, UCL SSEES:
#        course website with interactive diagrams (Teaching_PEIB)
#
# Purpose: shared ggplot2 theme and save helper for the lecture data
#          figures (never bundled into the browser apps)
#       Part 1: theme_lecture(): the look of every lecture data figure
#       Part 2: save_lecture_fig(): writes one figure as PNG and PDF
#
# Authors: Florian Münch
# Requires: the R packages ggplot2, ragg and systemfonts (loaded in Part 1
#     of code/master.R)
# Creates: nothing when sourced: it only defines two functions
# ***********************************************************

# Explanatory notes:
  # code/functions_models.R (base R only) draws the tutorial diagrams and is
  # bundled into the website apps. Lecture figures show real data and use
  # ggplot2, which would be far too heavy for the browser apps, so their
  # helpers live here, in a separate file that the apps never load.
  # Sourcing this file has no side effects: no paths, no files, no fonts
  # registered; everything happens when a function is called.


# ***********************************************************
# Part 1: theme_lecture() ----
# ***********************************************************
# What: theme_classic() with dark text, light horizontal grid lines, a
#   left-aligned grey caption across the whole figure and no legend (lines
#   carry direct end labels instead).
# How: Segoe UI (the Windows/PowerPoint font) if systemfonts finds it on
#   this computer, else R's generic "sans".
# Used by: code/lecture05_kaopen_figures.R
theme_lecture <- function(base_size = 16) {
  fams <- unique(systemfonts::system_fonts()$family)
  font <- if ("Segoe UI" %in% fams) "Segoe UI" else "sans"
  ggplot2::theme_classic(base_size = base_size, base_family = font) +
    ggplot2::theme(
      text                  = ggplot2::element_text(colour = "grey15"),
      axis.text             = ggplot2::element_text(colour = "grey25"),
      axis.title            = ggplot2::element_text(colour = "grey15"),
      panel.grid.major.y    = ggplot2::element_line(colour = "grey90",
                                                    linewidth = 0.4),
      plot.caption          = ggplot2::element_text(colour = "grey40",
                                                    size = ggplot2::rel(0.62),
                                                    hjust = 0,
                                                    lineheight = 1.1),
      plot.caption.position = "plot",
      legend.position       = "none",
      strip.background      = ggplot2::element_blank(),
      strip.text            = ggplot2::element_text(face = "bold",
                                                    hjust = 0)
    )
}


# ***********************************************************
# Part 2: save_lecture_fig() ----
# ***********************************************************
# What: writes <name>.png (ragg, sharp text, 300 dpi) and <name>.pdf
#   (cairo_pdf, fonts embedded) on a white background, both into dir.
# How: dir is created if missing; both paths are printed, so the master's
#   log shows where every figure went. Returns the two paths invisibly.
# Used by: code/lecture05_kaopen_figures.R
save_lecture_fig <- function(p, name, dir, width = 10, height = 5.6,
                             dpi = 300) {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  f_png <- file.path(dir, paste0(name, ".png"))
  f_pdf <- file.path(dir, paste0(name, ".pdf"))
  ggplot2::ggsave(f_png, plot = p, device = ragg::agg_png, width = width,
                  height = height, units = "in", dpi = dpi, bg = "white")
  ggplot2::ggsave(f_pdf, plot = p, device = grDevices::cairo_pdf,
                  width = width, height = height, units = "in",
                  bg = "white")
  cat("Saved:", f_png, "\n      ", f_pdf, "\n")
  invisible(c(png = f_png, pdf = f_pdf))
}
