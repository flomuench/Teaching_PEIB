# ***********************************************************
# Title: SEES0082 Political Economy of International Business, UCL SSEES:
#        course website with interactive diagrams (Teaching_PEIB)
#
# Purpose: clean the Chinn-Ito index, assign world regions and build the
#          region-year means for the Lecture 5 figures
#       Part 1: Read the imported csv and check its structure
#       Part 2: Assign each country to one of the seven World Bank regions
#       Part 3: Write the country-year file and the region map
#       Part 4: Region-year aggregates (all countries; balanced panel)
#       Part 5: Data checks
#
# Authors: Florian Münch
# Requires: data/kaopen/raw/kaopen_2023.csv (code/kaopen_import.R);
#     Part 1 of code/master.R (paths d_kaopen_raw, d_kaopen_clean;
#     packages data.table, countrycode)
#         ID variables: ccode-year
# Creates: in data/kaopen/clean/ (committed):
#     kaopen_country_year.csv  code, entity, year, kaopen, ka_open,
#                              region_wb, region_un_sub, region
#         ID variables: code-year
#     kaopen_region_map.csv    one row per country: its World Bank region,
#                              whether it was set by hand, years with data,
#                              balanced
#         ID variables: code
#     kaopen_regions.csv       sample, region, year, n_countries,
#                              mean/median/p25/p75 of ka_open, mean_kaopen
#         ID variables: sample-region-year
# ***********************************************************

# Explanatory notes:
  # Regions: the seven World Bank regions, read via the countrycode package
  # (destination "region"; Florian's decision of 3 Nov 2026, replacing a
  # mixed UN/World Bank definition). Only codes that countrycode cannot
  # read get an explicit fix (Part 2). The UN sub-region is kept as a
  # reference column.
  # Means are UNWEIGHTED (one country, one vote): the index describes a
  # policy regime, and GDP weights would let the United States and China
  # dominate their regions.
  # Two samples: "all" = every country with data in that year (the
  # composition changes, e.g. post-Soviet states enter in the early 1990s);
  # "balanced" = only countries with data in every year 1970-2023.
  # Structural problems (duplicates, codes without a region) stop the
  # script; implausible values only give a warning.

# Safety check: stop with a clear message if master.R Part 1 has not run
if (!exists("d_kaopen_raw") || !exists("d_kaopen_clean")) {
  stop("d_kaopen_raw or d_kaopen_clean is missing. Run code/master.R (at ",
       "least Parts 1 and 2) instead of this script on its own.",
       call. = FALSE)
}
f_raw_csv <- file.path(d_kaopen_raw, "kaopen_2023.csv")
if (!file.exists(f_raw_csv)) {
  stop("Missing ", f_raw_csv, ". Run code/kaopen_import.R (master Part 13) ",
       "first.", call. = FALSE)
}


# ***********************************************************
# Part 1: Read the imported csv and check its structure ----
# ***********************************************************
# What: kaopen (data.table) with code, entity, year, kaopen, ka_open.
# How: dated code and name corrections (Serbia; Cote d'Ivoire, Sao Tome
#   and Principe), then three structural checks:
#   ISO3 pattern, no duplicate code-year, years 1970-2023.
kaopen <- fread(f_raw_csv, encoding = "UTF-8")

### Code corrections (2026-11-03) ----
# The 2023 file stores Serbia (cn 942, "Serbia, Rep. of") with ccode "."
# instead of SRB. All its values are missing, but the code must be valid
# for the checks and the region map.
kaopen[ccode == "." & cn == 942, ccode := "SRB"]

### Name corrections (2026-11-03) ----
# Two names lost their accented letter in the source file ("C?e d'Ivoire",
# "S? Tom and Principe"). Corrected by ISO3 code, not by the broken text,
# and written in plain ASCII.
kaopen[ccode == "CIV", country_name := "Cote d'Ivoire"]
kaopen[ccode == "STP", country_name := "Sao Tome and Principe"]

### Structural checks ----
bad_iso <- unique(kaopen[!grepl("^[A-Z]{3}$", ccode), .(ccode, country_name)])
if (nrow(bad_iso) > 0) {
  print(bad_iso)
  stop("Country codes that are not three capital letters (see above).",
       call. = FALSE)
}
dups <- kaopen[, .N, by = .(ccode, year)][N > 1]
if (nrow(dups) > 0) {
  print(dups)
  stop("Duplicate code-year rows (see above).", call. = FALSE)
}
if (min(kaopen$year) != 1970 || max(kaopen$year) != 2023) {
  stop("Years run from ", min(kaopen$year), " to ", max(kaopen$year),
       ", expected 1970-2023.", call. = FALSE)
}

setnames(kaopen, c("ccode", "country_name"), c("code", "entity"))
kaopen[, cn := NULL]


# ***********************************************************
# Part 2: Assign each country to one of the seven World Bank regions ----
# ***********************************************************
# What: region_map, one row per code, with region_wb (World Bank region
#   name), region_un_sub (UN sub-region, reference only) and region (the
#   World Bank region in snake_case; display labels only in the figures).
# How: countrycode(code, "iso3c", "region"). The classification comes with
#   the countrycode package, so its version is printed below (1.7.0 when
#   this script was written, 2026-11-03): a new version can move countries.
region_map <- unique(kaopen[, .(code, entity)])
if (uniqueN(region_map$code) != nrow(region_map)) {
  stop("A code has more than one country name in the file.", call. = FALSE)
}

# World Bank region name -> internal snake_case value
wb_regions <- c("East Asia & Pacific"        = "east_asia_pacific",
                "Europe & Central Asia"      = "europe_central_asia",
                "Latin America & Caribbean"  = "lac",
                "Middle East & North Africa" = "mena",
                "North America"              = "north_america",
                "South Asia"                 = "south_asia",
                "Sub-Saharan Africa"         = "ssa")

### Code fixes for countrycode (2026-11-03) ----
# Old codes that countrycode does not know: look them up under the current
# ISO3 code (the code in the data stays as it is). (Serbia's "." is fixed
# to SRB in Part 1.)
code_alias <- c(TMP = "TLS",   # Timor-Leste (old code)
                ZAR = "COD")   # Congo, Dem. Rep. (old code)
# No ISO3 code at all: set the World Bank region by hand.
wb_override <- c(ANT = "Latin America & Caribbean")  # Netherlands Antilles,
                                                     # dissolved 2010

region_map[, code_lookup := fifelse(code %in% names(code_alias),
                                    code_alias[code], code)]
region_map[, region_un_sub := countrycode(code_lookup, "iso3c",
                                          "un.regionsub.name", warn = FALSE)]
region_map[, region_wb     := countrycode(code_lookup, "iso3c", "region",
                                          warn = FALSE)]
region_map[, override := code %in% names(wb_override)]
region_map[override == TRUE, region_wb := wb_override[code]]
region_map[, region := unname(wb_regions[region_wb])]

unmapped <- region_map[is.na(region)]
if (nrow(unmapped) > 0) {
  print(unmapped)
  stop("Codes without a World Bank region (see above): add them to ",
       "code_alias or wb_override.", call. = FALSE)
}
cat("\nWorld Bank regions from countrycode",
    as.character(packageVersion("countrycode")),
    "\nCodes looked up under a current ISO3 code:",
    paste(names(code_alias), code_alias, sep = " -> ", collapse = "; "),
    "\nRegion set by hand:",
    paste(names(wb_override), wb_override, sep = " -> ", collapse = "; "),
    "\n")


# ***********************************************************
# Part 3: Write the country-year file and the region map ----
# ***********************************************************
# What: kaopen_country_year.csv and kaopen_region_map.csv.
# How: years with data per country counted on ka_open; "balanced" = data in
#   every year of the file.
n_years_file <- uniqueN(kaopen$year)
kaopen <- merge(kaopen,
                region_map[, .(code, region_wb, region_un_sub, region)],
                by = "code", all.x = TRUE)
setcolorder(kaopen, c("code", "entity", "year", "kaopen", "ka_open",
                      "region_wb", "region_un_sub", "region"))
setorder(kaopen, code, year)

# first_year and last_year: first and last year WITH data (NA if none)
years_data <- kaopen[, .(first_year = if (all(is.na(ka_open))) NA_integer_
                                      else min(year[!is.na(ka_open)]),
                         last_year  = if (all(is.na(ka_open))) NA_integer_
                                      else max(year[!is.na(ka_open)]),
                         n_years    = sum(!is.na(ka_open))), by = code]
region_map <- merge(region_map, years_data, by = "code", all.x = TRUE)
region_map[, balanced := n_years == n_years_file]
region_map <- region_map[, .(code, entity, region_wb, region_un_sub, region,
                             override, first_year, last_year, n_years,
                             balanced)]
setorder(region_map, region, code)

dir.create(d_kaopen_clean, recursive = TRUE, showWarnings = FALSE)
# eol = "\n": on Windows fwrite writes CRLF by default; LF keeps the
# committed csv files identical on every computer
fwrite(kaopen, file.path(d_kaopen_clean, "kaopen_country_year.csv"),
       eol = "\n")
fwrite(region_map, file.path(d_kaopen_clean, "kaopen_region_map.csv"),
       eol = "\n")
cat("Written:", file.path(d_kaopen_clean, "kaopen_country_year.csv"), "\n",
    "        ", file.path(d_kaopen_clean, "kaopen_region_map.csv"), "\n")


# ***********************************************************
# Part 4: Region-year aggregates ----
# ***********************************************************
# What: kaopen_regions.csv: per sample, region (seven regions plus "world")
#   and year, the number of countries with data and the unweighted mean,
#   median and interquartile range of ka_open (plus the mean of kaopen).
# How: one loop over the two samples; the world rows are the same
#   statistics without the region grouping.
balanced_codes <- region_map[balanced == TRUE, code]
samples <- list(all      = kaopen[!is.na(ka_open)],
                balanced = kaopen[!is.na(ka_open) & code %in% balanced_codes])

regions_list <- list()
for (s in names(samples)) {
  temp_dt <- samples[[s]]
  by_region <- temp_dt[, .(n_countries    = .N,
                           mean_ka_open   = mean(ka_open),
                           median_ka_open = median(ka_open),
                           p25_ka_open    = quantile(ka_open, 0.25,
                                                     names = FALSE),
                           p75_ka_open    = quantile(ka_open, 0.75,
                                                     names = FALSE),
                           mean_kaopen    = mean(kaopen)),
                       by = .(region, year)]
  world <- temp_dt[, .(region         = "world",
                       n_countries    = .N,
                       mean_ka_open   = mean(ka_open),
                       median_ka_open = median(ka_open),
                       p25_ka_open    = quantile(ka_open, 0.25, names = FALSE),
                       p75_ka_open    = quantile(ka_open, 0.75, names = FALSE),
                       mean_kaopen    = mean(kaopen)),
                   by = year]
  regions_list[[s]] <- rbindlist(list(by_region, world), use.names = TRUE)
  regions_list[[s]][, sample := s]
  rm(temp_dt, by_region, world)
}
kaopen_regions <- rbindlist(regions_list, use.names = TRUE)
setcolorder(kaopen_regions, c("sample", "region", "year"))
setorder(kaopen_regions, sample, region, year)
fwrite(kaopen_regions, file.path(d_kaopen_clean, "kaopen_regions.csv"),
       eol = "\n")
cat("Written:", file.path(d_kaopen_clean, "kaopen_regions.csv"), "\n")


# ***********************************************************
# Part 5: Data checks ----
# ***********************************************************
# What: values we know from the readme and the source file. Printed with
#   cat(); a failed value check gives a warning.
cat("\nData checks (Chinn-Ito KAOPEN 2023):\n")

usa <- kaopen[code == "USA" & year %in% c(1970, 2023), ka_open]
cat(sprintf("  USA ka_open in 1970 and 2023: %s (expected 1 and 1)\n",
            paste(usa, collapse = ", ")))
if (!isTRUE(all.equal(usa, c(1, 1)))) warning("USA ka_open is not 1.")

rng <- round(range(kaopen$kaopen, na.rm = TRUE), 3)
cat(sprintf("  kaopen min and max: %.3f, %.3f (expected -1.939, 2.281)\n",
            rng[1], rng[2]))
if (!isTRUE(all.equal(rng, c(-1.939, 2.281)))) {
  warning("kaopen range differs from the readme.")
}

n_codes <- uniqueN(kaopen$code)
n_with_data <- uniqueN(kaopen[!is.na(ka_open), code])
cat(sprintf(paste0("  distinct codes: %d (expected 185); with any data: %d; ",
                   "without any data: %s\n"),
            n_codes, n_with_data,
            paste(region_map[n_years == 0, code], collapse = ", ")))
if (n_codes != 185) warning("Number of country codes is not 185.")

# Countries with data in 2023 per region. North America is USA and Canada
# only in this file (no Bermuda or Greenland), so its check is exactly
# those two; the other six regions need at least 3 countries.
n_2023 <- kaopen[year == 2023 & !is.na(ka_open), .N, by = region]
for (r in unname(wb_regions)) {
  n_r <- n_2023[region == r, N]
  if (length(n_r) == 0) n_r <- 0L
  cat(sprintf("  %s: %d countries with data in 2023\n", r, n_r))
  if (r == "north_america") {
    na_codes <- sort(kaopen[year == 2023 & !is.na(ka_open) &
                              region == r, code])
    if (!identical(na_codes, c("CAN", "USA"))) {
      warning("North America is not exactly CAN and USA in 2023.")
    }
  } else if (n_r < 3) {
    warning("Region ", r, " has fewer than 3 countries with data in 2023.")
  }
}

afg <- kaopen[code == "AFG" & year >= 2001, all(is.na(ka_open))]
cat(sprintf("  Afghanistan 2001-2023 all missing: %s (expected TRUE)\n", afg))
if (!afg) warning("Afghanistan has data after 2000.")

cat("\nCountries per region (all codes; with data in 2023; balanced panel):\n")
codes_2023 <- kaopen[year == 2023 & !is.na(ka_open), code]
print(region_map[, .(n_codes     = .N,
                     n_data_2023 = sum(code %in% codes_2023),
                     n_balanced  = sum(balanced)),
                 by = region][order(region)])
cat(sprintf("Balanced panel: %d countries with data in all %d years\n",
            length(balanced_codes), n_years_file))
