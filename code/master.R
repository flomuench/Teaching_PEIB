# ***********************************************************
# Title: SEES0082 Political Economy of International Business, UCL SSEES:
#        course website with interactive diagrams (Teaching_PEIB)
#
# Purpose: master script: runs every R step of the project in order
#       Part 1: Settings: clean start, folder paths, packages
#       Part 2: Load the model, drawing and lecture figure functions
#       Part 3: Tutorial 1 figures                          (on)
#       Part 4: Tutorial 2 figures                          (on)
#       Part 5: Tutorial 3 figures                          (on)
#       Part 6: Tutorial 4 figures                          (on)
#       Part 7: Tutorial 5 figures                          (on)
#       Parts 8-12: Tutorials 6 to 10 figures               (off)
#       Part 13: Lecture 5 data figures: Chinn-Ito index    (on)
#       Part 14: Lecture 5 data figure: IMF BOP inflows     (on)
#       Part 15: Build the website locally                  (off)
#       Part 16: Test an app locally as a normal Shiny app  (off)
#       Part 17: Session information
#
# Authors: Florian Münch
# Requires: the repository folder (the one with _quarto.yml), opened via
#     Teaching_PEIB.Rproj; the scripts in code/; internet access the first
#     time Parts 13 and 14 run (they download the Chinn-Ito and IMF data)
# Creates: figures/tutorialN/*.png (Parts 3 to 7: PNGs for the Word
#     handouts and the website); data/kaopen/ and figures/lecture5/
#     (Part 13: the Chinn-Ito data and the Lecture 5 figures);
#     data/imf_bop/ and outputs/lecture5_capital_inflows/ (Part 14: the
#     IMF balance of payments data and the capital inflows figure as PNG,
#     SVG, PDF, PPTX, CSV and notes); _site/ (Part 15: the rendered
#     website, not committed)
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
  # 4. New figures land in figures/tutorialN/ (e.g. figures/tutorial1/),
  #    lecture data figures in figures/lectureN/.
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
d_site <- file.path(root, "_site")       # rendered website (Part 15)
d_data <- file.path(root, "data")        # data for the lecture figures

# Chinn-Ito financial openness data (Part 13): raw = downloads (gitignored,
# re-created by code/kaopen_import.R), clean = csv files (committed)
d_kaopen_raw   <- file.path(d_data, "kaopen", "raw")
d_kaopen_clean <- file.path(d_data, "kaopen", "clean")

# One figures subfolder per tutorial: figures/tutorial1/, figures/tutorial2/,
# ... (no leading zero in the folder name). Add o_fig_t6 <- file.path(o_fig,
# "tutorial6") etc. here when the next tutorial's figures script exists.
o_fig_t1 <- file.path(o_fig, "tutorial1")   # Tutorial 1 figures (Part 3)
o_fig_t2 <- file.path(o_fig, "tutorial2")   # Tutorial 2 figures (Part 4)
o_fig_t3 <- file.path(o_fig, "tutorial3")   # Tutorial 3 figures (Part 5)
o_fig_t4 <- file.path(o_fig, "tutorial4")   # Tutorial 4 figures (Part 6)
o_fig_t5 <- file.path(o_fig, "tutorial5")   # Tutorial 5 figures (Part 7)

# Lecture data figures get figures/lectureN/, parallel to the tutorials
o_fig_l5 <- file.path(o_fig, "lecture5")    # Lecture 5 figures (Part 13)

# IMF balance of payments data (Part 14): raw = API downloads (gitignored,
# re-created by code/bop_import.R), clean = csv files (committed); the
# deliverables (PNG, SVG, PDF, PPTX, CSV, notes) go to outputs/
d_bop_raw   <- file.path(d_data, "imf_bop", "raw")
d_bop_clean <- file.path(d_data, "imf_bop", "clean")
o_out_l5    <- file.path(root, "outputs", "lecture5_capital_inflows")
# The course PowerPoint template (UCL Drive, outside the repo). If it is not
# found, the slide is built on officer's default 16:9 template instead.
f_pptx_template <- file.path(
  "C:/Users/flori/OneDrive - University College London/UCL teaching",
  "Political Economy of International Business/PEIB_Florian_Irakli",
  "lectures_tutorials/template_peib_slides.pptx")

dir.create(o_fig, showWarnings = FALSE)  # create figures/ if it is missing

### Packages ----
# Explanatory notes:
  # The tutorial figures need NO package: functions_models.R uses base R
  # only, because it is also bundled into the browser apps, where every
  # package means a longer download for students. Only the other parts
  # need one:
  #   shiny     - Part 16 runs an app on this computer as a normal Shiny app
  #   shinylive - Part 15: when Quarto renders the site, it calls this R
  #               package to turn each {shinylive-r} chunk into a browser app
  #   png       - Parts 4 to 7: only for the overview sheets (working
  #               files that show all figures at once); never used in apps
  #   the rest  - Part 13: the Lecture 5 data figures (ggplot2 and friends);
  #               never used in apps
  # Quarto itself is a separate program, not an R package (see README.md);
  # code/website_build.R calls it directly, so the quarto R package is not
  # needed. pacman::p_load() installs a package if it is missing, then
  # loads it.
options(repos = c(CRAN = "https://cran.rstudio.com"))
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")

pacman::p_load(
  # Interactive apps
  shiny,       # app_test.R (Part 16)
  shinylive,   # used by Quarto when rendering the website (Part 15)
  # Figure overview sheets (working files, not on the website)
  png,         # tutorial02/03/04_figures.R: reads the PNGs back in
  # Lecture data (Part 13)
  haven,       # kaopen_import.R: reads the Stata file
  curl,        # kaopen_import.R: downloads the data
  jsonlite,    # kaopen_import.R: writes the metadata file
  data.table,  # kaopen_clean.R (and the import and figure scripts)
  countrycode, # kaopen_clean.R: UN and World Bank regions
  # Lecture figures (Part 13)
  ggplot2,     # lecture05_kaopen_figures.R (and functions_lecture.R)
  ggrepel,     # lecture05_kaopen_figures.R: end labels
  scales,      # lecture05_kaopen_figures.R
  ragg,        # lecture05_kaopen_figures.R: PNG device (functions_lecture.R)
  systemfonts, # lecture05_kaopen_figures.R: font check (functions_lecture.R)
  # Lecture 5 IMF capital inflows figure (Part 14)
  imf.data,    # bop_import.R: IMF SDMX 3.0 API client
  svglite,     # lecture05_bop_figures.R: editable SVG
  officer,     # lecture05_bop_figures.R: PowerPoint slide
  rvg          # lecture05_bop_figures.R: editable vector graphic in the slide
)


# ***********************************************************
# Part 2: Load the model, drawing and lecture figure functions ----
# ***********************************************************
# Defines market_outcomes(), draw_market(), draw_firm_step(),
# draw_market_step() (Tutorial 1), chain_outcomes() and the draw_chain_*()
# functions (Tutorial 2), subsidy_outcomes(), draw_subsidy(), learning_cost()
# and draw_learning() (Tutorial 3), open_outcomes(), open_two_period() and
# the draw_open_*() functions (Tutorial 4), h2_outcomes(), draw_h2_steel(),
# fdi_outcomes() and draw_fdi_scenarios() (Tutorial 5), the colour palette
# peib_cols and their helpers.
# Nothing is drawn yet. (No echo: the file is 5,000 lines long.)
source(file.path(c_code, "functions_models.R"))
# theme_lecture() and save_lecture_fig(): the ggplot theme and the PNG/PDF
# save helper for the lecture data figures (Part 13). Never bundled into
# the apps, which load only functions_models.R.
source(file.path(c_code, "functions_lecture.R"))


# ***********************************************************
# Part 3: Tutorial 1 figures: markets, equilibrium and welfare ----
# ***********************************************************
# Writes the 13 Tutorial 1 PNGs into figures/tutorial1/ (overwriting the
# old ones) and prints the answer key numbers in the console.
if (1) source(file.path(c_code, "tutorial01_figures.R"), echo = TRUE)


# ***********************************************************
# Parts 4-12: Tutorials 2 to 10 ----
# ***********************************************************
# Explanatory notes:
  # Parts 8-12 are switched off (if (0)) because their scripts do not exist
  # yet; a switched-off line is skipped, so it cannot cause an error. When a
  # tutorial's figures are ready: copy code/tutorial04_figures.R to the new
  # name as a template (or code/tutorial05_figures.R), replace its
  # figures, then change if (0) to if (1).
  # Each tutorial saves its PNGs in its own folder figures/tutorialN/ (e.g.
  # Tutorial 6: figures/tutorial6/, path o_fig_t6 to be defined in Part 1;
  # in the copied script, replace every o_fig_t5 by o_fig_t6).

### Part 4: Tutorial 2: the nickel-battery value chain ----
# Writes the Tutorial 2 PNGs (student and tutor versions) and the overview
# sheet into figures/tutorial2/ and prints the answer key numbers.
if (1) source(file.path(c_code, "tutorial02_figures.R"), echo = TRUE)

### Part 5: Tutorial 3: government subsidies and learning-by-doing ----
# Writes the Tutorial 3 PNGs (noanswers and answers versions) and the overview
# sheet into figures/tutorial3/ and prints the answer key numbers. (The old
# tutorial01_market_tax.png, Part 6 of code/tutorial01_figures.R, is not
# used: the subsidy figures replace it.)
if (1) source(file.path(c_code, "tutorial03_figures.R"), echo = TRUE)

### Part 6: Tutorial 4: trade, a Home subsidy and international learning ----
# Writes the Tutorial 4 PNGs (noanswers and answers versions) and the overview
# sheet into figures/tutorial4/ and prints the answer key numbers, including
# the spillover slider table (theta = 0, 0.2, 0.5, 0.8, 1).
if (1) source(file.path(c_code, "tutorial04_figures.R"), echo = TRUE)

### Part 7: Tutorial 5: linked investments and FDI with local suppliers ----
# Writes the Tutorial 5 PNGs (noanswers and answers versions of Figures 1,
# 2 and 4; Figure 3 is TikZ) and the overview sheet into figures/tutorial5/,
# prints the answer key numbers and stops if one no longer matches the
# handout (Tables 2, 4, 8, 9 and A.1).
if (1) source(file.path(c_code, "tutorial05_figures.R"), echo = TRUE)

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
# Part 13: Lecture 5 data figures: Chinn-Ito financial openness by region ----
# ***********************************************************
# Explanatory notes:
  # Capital-account openness (Chinn-Ito index, 2023 update) by World Bank
  # region, 1970-2023, for Lecture 5 (MNEs, FDI & technology transfer). The raw
  # data are downloaded once (gitignored); the clean csv files and the
  # figures are committed.

# 13.1: Download (first run only) and import the Chinn-Ito data
#   Requires: internet access unless data/kaopen/raw/kaopen_2023.dta exists
#   Creates:  data/kaopen/raw/kaopen_2023.dta, Readme_kaopen2023.pdf,
#             kaopen_2023.csv, kaopen_2023_metadata.json
if (1) source(file.path(c_code, "kaopen_import.R"), echo = TRUE)
# 13.2: Clean, assign World Bank regions, region-year means, data checks
#   Requires: data/kaopen/raw/kaopen_2023.csv
#   Creates:  data/kaopen/clean/kaopen_country_year.csv,
#             kaopen_region_map.csv, kaopen_regions.csv
if (1) source(file.path(c_code, "kaopen_clean.R"), echo = TRUE)
# 13.3: Lecture 5 figures and headline numbers
#   Requires: data/kaopen/clean/kaopen_regions.csv
#   Creates:  figures/lecture5/lecture05_kaopen_regions(, _balanced,
#             _facets).png/.pdf, lecture05_kaopen_headline_numbers.csv
if (1) source(file.path(c_code, "lecture05_kaopen_figures.R"), echo = TRUE)


# ***********************************************************
# Part 14: Lecture 5 data figure: global financial inflows by type (IMF BOP) ----
# ***********************************************************
# Explanatory notes:
  # Gross cross-border financial inflows (net incurrence of liabilities:
  # FDI, portfolio equity, portfolio debt, financial derivatives, other
  # investment) and reserve accumulation, summed over all reporting
  # economies, as a percentage of world GDP, 1980-2025. Source: IMF BOP and
  # WEO via the SDMX 3.0 API. The raw downloads are cached (gitignored); set
  # BOP_FORCE_DOWNLOAD <- TRUE here to refresh them. Deliverables go to
  # outputs/lecture5_capital_inflows/.

# 14.1: Discover and verify the IMF codes, download (first run only)
#   Requires: internet access unless data/imf_bop/raw/ is complete
#   Creates:  data/imf_bop/raw/bop_country_raw.csv, bop_agg_raw.csv,
#             weo_gdp_raw.csv, bop_codelist_*.csv, bop_metadata.json
if (1) source(file.path(c_code, "bop_import.R"), echo = TRUE)
# 14.2: Country-year panel, world sums, coverage, validation, checks
#   Requires: data/imf_bop/raw/*.csv
#   Creates:  data/imf_bop/clean/bop_country_year.csv, bop_world_year.csv,
#             bop_coverage_year.csv, bop_agg_check.csv, bop_overlap_check.csv
if (1) source(file.path(c_code, "bop_clean.R"), echo = TRUE)
# 14.3: The stacked-area figure (PNG, SVG, PDF), the PowerPoint slide, the
#       figure csv, headline numbers and the methodology notes
#   Requires: data/imf_bop/clean/bop_world_year.csv, bop_coverage_year.csv,
#             bop_agg_check.csv; data/imf_bop/raw/bop_metadata.json
#   Creates:  outputs/lecture5_capital_inflows/lecture05_bop_inflows.png/
#             .svg/.pdf/.pptx, lecture05_bop_inflows_from1996.png/.pdf,
#             lecture05_bop_inflows_data.csv, lecture05_bop_headline_numbers.csv,
#             lecture05_bop_methodology.md
if (1) source(file.path(c_code, "lecture05_bop_figures.R"), echo = TRUE)


# ***********************************************************
# Part 15: Build the website locally (optional) ----
# ***********************************************************
# Checks the pages for known pitfalls, then renders the whole site into
# _site/ with Quarto, as GitHub does after every push: a way to catch errors
# BEFORE pushing. Nothing goes online from here; publishing still happens
# when you push with GitHub Desktop. Options at the top of website_build.R.
# (No echo here and in Part 16: these scripts report in plain messages.)
if (0) source(file.path(c_code, "website_build.R"))


# ***********************************************************
# Part 16: Test an app locally as a normal Shiny app (optional) ----
# ***********************************************************
# Copies the app of one tutorial page into a temporary folder and opens it
# in a browser window. The console is busy while the app runs: stop it with
# the red Stop sign in the console (or Esc).
# Choose the page and the app here (app_chunk: 1 = first app on the page):
#   tutorials/tutorial01_market.qmd          1 = the explorer
#   tutorials/tutorial02_linked_markets.qmd  1 = Explorer A, 2 = Explorer B
#   tutorials/tutorial03_subsidy.qmd         1 = the explorer
#   tutorials/tutorial04_open_economy.qmd    1 = the explorer
#   tutorials/tutorial05_linkages_fdi.qmd    1 = hydrogen and steel,
#                                            2 = FDI and local suppliers
app_qmd   <- "tutorials/tutorial01_market.qmd"
app_chunk <- 1
if (0) source(file.path(c_code, "app_test.R"))


# ***********************************************************
# Part 17: Session information ----
# ***********************************************************
# R version and package versions used: handy when something works on one
# computer but not on another. print() because "Source" does not auto-print.
print(sessionInfo())
