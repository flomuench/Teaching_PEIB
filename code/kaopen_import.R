# ***********************************************************
# Title: SEES0082 Political Economy of International Business, UCL SSEES:
#        course website with interactive diagrams (Teaching_PEIB)
#
# Purpose: download and import the Chinn-Ito financial openness index
#          (KAOPEN, 2023 update) for the Lecture 5 data figures
#       Part 1: Download the Stata file and the readme (skipped if cached)
#       Part 2: Read the Stata file, strip labels, write csv and metadata
#       Part 3: Print what was imported
#
# Authors: Florian Münch
# Requires: Part 1 of code/master.R (path d_kaopen_raw; packages haven,
#     curl, jsonlite, data.table); internet access on the first run only
#     Source: https://web.pdx.edu/~ito/Chinn-Ito_website.htm
# Creates: in data/kaopen/raw/ (gitignored, re-created by this script):
#     kaopen_2023.dta, Readme_kaopen2023.pdf (downloads),
#     kaopen_2023.csv (all rows, labels stripped)
#         ID variables: ccode-year
#     kaopen_2023_metadata.json (source, download date, citation, variables)
# ***********************************************************

# Explanatory notes:
  # Run via code/master.R (Part 13), not on its own. The script is
  # idempotent: if kaopen_2023.dta is already in data/kaopen/raw/, nothing
  # is downloaded again ("cache hit"); delete the file to force a fresh
  # download. Chinn and Ito recalculate the whole index with every update,
  # so a newer file (e.g. kaopen_2024) is NOT comparable with this one:
  # change the file names below only together with the figures.
  # A download is first saved as <file>.part and renamed only when its
  # first bytes show the expected format (a Stata 117 file starts with
  # "<stata_dta>", a PDF with "%PDF"); an error page from the server is
  # therefore never mistaken for the data.

# Safety check: stop with a clear message if master.R Part 1 has not run
if (!exists("d_kaopen_raw")) {
  stop("d_kaopen_raw is missing. Run code/master.R (at least Parts 1 and 2) ",
       "instead of this script on its own.", call. = FALSE)
}


# ***********************************************************
# Part 1: Download the Stata file and the readme ----
# ***********************************************************
# What: kaopen_2023.dta (required) and Readme_kaopen2023.pdf (nice to have)
#   in data/kaopen/raw/.
# How: curl::curl_download() into a .part file, check the first bytes,
#   rename. A failed data download stops with a manual-download
#   instruction; a failed readme download only prints a message.
url_site   <- "https://web.pdx.edu/~ito/Chinn-Ito_website.htm"
url_dta    <- "https://web.pdx.edu/~ito/kaopen_2023.dta"
url_readme <- "https://web.pdx.edu/~ito/Readme_kaopen2023.pdf"
f_dta      <- file.path(d_kaopen_raw, "kaopen_2023.dta")
f_readme   <- file.path(d_kaopen_raw, "Readme_kaopen2023.pdf")
f_csv      <- file.path(d_kaopen_raw, "kaopen_2023.csv")
f_meta     <- file.path(d_kaopen_raw, "kaopen_2023_metadata.json")

dir.create(d_kaopen_raw, recursive = TRUE, showWarnings = FALSE)

### Data file (required) ----
if (file.exists(f_dta)) {
  cat("kaopen_2023.dta: cache hit, no download (", f_dta, ")\n")
} else {
  f_part <- paste0(f_dta, ".part")
  ok <- tryCatch({
    curl::curl_download(url_dta, f_part, quiet = TRUE)
    first <- readBin(f_part, "raw", n = 11)
    identical(rawToChar(first), "<stata_dta>")
  }, error = function(e) FALSE)
  if (!ok) {
    if (file.exists(f_part)) file.remove(f_part)
    stop("Download of kaopen_2023.dta failed or did not return a Stata ",
         "file. Download it by hand from\n  ", url_dta, "\n(linked on ",
         url_site, ") and save it as\n  ", f_dta, "\nthen run the master ",
         "again.", call. = FALSE)
  }
  file.rename(f_part, f_dta)
  cat("kaopen_2023.dta: downloaded to", f_dta, "\n")
}

### Readme (optional, for the figure captions) ----
if (file.exists(f_readme)) {
  cat("Readme_kaopen2023.pdf: cache hit, no download\n")
} else {
  f_part <- paste0(f_readme, ".part")
  ok <- tryCatch({
    curl::curl_download(url_readme, f_part, quiet = TRUE)
    first <- readBin(f_part, "raw", n = 4)
    identical(rawToChar(first), "%PDF")
  }, error = function(e) FALSE)
  if (ok) {
    file.rename(f_part, f_readme)
    cat("Readme_kaopen2023.pdf: downloaded to", f_readme, "\n")
  } else {
    if (file.exists(f_part)) file.remove(f_part)
    message("Readme_kaopen2023.pdf could not be downloaded (not needed for ",
            "the figures): ", url_readme)
  }
}


# ***********************************************************
# Part 2: Read the Stata file, strip labels, write csv and metadata ----
# ***********************************************************
# What: kaopen_2023.csv with the six variables as plain numbers and text,
#   and a json file that records where the data came from.
# How: haven::read_dta() keeps Stata labels as attributes; as.numeric() and
#   as.character() remove them, so later scripts see plain columns.
kaopen_raw <- haven::read_dta(f_dta)
setDT(kaopen_raw)
setnames(kaopen_raw, names(kaopen_raw), tolower(names(kaopen_raw)))

keep_vars <- c("cn", "ccode", "country_name", "year", "kaopen", "ka_open")
missing_vars <- setdiff(keep_vars, names(kaopen_raw))
if (length(missing_vars) > 0) {
  stop("kaopen_2023.dta lacks the variable(s): ",
       paste(missing_vars, collapse = ", "), call. = FALSE)
}
kaopen_raw <- kaopen_raw[, ..keep_vars]
kaopen_raw[, `:=`(cn           = as.numeric(cn),
                  ccode        = as.character(ccode),
                  country_name = as.character(country_name),
                  year         = as.integer(year),
                  kaopen       = as.numeric(kaopen),
                  ka_open      = as.numeric(ka_open))]
setorder(kaopen_raw, ccode, year)
fwrite(kaopen_raw, f_csv, eol = "\n")   # LF line endings on every OS

meta <- list(
  dataset       = "Chinn-Ito index of financial openness (KAOPEN), 2023 update",
  source_url    = url_site,
  file_url      = url_dta,
  readme_url    = url_readme,
  download_date = format(file.info(f_dta)$mtime, "%Y-%m-%d"),
  citation      = paste0(
    "Chinn, M. D. & Ito, H. (2006). What Matters for Financial ",
    "Development? Capital Controls, Institutions, and Interactions. ",
    "Journal of Development Economics, 81(1), 163-192. Data: 2023 update ",
    "(January 2026), ", url_site),
  definition    = paste0(
    "First principal component of four binary variables from the IMF ",
    "AREAER: restrictions on capital account transactions, restrictions on ",
    "current account transactions, multiple exchange rates, requirement to ",
    "surrender export proceeds. Recalculated with every update: versions ",
    "are not comparable."),
  variables     = list(
    cn           = "IMF-World Bank numeric country code",
    ccode        = "ISO 3166 alpha-3 country code (as in the source file)",
    country_name = "country name (as in the source file)",
    year         = "calendar year",
    kaopen       = "Chinn-Ito index (first principal component, not bounded)",
    ka_open      = "Chinn-Ito index normalised to 0-1"),
  unit_ka_open  = "index, 0 = most closed, 1 = most open"
)
jsonlite::write_json(meta, f_meta, auto_unbox = TRUE, pretty = TRUE)
cat("Written:", f_csv, "\n        ", f_meta, "\n")


# ***********************************************************
# Part 3: Print what was imported ----
# ***********************************************************
# The readme (p. 1) speaks of 182 countries; the file has more distinct
# codes. We report the difference and do not "fix" it.
readme_n_countries <- 182L
cat("\nChinn-Ito KAOPEN 2023, as imported:\n")
cat(sprintf("  rows: %d; distinct codes (ccode): %d; years: %d-%d\n",
            nrow(kaopen_raw), uniqueN(kaopen_raw$ccode),
            min(kaopen_raw$year), max(kaopen_raw$year)))
cat(sprintf("  missing kaopen: %d; missing ka_open: %d\n",
            sum(is.na(kaopen_raw$kaopen)), sum(is.na(kaopen_raw$ka_open))))
cat(sprintf("  countries per readme: %d; distinct codes in file: %d\n",
            readme_n_countries, uniqueN(kaopen_raw$ccode)))
