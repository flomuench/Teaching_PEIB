# ***********************************************************
# Title: SEES0082 Political Economy of International Business, UCL SSEES:
#        course website with interactive diagrams (Teaching_PEIB)
#
# Purpose: discover, verify and download the IMF balance of payments series
#          behind the Lecture 5 figure on global cross-border financial
#          inflows by investment type (IMF SDMX 3.0 API via imf.data)
#       Part 1: Series specification and code verification against the
#               IMF code lists (never assume a code: check name and list)
#       Part 2: Download (skipped when the raw files are cached)
#       Part 3: Print what was downloaded
#
# Authors: Florian Münch
# Requires: Part 1 of code/master.R (path d_bop_raw; packages imf.data,
#     data.table, jsonlite); internet access on the first run
#     Source: IMF Data portal, https://data.imf.org/ (SDMX 3.0 API,
#     https://api.imf.org/external/sdmx/3.0), dataflows IMF.STA/BOP,
#     IMF.STA/BOP_AGG and IMF.RES/WEO
# Creates: in data/imf_bop/raw/ (gitignored, re-created by this script):
#     bop_country_raw.csv  - country-level BOP transactions, USD, annual
#         ID variables: country-indicator-accounting entry-year
#     bop_agg_raw.csv      - IMF world and group aggregates, USD, annual
#         ID variables: country group-indicator-year
#     weo_gdp_raw.csv      - WEO nominal GDP in USD, all economies + world
#         ID variables: country-year
#     bop_codelist_*.csv   - the IMF code lists used for verification
#     bop_metadata.json    - download date, dataflow versions, series list
# ***********************************************************

# Explanatory notes:
  # Run via code/master.R (Part 14), not on its own. The script is
  # idempotent: when every raw file exists in data/imf_bop/raw/ nothing is
  # downloaded again ("cache hit"). Set BOP_FORCE_DOWNLOAD <- TRUE before
  # sourcing the master to refresh the data (the IMF revises BOP data with
  # every monthly release, so a refresh changes the figure).
  # The IMF API returns a row only where an observation exists: a missing
  # country-year is an absent row, never an NA or a zero. Later scripts
  # keep it that way (no filling with zeros).
  # Units: OBS_VALUE is in plain US dollars although the SCALE attribute
  # says 6 (millions); checked against China's 2007 reserve accumulation
  # (460.7 billion USD) and world GDP 2024 (111.9 trillion USD).
  # Reserve assets: in the BOP dataflow the reserve transactions sit under
  # the accounting entry A_T ("Assets"), not A_NFA_T ("Assets, Net
  # acquisition of financial assets"), which returns no rows for R_F
  # (checked 5 Nov 2026). The BOP dataflow holds transactions only (stocks
  # are in the IIP dataflow), and the values are flows: China 2007 = 460.7
  # billion USD, and the world sum tracks the IMF aggregate R_A_AFR.

# Safety check: stop with a clear message if master.R Part 1 has not run
if (!exists("d_bop_raw")) {
  stop("d_bop_raw is missing. Run code/master.R (at least Parts 1 and 2) ",
       "instead of this script on its own.", call. = FALSE)
}
if (!exists("BOP_FORCE_DOWNLOAD")) BOP_FORCE_DOWNLOAD <- FALSE
dir.create(d_bop_raw, recursive = TRUE, showWarnings = FALSE)

f_country <- file.path(d_bop_raw, "bop_country_raw.csv")
f_agg     <- file.path(d_bop_raw, "bop_agg_raw.csv")
f_gdp     <- file.path(d_bop_raw, "weo_gdp_raw.csv")
f_meta    <- file.path(d_bop_raw, "bop_metadata.json")
f_cl      <- function(x) file.path(d_bop_raw, paste0("bop_codelist_", x, ".csv"))
cache_hit <- all(file.exists(c(f_country, f_agg, f_gdp, f_meta,
                               f_cl("bop_indicator"), f_cl("bop_entry"),
                               f_cl("bop_agg_indicator"),
                               f_cl("weo_indicator")))) && !BOP_FORCE_DOWNLOAD
cat("Settings of record: BOP_FORCE_DOWNLOAD =", BOP_FORCE_DOWNLOAD,
    "| cache hit =", cache_hit, "\n")


# ***********************************************************
# Part 1: Series specification and code verification ----
# ***********************************************************
# What: the exact IMF codes used downstream, each with the name the code
#   list must show for it. A mismatch stops the script: a silent change in
#   the IMF code lists would otherwise feed the wrong series into the figure.
# How: the code lists come from the API (list_dimension_values) on a fresh
#   run and from the cached csv files otherwise.

### Country-level BOP (dataflow IMF.STA/BOP, version 21 at first download) ----
# component = our snake_case name; indicator + entry = IMF dimension codes.
# Inflows are "net incurrence of liabilities" (BPM6: positive = foreigners
# add to their claims on the economy). Reserves are on the asset side, so
# their accounting entry is "Assets" (net acquisition, transactions).
bop_series <- data.table::data.table(
  component = c("fdi", "portfolio_total", "portfolio_equity", "portfolio_debt",
                "derivatives", "other", "reserves"),
  indicator = c("D_F", "P_F", "P_F5", "P_F3", "F_F7", "O_F", "R_F"),
  entry     = c(rep("L_NIL_T", 6), "A_T"),
  indicator_name = c(
    "Direct investment, Total financial assets/liabilities",
    "Portfolio investment, Total financial assets/liabilities",
    "Portfolio investment, Equity and investment fund shares",
    "Portfolio investment, Debt securities",
    "Financial derivatives (other than reserves) and employee stock options",
    "Other investment, Total financial assets/liabilities",
    "Reserve assets, Total financial /liabilities"),
  entry_name = c(rep("Liabilities, Net incurrence of liabilities", 6), "Assets")
)

### IMF aggregates (dataflow IMF.STA/BOP_AGG): validation only ----
# GX010 = "All Countries and International Organizations" (the IMF's world
# total, 2005 onwards). Portfolio investment is not split there.
agg_series <- data.table::data.table(
  component = c("fdi", "portfolio_total", "derivatives", "other", "reserves",
                "financial_account"),
  indicator = c("D_NIL_L", "P_NIL_L", "F7_NIL_L", "O_NIL_L_AFR", "R_A_AFR",
                "FAB_NNAFANIL_AFR"),
  indicator_name = c(
    "Direct investment, Net incurrence of liabilities, Liabilities",
    "Portfolio investment, Net incurrence of liabilities, Liabilities",
    paste0("Financial derivatives (other than reserves) and employee stock ",
           "options, Net incurrence of liabilities, Liabilities"),
    paste0("Other investment, Net incurrence of liabilities, Liabilities, ",
           "Adjusted using IMF accounting records"),
    "Reserve assets, Assets, Adjusted using IMF accounting records",
    paste0("Financial account balance (assets less liabilities), Net (net ",
           "acquisition of financial assets less net incurrence of ",
           "liabilities), Adjusted using IMF accounting records"))
)
agg_groups <- c("GX010", "G110", "G200")   # world, advanced, emerging+developing

### World GDP (dataflow IMF.RES/WEO) ----
weo_indicator <- "NGDPD"   # Gross domestic product (GDP), Current prices, US dollar
weo_world     <- "G001"    # World

### Fetch or read the code lists ----
get_codelist <- function(name, dataflow, dimension, agency = "IMF.STA") {
  f <- f_cl(name)
  if (cache_hit && file.exists(f)) return(data.table::fread(f))
  cl <- imf.data::list_dimension_values(dataflow, dimension, agency_id = agency)
  data.table::setDT(cl)
  data.table::fwrite(cl, f)
  cl
}
cl_ind   <- get_codelist("bop_indicator",     "BOP",     "INDICATOR")
cl_entry <- get_codelist("bop_entry",         "BOP",     "BOP_ACCOUNTING_ENTRY")
cl_unit  <- get_codelist("bop_unit",          "BOP",     "UNIT")
cl_ctry  <- get_codelist("bop_country",       "BOP",     "COUNTRY")
cl_agg   <- get_codelist("bop_agg_indicator", "BOP_AGG", "INDICATOR")
cl_aggc  <- get_codelist("bop_agg_country",   "BOP_AGG", "COUNTRY")
cl_weo   <- get_codelist("weo_indicator",     "WEO",     "INDICATOR", "IMF.RES")
cl_weoc  <- get_codelist("weo_country",       "WEO",     "COUNTRY",   "IMF.RES")

### Verify every code and its name ----
check_codes <- function(spec, codelist, code_col, name_col, what) {
  found <- codelist[match(spec[[code_col]], codelist$code), ]
  bad <- is.na(found$code) | trimws(found$name) != trimws(spec[[name_col]])
  if (any(bad)) {
    cat("\nCode verification failed for", what, ":\n")
    print(data.frame(code = spec[[code_col]][bad], expected = spec[[name_col]][bad],
                     found = found$name[bad]))
    stop("IMF code list no longer matches the series specification (", what,
         "). Check the codes above on https://data.imf.org/ and update ",
         "code/bop_import.R.", call. = FALSE)
  }
  cat("Verified", nrow(spec), what, "codes against the IMF code list\n")
}
check_codes(bop_series, cl_ind, "indicator", "indicator_name", "BOP indicator")
check_codes(unique(bop_series[, .(entry, entry_name)]), cl_entry, "entry",
            "entry_name", "BOP accounting entry")
check_codes(agg_series, cl_agg, "indicator", "indicator_name", "BOP_AGG indicator")
stopifnot("USD" %in% cl_unit$code,
          all(agg_groups %in% cl_aggc$code),
          cl_aggc[code == "GX010", name] ==
            "All Countries and International Organizations",
          cl_weo[code == weo_indicator, name] ==
            "Gross domestic product (GDP), Current prices, US dollar",
          cl_weoc[code == weo_world, name] == "World")
cat("Verified units, aggregate groups and the WEO GDP series\n")


# ***********************************************************
# Part 2: Download (skipped when cached) ----
# ***********************************************************
# What: three raw csv files plus a metadata file.
# How: imf.data::get_data() with explicit filters; a result with zero rows
#   or without the expected columns stops the script.
pull <- function(dataflow, filters, agency = "IMF.STA", expect_cols) {
  x <- tryCatch(imf.data::get_data(dataflow, filters = filters, agency_id = agency),
                error = function(e) stop("IMF API download failed for ", dataflow,
                                         ": ", conditionMessage(e), call. = FALSE))
  data.table::setDT(x)
  if (nrow(x) == 0 || !all(expect_cols %in% names(x))) {
    stop("IMF API returned no usable data for ", dataflow, " (rows = ", nrow(x),
         "; columns = ", paste(names(x), collapse = ", "), ").", call. = FALSE)
  }
  x
}

if (cache_hit) {
  cat("Raw files: cache hit, no download (", d_bop_raw, ")\n")
} else {
  t0 <- Sys.time()
  bop_cols <- c("COUNTRY", "BOP_ACCOUNTING_ENTRY", "INDICATOR", "UNIT",
                "FREQUENCY", "TIME_PERIOD", "OBS_VALUE")

  ### 2.1 Country-level BOP: liabilities (6 series) and reserve assets ----
  liab <- pull("BOP",
               filters = list(INDICATOR = bop_series[entry == "L_NIL_T", indicator],
                              BOP_ACCOUNTING_ENTRY = "L_NIL_T", UNIT = "USD",
                              FREQUENCY = "A"),
               expect_cols = bop_cols)
  resv <- pull("BOP",
               filters = list(INDICATOR = bop_series[entry == "A_T", indicator],
                              BOP_ACCOUNTING_ENTRY = "A_T", UNIT = "USD",
                              FREQUENCY = "A"),
               expect_cols = bop_cols)
  bop_country_raw <- data.table::rbindlist(list(liab, resv), use.names = TRUE)
  data.table::fwrite(bop_country_raw, f_country)
  cat("bop_country_raw.csv:", nrow(bop_country_raw), "rows\n")

  ### 2.2 IMF world and group aggregates (USD) ----
  bop_agg_raw <- pull("BOP_AGG",
                      filters = list(COUNTRY = agg_groups,
                                     INDICATOR = agg_series$indicator,
                                     TYPE_OF_TRANSFORMATION = "USD",
                                     FREQUENCY = "A"),
                      expect_cols = c("COUNTRY", "INDICATOR",
                                      "TYPE_OF_TRANSFORMATION", "TIME_PERIOD",
                                      "OBS_VALUE"))
  data.table::fwrite(bop_agg_raw, f_agg)
  cat("bop_agg_raw.csv:", nrow(bop_agg_raw), "rows\n")

  ### 2.3 WEO nominal GDP in USD, all economies and aggregates ----
  weo_gdp_raw <- pull("WEO", agency = "IMF.RES",
                      filters = list(INDICATOR = weo_indicator, FREQUENCY = "A"),
                      expect_cols = c("COUNTRY", "INDICATOR", "TIME_PERIOD",
                                      "OBS_VALUE"))
  data.table::fwrite(weo_gdp_raw, f_gdp)
  cat("weo_gdp_raw.csv:", nrow(weo_gdp_raw), "rows\n")

  ### 2.4 Metadata: what was downloaded when, from which dataflow version ----
  ds <- imf.data::list_datasets(); data.table::setDT(ds)
  meta <- list(
    downloaded   = format(Sys.time(), "%Y-%m-%d %H:%M %Z"),
    api_base_url = "https://api.imf.org/external/sdmx/3.0",
    r_package    = paste("imf.data", as.character(packageVersion("imf.data"))),
    dataflows    = ds[id %in% c("BOP", "BOP_AGG", "WEO") &
                      agency %in% c("IMF.STA", "IMF.RES"),
                      .(agency, id, version, name)],
    bop_series   = bop_series,
    agg_series   = agg_series,
    agg_groups   = agg_groups,
    weo          = list(indicator = weo_indicator, world = weo_world),
    units        = "OBS_VALUE in US dollars (not millions), annual",
    note         = paste("A missing country-year is an absent row in the API",
                         "response; never filled with zero downstream.")
  )
  jsonlite::write_json(meta, f_meta, pretty = TRUE, auto_unbox = TRUE)
  cat("Downloads finished in", format(round(Sys.time() - t0, 1)), "\n")
  rm(liab, resv, ds, t0)
}


# ***********************************************************
# Part 3: Print what was downloaded ----
# ***********************************************************
bop_country_raw <- data.table::fread(f_country)
bop_agg_raw     <- data.table::fread(f_agg)
weo_gdp_raw     <- data.table::fread(f_gdp)
meta            <- jsonlite::read_json(f_meta)
cat("\nIMF data downloaded on", meta$downloaded, "with", meta$r_package, "\n")
print(data.table::rbindlist(meta$dataflows))
cat("\nCountry-level BOP rows per series and year range:\n")
print(bop_country_raw[, .(rows = .N, reporters = data.table::uniqueN(COUNTRY),
                          first = min(TIME_PERIOD), last = max(TIME_PERIOD)),
                      by = .(INDICATOR, BOP_ACCOUNTING_ENTRY)])
cat("\nIMF aggregates:", nrow(bop_agg_raw), "rows,",
    min(bop_agg_raw$TIME_PERIOD), "-", max(bop_agg_raw$TIME_PERIOD), "\n")
cat("WEO GDP:", nrow(weo_gdp_raw), "rows,",
    data.table::uniqueN(weo_gdp_raw$COUNTRY), "economies and groups,",
    min(weo_gdp_raw$TIME_PERIOD), "-", max(weo_gdp_raw$TIME_PERIOD),
    "(includes projections)\n")
rm(pull, get_codelist, check_codes, cl_ind, cl_entry, cl_unit, cl_ctry, cl_agg,
   cl_aggc, cl_weo, cl_weoc)
