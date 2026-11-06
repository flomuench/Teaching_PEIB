# CLAUDE.md - Teaching_PEIB (course website with interactive diagrams)

Project context for Claude sessions working in this repository.

## 1. What this repo is

The public course website for **SEES0082 Political Economy of International Business** (UCL SSEES, Master's level, ~100 students, mostly without an economics background), taught by Florian Münch from Autumn Term 2026/27.

- Live site: https://flomuench.github.io/Teaching_PEIB/
- Built with **Quarto** (website) + **R Shiny apps running in the student's browser via shinylive** (webR), deployed to **GitHub Pages** by GitHub Actions on every push to `main`.
- Content is added week by week: each tutorial gets a page with a short plain-language explanation, a static figure, an interactive diagram with sliders, and "Things to try" prompts.
- The same R code also produces static PNGs that Florian inserts into his Word tutorial handouts.

Course materials (lectures, handouts, assessment) live elsewhere, on the UCL Drive shared with co-teacher Irakli: `C:\Users\flori\OneDrive - University College London\UCL teaching\Political Economy of International Business` (working folder `PEIB_Florian_Irakli\`). The older personal OneDrive copy (`C:\Users\flori\OneDrive\Documents\Teaching\...`) is outdated. Claude's outputs (feedback documents, drafts, tables) go into `Claude outputs\Week<N>\Lecture\` or `\Tutorial\` in that folder; figures for the website stay in this repo under `figures/tutorialN/`.

## 2. Use the skill

**Always load the `r-shinylive-teaching-site` skill before working in this repo**, in particular before adding a diagram or page, changing `code/functions_models.R`, editing the workflow, or debugging a failed build. It holds the architecture rationale, page and app templates, design rules for the diagrams, testing steps for the Cowork sandbox, and the list of gotchas that have already cost debugging time. This repo is the skill's reference implementation: copy the existing patterns rather than inventing new ones.

## 3. File map

- `_quarto.yml` - website settings, navbar (add each new tutorial page to the "Tutorials" menu), `filters: [shinylive]`.
- `index.qmd` - home page (keep its list of tutorials up to date).
- `tutorials/tutorialNN_<topic>.qmd` - one page per tutorial, at most two apps per page (each app loads its own R engine in the browser). Template: `tutorials/tutorial01_market.qmd`: one "stepper" app (the explorer: a figure drop-down, sliders shown per figure via `conditionalPanel`, an outcome table) covering all handout figures, then the static PNGs with short key text.
- `code/master.R` - runs all R steps (open `Teaching_PEIB.Rproj`, open `code/master.R`, Source). Part 1 settings (root folder via USERPROFILE, else the working directory, checked for `_quarto.yml`; paths `c_code`, `d_tut`, `o_fig`, `o_fig_t1`, `d_site`; `pacman::p_load(shiny, shinylive)`), Part 2 sources `functions_models.R`, Part 3 Tutorial 1 figures (on), Parts 4-12 Tutorials 2-10 `tutorialNN_figures.R` (4-7 on, 8-12 off until the scripts exist), Part 13 Lecture 5 data figures (on: `kaopen_import.R`, `kaopen_clean.R`, `lecture05_kaopen_figures.R`; paths `d_data`, `d_kaopen_raw`, `d_kaopen_clean`, `o_fig_l5`), Part 14 Lecture 5 IMF capital inflows figure (on: `bop_import.R`, `bop_clean.R`, `lecture05_bop_figures.R`; paths `d_bop_raw`, `d_bop_clean`, `o_out_l5`, `f_pptx_template`; flag `BOP_FORCE_DOWNLOAD`), Part 15 `website_build.R` (off), Part 16 `app_test.R` (off), Part 17 `sessionInfo()`.
- `code/functions_models.R` - ALL model and plotting functions for the tutorial diagrams (base R only). Used by the apps (bundled via the include shortcode) and by the figure scripts.
- `code/functions_lecture.R` - `theme_lecture()` and `save_lecture_fig()` (ggplot2, PNG via ragg + PDF via cairo_pdf) for lecture data figures; sourced in master Part 2, never bundled into apps.
- `code/kaopen_import.R`, `code/kaopen_clean.R`, `code/lecture05_kaopen_figures.R` - Chinn-Ito financial openness index (2023 update): download (cached in `data/kaopen/raw/`, gitignored), the seven World Bank regions (via `countrycode(code, "iso3c", "region")`; code fixes in a dated block in `kaopen_clean.R` Part 2) and region-year unweighted means (`data/kaopen/clean/`, committed), Lecture 5 figures and headline numbers csv in `figures/lecture5/`.
- `code/bop_import.R`, `code/bop_clean.R`, `code/lecture05_bop_figures.R` - IMF balance of payments data via the SDMX 3.0 API (`imf.data`): global cross-border financial inflows by type (FDI, portfolio equity, portfolio debt, other investment, derivatives = net incurrence of liabilities) and reserve accumulation, summed over reporting economies, % of world GDP, 1980-2025. Import verifies every IMF code by name against the code lists and caches the downloads in `data/imf_bop/raw/` (gitignored; `BOP_FORCE_DOWNLOAD <- TRUE` refreshes); clean builds the economy-year panel and world sums with checks that stop on failure (no NA filled, negatives kept, no double counting, units anchor, IMF-aggregate comparison) into `data/imf_bop/clean/` (committed); the figure script writes PNG/PDF/SVG, a 3-slide PPTX (course template, editable vector graphic via `rvg`), the figure csv, headline numbers and methodology notes into `outputs/lecture5_capital_inflows/`. Coverage caveat: Japan reports from 1996 only, so 1980-1995 is shaded as partial coverage; a `_from1996` variant exists.
- `code/tutorial01_figures.R` - writes the Tutorial 1 PNGs (300 dpi) to `figures/tutorial1/` and prints the answer key numbers. Uses `o_fig_t1` and the functions from master Parts 1-2; never sets the working directory itself.
- `code/website_build.R` - checks every page (`engine: markdown` on app pages, `figures/` links, include paths and `## file:`/`source()` names in app chunks), then `quarto render` into `_site/` (optional `quarto preview`). Env var `QUARTO_PATH` selects a specific Quarto. During the render it puts this R session's `bin` folder first on the PATH (restored afterwards), because the shinylive extension calls plain `Rscript`, which is often not on the Windows PATH.
- `code/app_test.R` - copies one page's app (app.R + included files) into a temp folder and runs it with `shiny::runApp()`.
- `figures/tutorialN/` - committed PNGs, one subfolder per tutorial (`figures/tutorial1/`, `figures/tutorial2/`, ...: no leading zero in the folder name, while file names keep `tutorial01_...`). Pages link them as `../figures/tutorialN/<file>.png`; master.R Part 1 defines one path per tutorial (`o_fig_t1`, later `o_fig_t2`, ...). Shown above each app and used in Word handouts.
- `figures/lectureN/` - lecture data figures (PNG 300 dpi and PDF, 10 x 5.6 in, no titles), e.g. `figures/lecture5/` (path `o_fig_l5`). The PDFs change bytes on every run (embedded creation date), so commit them only after a data or code change; the PNGs are byte-stable.
- `data/` - data for lecture figures, one folder per source (`data/kaopen/raw/` and `data/imf_bop/raw/` gitignored and re-downloaded, `data/kaopen/clean/` and `data/imf_bop/clean/` committed).
- `outputs/` - slide-ready deliverables that are not website figures (currently `outputs/lecture5_capital_inflows/`, master Part 14). Not rendered as site pages (`_quarto.yml` renders only `index.qmd` and `tutorials/*.qmd`).
- `_extensions/quarto-ext/shinylive/` - vendored Quarto extension (v0.2.0). Do not edit.
- `.github/workflows/publish.yml` - render and deploy to GitHub Pages.
- `README.md` - Florian's own how-to (daily workflow, troubleshooting).

## 4. Rules that must not be broken

- Every page containing a `{shinylive-r}` chunk needs `engine: markdown` in its own YAML header (setting it in `_quarto.yml` is ignored by current Quarto; without it the GitHub build fails looking for Jupyter).
- Never duplicate model logic inside an app: put it in `code/functions_models.R` and bundle it with the include shortcode in the chunk (`## file: functions_models.R`, and `source("functions_models.R")` in app.R). Never write that shortcode literally inside `code/functions_models.R` itself.
- `code/functions_models.R` stays self-contained: no `library()` calls, no file paths, no side effects (it only defines objects), because it is copied into the browser apps.
- Scripts in `code/` follow the r-economics-research skill (header, `# Part X: ... ----` banners, `if (1)`/`if (0)` toggles in `master.R`) and rely on master Parts 1-2 for paths and functions.
- Only `shiny` + base R inside apps (no ggplot2 or other packages) to keep the browser download small.
- Fixed axis limits, plain-language slider labels, the shared colour palette `peib_cols`, and explicit handling of "no trade" cases (see the skill).
- The repository must stay public (GitHub Pages on a free account), and Settings > Pages > Source stays "GitHub Actions".
- Check the economics numerically (hand-computed cases and welfare accounting identities) and look at every generated PNG before handing over.

## 5. Working conventions with Florian

- Balance productivity with learning: explain code, economic concepts and Quarto/GitHub mechanics pedagogically.
- Implementer + reviewer pattern for any code task: one agent writes, an independent agent reviews. Report a clear summary of additions vs deletions per file.
- Use only single `-`, never multiple dashes, in prose.
- Do not commit or push on Florian's behalf; he commits and pushes with GitHub Desktop, and the push triggers the build (site live about 3-5 minutes later).
- When writing into this repo from Cowork: avoid `git status` before delete permission is granted (it can leave a `.git/index.lock` that blocks GitHub Desktop); for edits to existing files prefer in-place edits and verify with `md5sum`.
- Record decisions and progress in the Claude project doc `claude/project.md` (project "Political Economy of International Business").

## 6. Status (2026-10-19)

- Pipeline working end to end; R code in `code/` with `master.R` (the old `R/` folder is gone).
- Tutorial 1 has 12 approved static figures in `figures/tutorial1/`: supply side steps 1-6b (`tutorial01_firm_step1` ... `6b`), demand, equilibrium, excess supply, shortage; plus the overview sheet `figures/tutorial1/tutorial01_figures_overview.png` (a contact sheet made outside R, a handout working file, not linked on the site).
- Tutorial 1 page rebuilt (2026-10-04): short intro, the explorer app (all 12 figures; slider defaults = handout values; app axes 0-14 x 0-20; `viewerHeight: 820`), the 12 PNGs with key handout text and "Things to try", and at the end a welfare ledger (the page ends there). The "Preview of Tutorial 3" section with the per-unit tax app was removed (2026-10-04); `tutorial01_market_tax.png` and Part 6 of `code/tutorial01_figures.R` are kept for Tutorial 3 (to move there later, likely as a subsidy). `tutorial01_market_equilibrium.png` was deleted (Figure 8 replaces it).
- `draw_firm_step()` has an optional `q` (step 5a only; NULL = q*, the handout figure): a quantity above q* shades the loss on the extra units, below q* the forgone surplus (handout Question 4). `draw_market_step("demand")` treats the marginal unit (W2P = P*) as bought with a surplus of 0. The handout PNGs are unchanged.
- Tutorial 3 (2026-10-19): page `tutorials/tutorial03_subsidy.qmd` (producer subsidy and learning-by-doing, solar panels) with one explorer (views: Figure 1 market, Figure 2a shift, Figure 2 welfare changes, extra "welfare levels"; sliders b, d, s with a = 100, c = 20 fixed; outcome and welfare tables). Model E in `code/functions_models.R` Part 6 (`subsidy_outcomes()`, `draw_subsidy()`, `learning_cost()`, `draw_learning()`), figures by `code/tutorial03_figures.R` (master Part 5) into `figures/tutorial3/`.
- From Tutorial 3 on, the two figure versions are named after the handout versions: `_noanswers.png` (before the tutorial; shown on the site) and `_answers.png` (after it); `draw_subsidy(version = "noanswers"/"answers")` still accepts "student"/"tutor" as aliases. Tutorials 1-2 keep `_student`/`_tutor`. Handout figures: 1, 2a, 2 (welfare changes), 3-5 (learning curves, conceptual), 6 (period 2 without subsidy, c = 16, point E2), 7 (period 2 with the subsidy kept).
- Lecture 5 (2026-11-03): Chinn-Ito capital-account openness by World Bank region (seven regions; Florian's choice of 3 Nov, replacing a mixed UN/World Bank definition), 1970-2023 (master Part 13; website build and app test renumbered to Parts 14 and 15). Three figures in `figures/lecture5/` (`lecture05_kaopen_regions`, `_balanced`, `_facets` with a World panel) and `lecture05_kaopen_headline_numbers.csv`. Open for Florian: which figure goes on the slides.
- Lecture 5 IMF capital inflows figure (2026-11-05): master Part 14 (`bop_import.R`, `bop_clean.R`, `lecture05_bop_figures.R`; website build, app test and session info renumbered to Parts 15-17). Stacked areas of gross inflows by type plus a dashed reserve-accumulation line, % of world GDP, 1980-2025, built from the country-level IMF BOP data (the IMF's own world aggregates start only in 2005 and do not split portfolio flows). Headline numbers (data of 5 Nov 2026): peak 21.1% of world GDP in 2007, trough 2.3% in 2009, 5.0% in 2024, 8.1% in 2025 (preliminary, 159 reporters). Coverage: 77-84% of world GDP before 1996 (Japan reports from 1996), 95%+ afterwards; Belgium/Luxembourg from 2002, Austria/Ireland from 2005; Taiwan never. Deliverables in `outputs/lecture5_capital_inflows/` (PNG, PDF, SVG, PPTX, csv, methodology notes). Palette: the five validated categorical slots of the dataviz skill (`#2a78d6`, `#eb6834`, `#1baf7a`, `#eda100`, `#e87ba4`), not `peib_cols` (which fails the colour-blindness validator). Open for Florian: which variant (1980 with shaded band, or 1996) goes on the slide; whether to move the outputs into `figures/lecture5/`.
- Next candidates: tariff / small open economy, import quota, export tax, externalities (market failures I and II), matching the tutorial sequence.
- Open: test first-load time on a phone over 4G (the Tutorial 1 page loads one R engine); on phones the explorer's sidebar stacks above the plot, so the app scrolls inside its 820px frame (content about 1,250px tall at 375px width).
