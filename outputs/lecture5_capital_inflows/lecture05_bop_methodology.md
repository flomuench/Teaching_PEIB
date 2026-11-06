# Global cross-border financial inflows by investment type, 1980-2025: methodology notes

Built on 05 November 2026 by `code/lecture05_bop_figures.R` (Teaching_PEIB, master Part 14) from IMF data downloaded on 2026-11-05 11:14 GMT.

## 1. What the figure shows

Annual gross cross-border financial inflows into all reporting economies, measured as the net incurrence of liabilities to non-residents (BPM6 financial account), summed over economies and expressed as a percentage of world GDP in current US dollars. The stack distinguishes foreign direct investment, portfolio equity, portfolio debt, other investment (mainly bank loans, deposits and trade credit) and financial derivatives. Reserve-asset accumulation (net acquisition of reserve assets by central banks) belongs to the asset side of the financial account and is drawn as a separate dashed line, not stacked. The thin black line is the total of the five stacked components.

Headline numbers: gross inflows rose from 3.5% of world GDP in 1980 to a peak of 21.1% in 2007 (USD 12,452 billion), collapsed to 2.2% in 2009, and stood at 5.0% in 2024 (2025 preliminary: 8.0%). Reserve accumulation peaked at 2.0% of world GDP in 2007.

## 2. Data sources (all IMF, SDMX 3.0 API, R package imf.data)

- API base URL: https://api.imf.org/external/sdmx/3.0; R package: imf.data 0.2.0.
- `IMF.STA/BOP` version 21.0.0, Balance of Payments (country data, BPM6 presentation): the series behind the figure.
- `IMF.STA/BOP_AGG` version 9.0.1, BOP/IIP World and Country Group Aggregates: used only to validate the country sums (world total GX010 "All Countries and International Organizations", available 2005-2024).
- `IMF.RES/WEO` version 9.0.0, World Economic Outlook: nominal GDP in US dollars (indicator NGDPD) for the world (G001) and every economy, 1980 onwards.

All codes were discovered from the IMF code lists (dimension values of each dataflow) and are re-verified by name on every run of `code/bop_import.R`; a mismatch stops the pipeline.

| Component | BOP indicator | Indicator name in the IMF code list | Accounting entry |
|---|---|---|---|
| fdi | `D_F` | Direct investment, Total financial assets/liabilities | `L_NIL_T` (Liabilities, Net incurrence of liabilities) |
| portfolio_total | `P_F` | Portfolio investment, Total financial assets/liabilities | `L_NIL_T` (Liabilities, Net incurrence of liabilities) |
| portfolio_equity | `P_F5` | Portfolio investment, Equity and investment fund shares | `L_NIL_T` (Liabilities, Net incurrence of liabilities) |
| portfolio_debt | `P_F3` | Portfolio investment, Debt securities | `L_NIL_T` (Liabilities, Net incurrence of liabilities) |
| derivatives | `F_F7` | Financial derivatives (other than reserves) and employee stock options | `L_NIL_T` (Liabilities, Net incurrence of liabilities) |
| other | `O_F` | Other investment, Total financial assets/liabilities | `L_NIL_T` (Liabilities, Net incurrence of liabilities) |
| reserves | `R_F` | Reserve assets, Total financial /liabilities | `A_T` (Assets) |

Unit: US dollars, annual. The API's SCALE attribute reads 6 (millions) but the returned values are plain dollars; this was anchored on China's 2007 reserve accumulation (460.7 billion USD) and world GDP 2024 (111.9 trillion USD), and the anchor is one of the checks in `code/bop_clean.R`.

## 3. Construction

- Economies only: the BOP country dimension also contains the euro area (G163) and the Eastern Caribbean Currency Union (G309); both are dropped because they would double count their members.
- Curaçao and Sint Maarten: the IMF list carries the combined code CWX next to CUW and SXM, all reporting 2011-2023. The combined code is dropped in every year where a constituent reports and kept where it is the only reporter (2024-2025), so the territory is counted once. A general predecessor/successor check (Czechoslovakia, Yugoslavia, Netherlands Antilles, the two Yemens, the USSR, the GDR, Serbia and Montenegro) finds no other overlap; see `data/imf_bop/clean/bop_overlap_check.csv`.
- Missing values: the API returns a row only where an observation exists. A missing economy-year stays NA in the panel and is simply absent from the world sum (the number of reporters per component and year is written next to every sum). No NA is replaced by zero; negative observations are kept (they are net repayments or withdrawals).
- Portfolio split: equity (P_F5) and debt (P_F3) are stacked. Where an economy reports only the portfolio total (P_F) or one component, the unexplained remainder is kept in `portfolio_unsplit` and is not stacked (0.1% of the absolute gross flows over 1980-2025; at most 0.13% of world GDP in any year). Where total, equity and debt are all reported, total minus the components is a reporting discrepancy kept for information (`portfolio_split_gap`); the only material case is Bahrain 2024, where the IMF file repeats the total as both equity and debt (USD 3.4 billion, 0.003% of world GDP), left as reported.
- No double counting: the stack uses the five mutually exclusive components; the portfolio total, the unsplit remainder and the IMF aggregates are carried in the csv for reference only.
- Denominators: world GDP is the WEO "World" series. The csv also gives every series in percent of the GDP of the economies reporting FDI inflows that year (`*_pct_reporter_gdp`), which corrects for the growing sample if non-reporters are assumed to resemble reporters. The figure uses world GDP as requested.

## 4. Coverage, and whether 1980-2025 is feasible

The IMF's own world aggregates (BOP_AGG) start in 2005 and do not split portfolio investment, so the long series has to be built from country data. Country data in the BPM6 presentation reach back to 1948 for a few economies and cover 119 reporters in 1980. The binding constraint is Japan, whose BPM6 series start in 1996 (no earlier data in any presentation on the API); Belgium and Luxembourg report from 2002 and 2002, Austria and Ireland from 2005 and 2005, Switzerland from 1983, Australia from 1989, Hong Kong SAR from 1998, Taiwan Province of China never (not an IMF member) and Iran last in 2000. Reporting economies therefore cover 77-84% of world GDP in 1980-1995 and 95-99% from 1996. Because financial centres have small GDP but large flows, the csv also reports an inflow-weighted coverage (share of 2005-2015 average absolute gross inflows accounted for by the economies reporting in a given year; base years = BOP_BASE_YEARS in code/bop_clean.R): 64% in 1980, 82% in 1996, 100% in 2005.

Verdict: 1980-2025 is feasible as a reporter sum, and the figure shows it, but 1980-1995 is a partial-coverage segment (shaded in the figure) and 1996-2004 still lacks Belgium, Luxembourg, Austria and Ireland, all large portfolio and FDI conduits. The series with defensible world coverage is 1996-2025 (variant `lecture05_bop_inflows_from1996`), and the IMF-consistent segment is 2005 onwards. The level in the early years is a lower bound for the world; the ratio to reporters' GDP (in the csv) is the better like-for-like comparison across the 1995/1996 break.

2025 is preliminary: 159 economies had reported annual data at download, and the economies that reported in 2024 but not yet in 2025 accounted for 0.5% of 2024's absolute gross inflows.

| Year | Reporters | GDP coverage (% of world GDP) | Inflow-weighted coverage (%) | Largest non-reporters (by GDP) |
|---|---|---|---|---|
| 1980 | 119 | 78.6 | 64.4 | JPN CHN AUS CHE BEL |
| 1985 | 130 | 83.5 | 71.0 | JPN AUS BEL AUT TWN |
| 1990 | 132 | 81.8 | 73.0 | JPN BEL TWN AUT HKG |
| 1995 | 142 | 77.5 | 75.6 | JPN BEL TWN AUT HKG |
| 1996 | 145 | 95.5 | 81.8 | TWN BEL AUT HKG IRL |
| 2000 | 148 | 96.2 | 84.6 | TWN BEL AUT ARE IRL |
| 2005 | 176 | 97.8 | 99.7 | TWN IRN ARE PRI QAT |
| 2010 | 185 | 97.5 | 99.8 | IRN TWN ARE QAT PRI |
| 2015 | 190 | 97.9 | 100.0 | TWN IRN ARE PRI TKM |
| 2020 | 185 | 98.2 | 99.9 | TWN ARE IRN PRI MMR |
| 2024 | 175 | 98.4 | 99.8 | TWN IRN PRI MMR TKM |
| 2025 | 159 | 98.0 | 99.2 | TWN IRN PRI ETH CIV |

## 5. Validation against the IMF world aggregates (2005-2024)

Ratio of the country sums to the IMF's world aggregate (GX010), per component and year (`data/imf_bop/clean/bop_agg_check.csv`). The IMF aggregate includes IMF estimates for late reporters and uses series "adjusted using IMF accounting records" for other investment and reserves, so ratios near but not exactly 1 are expected; ratios far from 1 for derivatives and other investment occur in years when the world total is close to zero and the ratio is not informative (the median absolute difference in USD billion is the better gauge).

| Component | Median ratio | Min | Max | Median abs. difference (USD bn) |
|---|---|---|---|---|
| derivatives | 1.012 | 0.528 | 1.857 | 32.8 |
| fdi | 0.995 | 0.907 | 1.038 | 14.6 |
| other | 0.985 | -3.253 | 1.031 | 43.8 |
| portfolio_total | 0.999 | 0.990 | 1.056 | 15.9 |
| reserves | 0.952 | 0.854 | 1.262 | 27.4 |

## 6. Checks run by the pipeline (each stops the build when it fails)

1. Every IMF code used matches its name in the current IMF code list.
2. Nothing lost, nothing filled: the number of non-missing cells per component equals the number of rows the API returned (after the CWX correction).
3. Negative observations preserved: the count of negative cells equals the raw count.
4. Stack identity: the total equals the sum of the five components in every year.
5. Portfolio identity: total = equity + debt + unsplit remainder + split discrepancy in every year.
6. All years present once; no economy counted twice in a year; no predecessor/successor overlap.
7. Units anchor (China 2007 reserves between 455 and 466 billion USD).
8. FDI and portfolio country sums within 15% of the IMF world aggregate in every year 2005 onwards.

## 7. Known limitations and unresolved coverage issues

- Japan before 1996, Belgium and Luxembourg before 2002, Austria and Ireland before 2005: the largest gaps; no IMF source on the SDMX 3.0 API fills them (the BPM5-era IFS presentation is not available there).
- Taiwan Province of China is never included (not an IMF member); Iran's last reported year is 2000.
- Reporter counts in the figure caption and the csv refer to economies reporting FDI inflows; fewer economies report financial derivatives (see the `n_*` columns in the csv), so the derivatives layer covers a smaller sample.
- Financial-centre flows (Luxembourg, Ireland, Netherlands, Cayman Islands, Hong Kong SAR, Singapore) are gross cross-border positions of pass-through entities and inflate world totals relative to "real" financing; the figure does not net them out.
- The IMF revises BOP data monthly; a fresh download (set `BOP_FORCE_DOWNLOAD <- TRUE` in the master) changes the numbers. The download date and dataflow versions are in `data/imf_bop/raw/bop_metadata.json`.
- 2025 is preliminary (see section 4). World GDP for 2025 is the WEO estimate of the vintage downloaded.
- The Bahrain 2024 portfolio duplicate (section 3) is left as reported.

## 8. Files

- `outputs/lecture5_capital_inflows/lecture05_bop_inflows.png` (300 dpi), `.pdf`, `.svg`: the main figure, 1980-2025, 11 x 5.8 in, white background, Segoe UI.
- `outputs/lecture5_capital_inflows/lecture05_bop_inflows_from1996.png/.pdf/.svg`: the variant starting in 1996.
- `outputs/lecture5_capital_inflows/lecture05_bop_inflows.pptx`: three slides (editable vector graphic, PNG, 1996 variant), built on the course template.
- `outputs/lecture5_capital_inflows/lecture05_bop_inflows_data.csv`: the figure data by year (USD billion, % of world GDP, % of reporters' GDP, reporter counts, coverage).
- `outputs/lecture5_capital_inflows/lecture05_bop_headline_numbers.csv`: numbers for the slide text.
- `data/imf_bop/clean/bop_country_year.csv`: the economy-year panel (USD) behind the sums; `bop_world_year.csv`, `bop_coverage_year.csv`, `bop_agg_check.csv`, `bop_overlap_check.csv`.
- Code: `code/bop_import.R`, `code/bop_clean.R`, `code/lecture05_bop_figures.R`, run from `code/master.R` Part 14.

