# ***********************************************************
# Title: SEES0082 Political Economy of International Business, UCL SSEES:
#        course website with interactive diagrams (Teaching_PEIB)
#
# Purpose: master script: runs every R step of the project in order
#       Part 1: Settings: clean start, folder paths, packages
#       Part 2: Load the model and drawing functions
#       Part 3: Tutorial 1 figures                          (on)
#       Parts 4-12: Tutorials 2 to 10 figures               (off)
#       Part 13: Build the website locally                  (off)
#       Part 14: Test an app locally as a normal Shiny app  (off)
#       Part 15: Session information
#
# Authors: Florian Münch
# Requires: the repository folder (the one with _quarto.yml), opened via
#     Teaching_PEIB.Rproj; the scripts in code/
# Creates: figures/tutorialN/*.png (Part 3: PNGs for the Word handouts
#     and the website); _site/ (Part 13: the rendered website, not
#     committed)
# ***********************************************************

# How to use (explanatory notes):
  # 1. Open Teaching_PEIB.Rproj in RStudio (double-click it). RStudio then
  #    starts in the repository folder.
  # 2. Open code/master.R and click "Source" (top right of the editor) or
  #    press Ctrl+Shift+S. Every part that is switched on runs, in order.
  # 3. if (1) switches a step on, if (0) switches it off: change only the
  #    1 or 0 to choose what runs. Parts 1 and 2 always run, because all
  #    other scripts rely on the paths, packages and functions they set up.
  #    To run one script by hand, first run Parts 1 and 2 (select the lines,
  #    Ctrl+Enter).
  # 4. New figures land in figures/tutorialN/ (e.g. figures/tutorial1/).
  #    Commit and push them with GitHub Desktop; GitHub then rebuilds and
  #    publishes the website by itself.


# ***********************************************************
# Part 1: Settings: clean start, folder paths, packages ----
# ***********************************************************

### Clean start ----
# Remove all objects from the workspace, so that leftovers from earlier work
# cannot change the results (only objects are removed, never files).
rm(list = ls())
# No random numbers are used yet; fixing the seed means any future
# simulation gives the same result every time the script runs.
set.seed(12345)

### Repository folder (multi-machine detection) ----
# USERPROFILE is the Windows home folder of whoever is logged in; R writes
# its backslash twice ("\\"). On Florian's laptop the repository has a fixed
# place. On any other computer we use the current working directory, which
# is the repository folder when Teaching_PEIB.Rproj was opened in RStudio.
user_profile <- Sys.getenv("USERPROFILE")

if (user_profile == "C:\\Users\\flori") {
  root <- "C:/Users/flori/Documents/GitHub/Teaching_PEIB"
} else {
  root <- getwd()
}

# _quarto.yml exists only in the repository's top folder. If it is not
# there, we are in the wrong folder and every path below would be wrong.
if (!file.exists(file.path(root, "_quarto.yml"))) {
  stop("Cannot find _quarto.yml in\n  ", root, "\n",
       "Open Teaching_PEIB.Rproj in RStudio (File > Open Project...) so that ",
       "R starts in the repository folder, then run code/master.R again. ",
       "(For a new computer you can also add its USERPROFILE and repository ",
       "path to the if/else block above.)", call. = FALSE)
}

### Folder paths ----
# Prefixes: c_ = code, o_ = outputs, d_ = other directories
c_code <- file.path(root, "code")        # all R scripts (this folder)
d_tut  <- file.path(root, "tutorials")   # the website's tutorial pages (.qmd)
o_fig  <- file.path(root, "figures")     # PNGs for handouts and website
d_site <- file.path(root, "_site")       # rendered website (Part 13)

# One figures subfolder per tutorial: figures/tutorial1/, figures/tutorial2/,
# ... (no leading zero in the folder name). Add o_fig_t2 <- file.path(o_fig,
# "tutorial2") etc. here when the next tutorial's figures script exists.
o_fig_t1 <- file.path(o_fig, "tutorial1")   # Tutorial 1 figures (Part 3)

dir.create(o_fig, showWarnings = FALSE)  # create figures/ if it is missing

### Packages ----
# Explanatory notes:
  # The figures need NO package: functions_models.R uses base R only,
  # because it is also bundled into the browser apps, where every package
  # means a longer download for students. Only two optional parts need one:
  #   shiny     - Part 14 runs an app on this computer as a normal Shiny app
  #   shinylive - Part 13: when Quarto renders the site, it calls this R
  #               package to turn each {shinylive-r} chunk into a browser app
  # Quarto itself is a separate program, not an R package (see README.md);
  # code/website_build.R calls it directly, so the quarto R package is not
  # needed. pacman::p_load() installs a package if it is missing, then
  # loads it.
options(repos = c(CRAN = "https://cran.rstudio.com"))
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")

pacman::p_load(
  # Interactive apps
  shiny,      # app_test.R (Part 14)
  shinylive   # used by Quarto when rendering the website (Part 13)
)


# ***********************************************************
# Part 2: Load the model and drawing functions ----
# ***********************************************************
# Defines market_outcomes(), draw_market(), draw_firm_step(),
# draw_market_step(), the colour palette peib_cols and their helpers.
# Nothing is drawn yet. (No echo: the file is 1,700 lines long.)
source(file.path(c_code, "functions_models.R"))


# ***********************************************************
# Part 3: Tutorial 1 figures: markets, equilibrium and welfare ----
# ***********************************************************
# Writes the 14 Tutorial 1 PNGs into figures/tutorial1/ (overwriting the
# old ones) and prints the answer key numbers in the console.
if (1) source(file.path(c_code, "tutorial01_figures.R"), echo = TRUE)


# ***********************************************************
# Parts 4-12: Tutorials 2 to 10 ----
# ***********************************************************
# Explanatory notes:
  # These lines are switched off (if (0)) because the scripts do not exist
  # yet; a switched-off line is skipped, so it cannot cause an error. When a
  # tutorial's figures are ready: copy code/tutorial01_figures.R to the new
  # name as a template, replace its figures, then change if (0) to if (1).
  # Each tutorial saves its PNGs in its own folder figures/tutorialN/ (e.g.
  # Tutorial 2: figures/tutorial2/, path o_fig_t2 defined in Part 1; in the
  # copied script, replace every o_fig_t1 by o_fig_t2).

### Part 4: Tutorial 2 ----
if (0) source(file.path(c_code, "tutorial02_figures.R"), echo = TRUE)

### Part 5: Tutorial 3 ----
# Will also take over tutorial01_market_tax.png (probably redrawn as a
# subsidy); see Part 6 of code/tutorial01_figures.R.
if (0) source(file.path(c_code, "tutorial03_figures.R"), echo = TRUE)

### Part 6: Tutorial 4 ----
if (0) source(file.path(c_code, "tutorial04_figures.R"), echo = TRUE)

### Part 7: Tutorial 5 ----
if (0) source(file.path(c_code, "tutorial05_figures.R"), echo = TRUE)

### Part 8: Tutorial 6 ----
if (0) source(file.path(c_code, "tutorial06_figures.R"), echo = TRUE)

### Part 9: Tutorial 7 ----
if (0) source(file.path(c_code, "tutorial07_figures.R"), echo = TRUE)

### Part 10: Tutorial 8 ----
if (0) source(file.path(c_code, "tutorial08_figures.R"), echo = TRUE)

### Part 11: Tutorial 9 ----
if (0) source(file.path(c_code, "tutorial09_figures.R"), echo = TRUE)

### Part 12: Tutorial 10 ----
if (0) source(file.path(c_code, "tutorial10_figures.R"), echo = TRUE)


# ***********************************************************
# Part 13: Build the website locally (optional) ----
# ***********************************************************
# Checks the pages for known pitfalls, then renders the whole site into
# _site/ with Quarto, as GitHub does after every push: a way to catch errors
# BEFORE pushing. Nothing goes online from here; publishing still happens
# when you push with GitHub Desktop. Options at the top of website_build.R.
# (No echo here and in Part 14: these scripts report in plain messages.)
if (0) source(file.path(c_code, "website_build.R"))


# ***********************************************************
# Part 14: Test an app locally as a normal Shiny app (optional) ----
# ***********************************************************
# Copies the app of one tutorial page (choose the page at the top of
# app_test.R) into a temporary folder and opens it in a browser window.
# The console is busy while the app runs: stop it with the red Stop sign
# in the console (or Esc).
if (0) source(file.path(c_code, "app_test.R"))


# ***********************************************************
# Part 15: Session information ----
# ***********************************************************
# R version and package versions used: handy when something works on one
# computer but not on another. print() because "Source" does not auto-print.
print(sessionInfo())
