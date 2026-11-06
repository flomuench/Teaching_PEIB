# ***********************************************************
# Title: SEES0082 Political Economy of International Business, UCL SSEES:
#        course website with interactive diagrams (Teaching_PEIB)
#
# Purpose: build the world series of cross-border financial inflows by
#          investment type from the country-level IMF BOP data, with the
#          coverage diagnostics and the checks the figure relies on
#       Part 1: Read the raw files, keep economies only (no country groups)
#       Part 2: Country-year panel (wide), portfolio split, overlap checks
#       Part 3: World sums by year and the two GDP denominators
#       Part 4: Coverage diagnostics by year
#       Part 5: Validation against the IMF's own world aggregates (2005+)
#       Part 6: Checks that stop the script, then write the clean files
#
# Authors: Florian Münch
# Requires: data/imf_bop/raw/bop_country_raw.csv, bop_agg_raw.csv,
#     weo_gdp_raw.csv, bop_codelist_bop_country.csv (code/bop_import.R);
#     Part 1 of code/master.R (paths d_bop_raw, d_bop_clean; data.table)
#         ID variables: country-indicator-accounting entry-year
# Creates: in data/imf_bop/clean/ (committed):
#     bop_country_year.csv   - one row per economy and year, USD
#         ID variables: country-year
#     bop_world_year.csv     - the figure's data: USD sums, % of world GDP,
#                              % of reporters' GDP, reporter counts
#         ID variables: year
#     bop_coverage_year.csv  - coverage diagnostics
#         ID variables: year
#     bop_agg_check.csv      - country sums vs IMF world aggregates
#         ID variables: year-component
#     bop_overlap_check.csv  - predecessor/successor states, years reported
#         ID variables: pair
# ***********************************************************

# Explanatory notes:
  # Sign convention (BPM6): "net incurrence of liabilities" is positive
  # when non-residents add to their claims on the economy (an inflow) and
  # negative when they withdraw. Reserve assets are "net acquisition of
  # assets": positive = the central bank accumulates reserves. Both signs
  # are kept as reported; nothing is clipped at zero.
  # Missing = absent row in the IMF response. In the panel it is NA, and a
  # world sum is the sum over the economies that reported that year
  # (sum(..., na.rm = TRUE) with the reporter count written next to it).
  # No NA is ever replaced by 0.
  # Portfolio investment: equity (P_F5) and debt (P_F3) are stacked in the
  # figure. Where an economy reports the portfolio total (P_F) but not
  # both components, the unexplained remainder is kept in a separate
  # column portfolio_unsplit (reported in the notes, not stacked). Where
  # both components exist, total - equity - debt is a reporting
  # discrepancy (portfolio_split_gap), kept for information only.
  # World GDP: WEO "World" (G001) in current USD; the alternative
  # denominator is the GDP of the economies reporting FDI inflows that
  # year ("reporters' GDP"), which corrects for the sample growing over
  # time under the assumption that non-reporters resemble reporters.

# Safety check: stop with a clear message if master.R Part 1 has not run
if (!exists("d_bop_clean") || !exists("d_bop_raw")) {
  stop("d_bop_raw or d_bop_clean is missing. Run code/master.R (at least ",
       "Parts 1 and 2) instead of this script on its own.", call. = FALSE)
}
for (f in c("bop_country_raw.csv", "bop_agg_raw.csv", "weo_gdp_raw.csv",
            "bop_codelist_bop_country.csv")) {
  if (!file.exists(file.path(d_bop_raw, f))) {
    stop("Missing ", file.path(d_bop_raw, f), ". Run code/bop_import.R ",
         "(master Part 14) first.", call. = FALSE)
  }
}
dir.create(d_bop_clean, recursive = TRUE, showWarnings = FALSE)

# Settings of record
if (!exists("BOP_FIRST_YEAR")) BOP_FIRST_YEAR <- 1980L   # WEO GDP starts 1980
if (!exists("BOP_BASE_YEARS")) BOP_BASE_YEARS <- 2005:2015  # inflow weights
cat("Settings of record: BOP_FIRST_YEAR =", BOP_FIRST_YEAR,
    "| BOP_BASE_YEARS =", min(BOP_BASE_YEARS), "-", max(BOP_BASE_YEARS), "\n")


# ***********************************************************
# Part 1: Read the raw files, keep economies only ----
# ***********************************************************
# What: long tables with lower-case names; the BOP country dimension also
#   holds currency unions (G163 euro area, G309 ECCU) which would double
#   count their members, so only three-letter economy codes are kept.
bop_raw <- fread(file.path(d_bop_raw, "bop_country_raw.csv"))
agg_raw <- fread(file.path(d_bop_raw, "bop_agg_raw.csv"))
gdp_raw <- fread(file.path(d_bop_raw, "weo_gdp_raw.csv"))
cl_ctry <- fread(file.path(d_bop_raw, "bop_codelist_bop_country.csv"))
for (x in c("bop_raw", "agg_raw", "gdp_raw")) {
  setnames(get(x), names(get(x)), tolower(names(get(x))))
}
setnames(bop_raw, c("country", "bop_accounting_entry", "time_period",
                    "obs_value"), c("code", "entry", "year", "value"))
setnames(agg_raw, c("country", "time_period", "obs_value"),
         c("code", "year", "value"))
setnames(gdp_raw, c("country", "time_period", "obs_value"),
         c("code", "year", "gdp_usd"))
bop_raw[, year := as.integer(year)]
agg_raw[, year := as.integer(year)]
gdp_raw[, year := as.integer(year)]

# Economies = three-letter codes. Groups dropped are printed for the record.
dropped <- bop_raw[nchar(code) != 3, unique(code)]
cat("Dropped non-economy codes from the country data:",
    paste(dropped, collapse = ", "), "\n")
bop_raw <- bop_raw[nchar(code) == 3]

# Map indicator + entry to our component names (same table as the import)
comp_map <- data.table(
  indicator = c("D_F", "P_F", "P_F5", "P_F3", "F_F7", "O_F", "R_F"),
  entry     = c(rep("L_NIL_T", 6), "A_T"),
  component = c("fdi", "portfolio_total", "portfolio_equity", "portfolio_debt",
                "derivatives", "other", "reserves"))
bop_raw <- merge(bop_raw, comp_map, by = c("indicator", "entry"))
stopifnot(bop_raw[, .N, by = .(code, component, year)][N > 1, .N] == 0)

# Raw tallies used by the checks in Part 6 (nothing may get lost or filled)
raw_tally <- bop_raw[, .(n_raw = .N, n_neg_raw = sum(value < 0),
                         n_zero_raw = sum(value == 0)), by = component]


# ***********************************************************
# Part 2: Country-year panel, portfolio split, overlap checks ----
# ***********************************************************
# What: bop_country_year, one row per economy-year, one column per
#   component, NA where nothing was reported.
bop_country_year <- data.table::dcast(bop_raw, code + year ~ component,
                                      value.var = "value")
setcolorder(bop_country_year, c("code", "year", "fdi", "portfolio_total",
                                "portfolio_equity", "portfolio_debt",
                                "derivatives", "other", "reserves"))

### Portfolio split ----
# unsplit: the part of a reported total that no reported component explains
# (only when at least one component is missing); split_gap: the discrepancy
# when total and both components are reported (information only).
bop_country_year[, portfolio_unsplit := NA_real_]
bop_country_year[!is.na(portfolio_total) &
                 (is.na(portfolio_equity) | is.na(portfolio_debt)),
                 portfolio_unsplit := portfolio_total -
                   fifelse(is.na(portfolio_equity), 0, portfolio_equity) -
                   fifelse(is.na(portfolio_debt), 0, portfolio_debt)]
bop_country_year[, portfolio_split_gap := NA_real_]
bop_country_year[!is.na(portfolio_total) & !is.na(portfolio_equity) &
                 !is.na(portfolio_debt),
                 portfolio_split_gap := portfolio_total - portfolio_equity -
                   portfolio_debt]
cat("\nPortfolio split (country-years with a reported total):\n")
print(bop_country_year[!is.na(portfolio_total),
                       .(both_components = sum(!is.na(portfolio_equity) &
                                                 !is.na(portfolio_debt)),
                         one_component   = sum(xor(is.na(portfolio_equity),
                                                   is.na(portfolio_debt))),
                         no_component    = sum(is.na(portfolio_equity) &
                                                 is.na(portfolio_debt)))])
cat("Largest split discrepancies (total - equity - debt), USD bn:\n")
print(head(bop_country_year[abs(portfolio_split_gap) > 1e8][
  order(-abs(portfolio_split_gap)),
  .(code, year, portfolio_total = round(portfolio_total / 1e9, 2),
    portfolio_equity = round(portfolio_equity / 1e9, 2),
    portfolio_debt = round(portfolio_debt / 1e9, 2),
    gap = round(portfolio_split_gap / 1e9, 2))], 5))

### Names and GDP ----
bop_country_year <- merge(bop_country_year, cl_ctry[, .(code, name)],
                          by = "code", all.x = TRUE)
bop_country_year <- merge(bop_country_year,
                          gdp_raw[nchar(code) == 3, .(code, year, gdp_usd)],
                          by = c("code", "year"), all.x = TRUE)
setorder(bop_country_year, code, year)

### Correction (2026-11-05): combined and separate reporters in one year ----
# The IMF list carries "Curaçao and Sint Maarten" (CWX, the former
# Netherlands Antilles currency area) next to Curaçao (CUW) and Sint
# Maarten (SXM). All three report for 2011-2023, so a plain sum counts the
# two islands twice. Rule: in a year where any constituent reports, the
# combined code is dropped; in years with the combined code only (2024-25)
# it stays, so the territory is counted exactly once in every year.
combined <- list(CWX = c("CUW", "SXM"))
for (cc in names(combined)) {
  yrs_const <- bop_country_year[code %in% combined[[cc]], unique(year)]
  n_drop <- bop_country_year[code == cc & year %in% yrs_const, .N]
  bop_country_year <- bop_country_year[!(code == cc & year %in% yrs_const)]
  cat("Dropped", n_drop, "rows of", cc, "in years where",
      paste(combined[[cc]], collapse = "/"), "report\n")
}
# The raw tallies (Part 1) must shrink by the same rows, so the Part 6
# check "nothing lost, nothing filled" still holds.
dropped_tally <- bop_raw[code %in% names(combined) &
                         year %in% bop_country_year[code %in% unlist(combined),
                                                    unique(year)],
                         .(n_drop = .N, n_neg_drop = sum(value < 0)), by = component]
raw_tally <- merge(raw_tally, dropped_tally, by = "component", all.x = TRUE)
raw_tally[is.na(n_drop), `:=`(n_drop = 0L, n_neg_drop = 0L)]
raw_tally[, `:=`(n_raw = n_raw - n_drop, n_neg_raw = n_neg_raw - n_neg_drop)]

### Predecessor / successor states: no year may count both ----
# Pairs present in the IMF country list (checked by code, not by hand):
# a predecessor reporting in the same year as a successor would double
# count that territory.
pairs <- data.table(
  pred = c("CSK", "CSK", "YUG", "YUG", "YUG", "YUG", "YUG", "YUG", "YUG", "YUG",
           "YAR", "YMD", "ANT", "ANT", "ANT", "CWX", "CWX", "SUN", "DDR",
           "SCG", "SCG"),
  succ = c("CZE", "SVK", "HRV", "SVN", "BIH", "MKD", "SRB", "MNE", "KOS", "UVK",
           "YEM", "YEM", "CUW", "SXM", "CWX", "CUW", "SXM", "RUS", "DEU",
           "SRB", "MNE"))
yrs <- bop_country_year[!is.na(fdi) | !is.na(other) | !is.na(portfolio_total),
                        .(first = min(year), last = max(year),
                          years = list(year)), by = code]
bop_overlap_check <- pairs[pred %in% yrs$code & succ %in% yrs$code]
bop_overlap_check[, `:=`(
  pred_first = yrs[match(pred, code), first], pred_last = yrs[match(pred, code), last],
  succ_first = yrs[match(succ, code), first], succ_last = yrs[match(succ, code), last])]
bop_overlap_check[, overlap_years := mapply(function(a, b) {
  length(intersect(yrs[code == a, years][[1]], yrs[code == b, years][[1]]))
}, pred, succ)]
cat("\nPredecessor/successor states present in the data:\n")
print(bop_overlap_check)
if (any(bop_overlap_check$overlap_years > 0)) {
  stop("A predecessor state and a successor state report in the same year ",
       "(see the table above): fix the double counting before aggregating.",
       call. = FALSE)
}


# ***********************************************************
# Part 3: World sums by year and the two GDP denominators ----
# ***********************************************************
# What: bop_world_year with, per component, the USD sum over reporters and
#   the number of reporters; gross inflows = the five stacked components;
#   % of world GDP (WEO World) and % of reporters' GDP.
comps <- c("fdi", "portfolio_equity", "portfolio_debt", "derivatives", "other",
           "portfolio_total", "portfolio_unsplit", "reserves")
last_year <- bop_country_year[, max(year)]
world <- bop_country_year[year >= BOP_FIRST_YEAR & year <= last_year]
bop_world_year <- world[, c(
  lapply(.SD, function(v) sum(v, na.rm = TRUE)),
  setNames(lapply(.SD, function(v) sum(!is.na(v))), paste0("n_", comps))),
  by = year, .SDcols = comps]
setnames(bop_world_year, comps, paste0(comps, "_usd"))
# The stacked total and the total including the unsplit portfolio remainder
bop_world_year[, gross_inflows_usd := fdi_usd + portfolio_equity_usd +
                 portfolio_debt_usd + derivatives_usd + other_usd]
bop_world_year[, gross_inflows_incl_unsplit_usd := gross_inflows_usd +
                 portfolio_unsplit_usd]

### Denominators ----
world_gdp <- gdp_raw[code == "G001", .(year, world_gdp_usd = gdp_usd)]
rep_gdp <- world[!is.na(fdi), .(reporter_gdp_usd = sum(gdp_usd, na.rm = TRUE),
                                n_reporters_no_gdp = sum(is.na(gdp_usd))),
                 by = year]
bop_world_year <- merge(bop_world_year, world_gdp, by = "year", all.x = TRUE)
bop_world_year <- merge(bop_world_year, rep_gdp, by = "year", all.x = TRUE)
if (anyNA(bop_world_year$world_gdp_usd)) {
  stop("World GDP (WEO G001) missing for some years of the BOP data.",
       call. = FALSE)
}
pct_cols <- c("fdi", "portfolio_equity", "portfolio_debt", "derivatives",
              "other", "portfolio_unsplit", "gross_inflows",
              "gross_inflows_incl_unsplit", "reserves")
for (v in pct_cols) {
  bop_world_year[, (paste0(v, "_pct_world_gdp")) :=
                   100 * get(paste0(v, "_usd")) / world_gdp_usd]
  bop_world_year[, (paste0(v, "_pct_reporter_gdp")) :=
                   100 * get(paste0(v, "_usd")) / reporter_gdp_usd]
}
setorder(bop_world_year, year)


# ***********************************************************
# Part 4: Coverage diagnostics by year ----
# ***********************************************************
# What: how much of the world the reporting sample represents each year,
#   measured three ways: reporters, their share of world GDP, and their
#   share of a base-period inflow volume (financial centres have little
#   GDP but large inflows, so GDP alone understates their absence).
# How: the inflow weight of an economy is its mean absolute gross inflows
#   over BOP_BASE_YEARS (|FDI| + |equity| + |debt| + |derivatives| +
#   |other| over the components it reported). Economies without base-year
#   data (e.g. dissolved states) get weight 0.
stack5 <- c("fdi", "portfolio_equity", "portfolio_debt", "derivatives", "other")
base <- bop_country_year[year %in% BOP_BASE_YEARS]
base[, n_rep := rowSums(!is.na(.SD)), .SDcols = stack5]
base[, abs_inflow := rowSums(abs(.SD), na.rm = TRUE), .SDcols = stack5]
base[n_rep == 0, abs_inflow := NA_real_]   # nothing reported: no weight info
weights <- base[, .(w = mean(abs_inflow, na.rm = TRUE)), by = code]
weights[is.nan(w), w := 0]
w_total <- sum(weights$w)

cov <- world[, .(code, year, reports = !is.na(fdi), gdp_usd)]
cov <- merge(cov, weights, by = "code", all.x = TRUE)
cov[is.na(w), w := 0]
# Economies with GDP in WEO but no BOP report at all that year
all_gdp <- gdp_raw[nchar(code) == 3 & year >= BOP_FIRST_YEAR & year <= last_year,
                   .(code, year, gdp_usd)]
all_gdp <- merge(all_gdp, cov[reports == TRUE, .(code, year, reports)],
                 by = c("code", "year"), all.x = TRUE)
all_gdp[is.na(reports), reports := FALSE]
missing_top <- all_gdp[reports == FALSE][order(year, -gdp_usd)][,
  .(largest_non_reporters = paste(head(code, 5), collapse = " ")), by = year]

bop_coverage_year <- merge(
  cov[reports == TRUE, .(n_reporters = .N,
                         inflow_weight_coverage_pct = 100 * sum(w) / w_total),
      by = year],
  bop_world_year[, .(year, world_gdp_usd, reporter_gdp_usd, n_reporters_no_gdp,
                     gdp_coverage_pct = 100 * reporter_gdp_usd / world_gdp_usd)],
  by = "year")
bop_coverage_year <- merge(bop_coverage_year, missing_top, by = "year", all.x = TRUE)
# Share of last year's absolute inflows from economies that stopped
# reporting this year (tells how incomplete the latest year is)
prev <- world[!is.na(fdi), .(code, year = year + 1L, prev_reported = TRUE)]
prev <- merge(prev, world[, .(code, year, now_reported = !is.na(fdi))],
              by = c("code", "year"), all.x = TRUE)
prev[is.na(now_reported), now_reported := FALSE]
prev_abs <- world[, .(code, year = year + 1L,
                      prev_abs = rowSums(abs(.SD), na.rm = TRUE)),
                  .SDcols = stack5]
prev <- merge(prev, prev_abs, by = c("code", "year"))
lost <- prev[, .(dropped_reporters = sum(!now_reported),
                 dropped_prev_year_inflow_share_pct =
                   100 * sum(prev_abs[!now_reported]) / sum(prev_abs)), by = year]
bop_coverage_year <- merge(bop_coverage_year, lost, by = "year", all.x = TRUE)
setorder(bop_coverage_year, year)
cat("\nCoverage by year (selected):\n")
print(bop_coverage_year[year %in% c(1980, 1985, 1990, 1995, 1996, 2000, 2005,
                                    2010, 2020, 2024, 2025),
                        .(year, n_reporters, gdp_coverage_pct = round(gdp_coverage_pct, 1),
                          inflow_weight_coverage_pct = round(inflow_weight_coverage_pct, 1),
                          dropped_prev_year_inflow_share_pct =
                            round(dropped_prev_year_inflow_share_pct, 1),
                          largest_non_reporters)])


# ***********************************************************
# Part 5: Validation against the IMF's own world aggregates ----
# ***********************************************************
# What: country sums vs BOP_AGG "All Countries and International
#   Organizations" (GX010), 2005 onwards, per component. The IMF aggregate
#   includes its own estimates and "adjusted" other-investment and reserve
#   series, so ratios near 1 (not exactly 1) are expected.
agg_map <- data.table(
  component = c("fdi", "portfolio_total", "derivatives", "other", "reserves"),
  indicator = c("D_NIL_L", "P_NIL_L", "F7_NIL_L", "O_NIL_L_AFR", "R_A_AFR"))
agg_w <- merge(agg_raw[code == "GX010", .(indicator, year, imf_agg_usd = value)],
               agg_map, by = "indicator")
sums <- data.table::melt(bop_world_year[, .(year, fdi = fdi_usd,
                                            portfolio_total = portfolio_total_usd,
                                            derivatives = derivatives_usd,
                                            other = other_usd,
                                            reserves = reserves_usd)],
                         id.vars = "year", variable.name = "component",
                         value.name = "country_sum_usd")
sums[, component := as.character(component)]
bop_agg_check <- merge(sums, agg_w[, .(year, component, imf_agg_usd)],
                       by = c("year", "component"))
bop_agg_check[, `:=`(diff_usd_bn = (country_sum_usd - imf_agg_usd) / 1e9,
                     ratio = country_sum_usd / imf_agg_usd)]
setorder(bop_agg_check, component, year)
cat("\nCountry sums / IMF world aggregate (GX010), median and range by component:\n")
print(bop_agg_check[, .(median_ratio = round(median(ratio), 3),
                        min_ratio = round(min(ratio), 3),
                        max_ratio = round(max(ratio), 3),
                        median_abs_diff_bn = round(median(abs(diff_usd_bn)), 1)),
                    by = component])
# Carry the IMF aggregates into the world table for the csv
agg_wide <- data.table::dcast(agg_w, year ~ component, value.var = "imf_agg_usd")
setnames(agg_wide, setdiff(names(agg_wide), "year"),
         paste0("imf_agg_", setdiff(names(agg_wide), "year"), "_usd"))
bop_world_year <- merge(bop_world_year, agg_wide, by = "year", all.x = TRUE)


# ***********************************************************
# Part 6: Checks that stop the script, then write ----
# ***********************************************************
# What: the invariants the figure relies on. Each failure is a stop(),
#   never a warning.
checks <- list()
# 6.1 Nothing lost, nothing filled: non-NA cells per component = raw rows
tally <- bop_country_year[, lapply(.SD, function(v) sum(!is.na(v))),
                          .SDcols = comp_map$component]
tally <- data.table::melt(tally, measure.vars = comp_map$component,
                          variable.name = "component", value.name = "n_panel")
tally[, component := as.character(component)]
tally <- merge(tally, raw_tally, by = "component")
checks$no_fill <- all(tally$n_panel == tally$n_raw)
# 6.2 Negative observations preserved
neg <- bop_country_year[, lapply(.SD, function(v) sum(v < 0, na.rm = TRUE)),
                        .SDcols = comp_map$component]
neg <- data.table::melt(neg, measure.vars = comp_map$component,
                        variable.name = "component", value.name = "n_neg_panel")
neg[, component := as.character(component)]
tally <- merge(tally, neg, by = "component")
checks$negatives_kept <- all(tally$n_neg_panel == tally$n_neg_raw)
# 6.3 Stacked total = sum of the five components (no double counting of
#     portfolio total, components and unsplit remainder)
checks$stack_identity <- bop_world_year[, all(abs(
  gross_inflows_usd - (fdi_usd + portfolio_equity_usd + portfolio_debt_usd +
                         derivatives_usd + other_usd)) < 1)]
#     Portfolio: for every economy-year with a reported total, the total
#     equals equity + debt + unsplit remainder + split discrepancy
pf <- world[!is.na(portfolio_total), .(
  total = sum(portfolio_total),
  parts = sum(fifelse(is.na(portfolio_equity), 0, portfolio_equity) +
                fifelse(is.na(portfolio_debt), 0, portfolio_debt) +
                fifelse(is.na(portfolio_unsplit), 0, portfolio_unsplit) +
                fifelse(is.na(portfolio_split_gap), 0, portfolio_split_gap))),
  by = year]
checks$portfolio_identity <- pf[, all(abs(total - parts) < 1)]
# 6.4 Every year present once
checks$years_complete <- identical(bop_world_year$year,
                                   BOP_FIRST_YEAR:last_year)
# 6.5 Units anchor: China's reserve accumulation in 2007 was 460.7 bn USD
chn07 <- bop_country_year[code == "CHN" & year == 2007, reserves]
checks$units_anchor <- length(chn07) == 1 && chn07 > 455e9 && chn07 < 466e9
# 6.6 No economy counted twice in a year
checks$unique_rows <- bop_country_year[, .N, by = .(code, year)][N > 1, .N] == 0
# 6.7 IMF aggregate comparison: FDI and portfolio within 15% every year
checks$agg_close <- bop_agg_check[component %in% c("fdi", "portfolio_total"),
                                  all(ratio > 0.85 & ratio < 1.15)]
cat("\nChecks:\n"); print(unlist(checks))
if (!all(unlist(checks))) {
  print(tally)
  stop("At least one check failed (see above). The clean files were NOT ",
       "written.", call. = FALSE)
}

### Write ----
setcolorder(bop_country_year, c("code", "name", "year"))
fwrite(bop_country_year, file.path(d_bop_clean, "bop_country_year.csv"))
fwrite(bop_world_year,   file.path(d_bop_clean, "bop_world_year.csv"))
fwrite(bop_coverage_year, file.path(d_bop_clean, "bop_coverage_year.csv"))
fwrite(bop_agg_check,    file.path(d_bop_clean, "bop_agg_check.csv"))
fwrite(bop_overlap_check[, .(pred, succ, pred_first, pred_last, succ_first,
                             succ_last, overlap_years)],
       file.path(d_bop_clean, "bop_overlap_check.csv"))
cat("\nWritten to", d_bop_clean, ":\n  bop_country_year.csv (",
    nrow(bop_country_year), "rows )\n  bop_world_year.csv (",
    nrow(bop_world_year), "rows,", BOP_FIRST_YEAR, "-", last_year,
    ")\n  bop_coverage_year.csv, bop_agg_check.csv, bop_overlap_check.csv\n")
cat("\nWorld gross inflows, % of world GDP (selected years):\n")
print(bop_world_year[year %in% c(1980, 1990, 2000, 2007, 2008, 2015, 2020, 2024, 2025),
                     .(year, fdi = round(fdi_pct_world_gdp, 2),
                       pf_equity = round(portfolio_equity_pct_world_gdp, 2),
                       pf_debt = round(portfolio_debt_pct_world_gdp, 2),
                       deriv = round(derivatives_pct_world_gdp, 2),
                       other = round(other_pct_world_gdp, 2),
                       total = round(gross_inflows_pct_world_gdp, 2),
                       reserves = round(reserves_pct_world_gdp, 2),
                       n = n_fdi)])
rm(bop_raw, agg_raw, gdp_raw, cl_ctry, dropped, comp_map, raw_tally, pairs, yrs,
   comps, world, world_gdp, rep_gdp, pct_cols, base, weights, w_total, cov,
   all_gdp, missing_top, prev, lost, agg_map, agg_w, sums, agg_wide, checks,
   tally, neg, pf, chn07, last_year, combined, cc, yrs_const, n_drop,
   dropped_tally, stack5, prev_abs, x, v, f)
