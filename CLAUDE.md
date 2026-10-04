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
- `code/master.R` - runs all R steps (open `Teaching_PEIB.Rproj`, open `code/master.R`, Source). Part 1 settings (root folder via USERPROFILE, else the working directory, checked for `_quarto.yml`; paths `c_code`, `d_tut`, `o_fig`, `o_fig_t1`, `d_site`; `pacman::p_load(shiny, shinylive)`), Part 2 sources `functions_models.R`, Part 3 Tutorial 1 figures (on), Parts 4-12 Tutorials 2-10 `tutorialNN_figures.R` (off until the scripts exist), Part 13 `website_build.R` (off), Part 14 `app_test.R` (off), Part 15 `sessionInfo()`.
- `code/functions_models.R` - ALL model and plotting functions (base R only). Used by the apps (bundled via the include shortcode) and by the figure scripts.
- `code/tutorial01_figures.R` - writes the Tutorial 1 PNGs (300 dpi) to `figures/tutorial1/` and prints the answer key numbers. Uses `o_fig_t1` and the functions from master Parts 1-2; never sets the working directory itself.
- `code/website_build.R` - checks every page (`engine: markdown` on app pages, `figures/` links, include paths and `## file:`/`source()` names in app chunks), then `quarto render` into `_site/` (optional `quarto preview`). Env var `QUARTO_PATH` selects a specific Quarto. During the render it puts this R session's `bin` folder first on the PATH (restored afterwards), because the shinylive extension calls plain `Rscript`, which is often not on the Windows PATH.
- `code/app_test.R` - copies one page's app (app.R + included files) into a temp folder and runs it with `shiny::runApp()`.
- `figures/tutorialN/` - committed PNGs, one subfolder per tutorial (`figures/tutorial1/`, `figures/tutorial2/`, ...: no leading zero in the folder name, while file names keep `tutorial01_...`). Pages link them as `../figures/tutorialN/<file>.png`; master.R Part 1 defines one path per tutorial (`o_fig_t1`, later `o_fig_t2`, ...). Shown above each app and used in Word handouts.
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

## 6. Status (2026-10-04)

- Pipeline working end to end; R code in `code/` with `master.R` (the old `R/` folder is gone).
- Tutorial 1 has 12 approved static figures in `figures/tutorial1/`: supply side steps 1-6b (`tutorial01_firm_step1` ... `6b`), demand, equilibrium, excess supply, shortage; plus the overview sheet `figures/tutorial1/tutorial01_figures_overview.png` (a contact sheet made outside R, a handout working file, not linked on the site).
- Tutorial 1 page rebuilt (2026-10-04): short intro, the explorer app (all 12 figures; slider defaults = handout values; app axes 0-14 x 0-20; `viewerHeight: 820`), the 12 PNGs with key handout text and "Things to try", and at the end a welfare ledger (the page ends there). The "Preview of Tutorial 3" section with the per-unit tax app was removed (2026-10-04); `tutorial01_market_tax.png` and Part 6 of `code/tutorial01_figures.R` are kept for Tutorial 3 (to move there later, likely as a subsidy). `tutorial01_market_equilibrium.png` was deleted (Figure 8 replaces it).
- `draw_firm_step()` has an optional `q` (step 5a only; NULL = q*, the handout figure): a quantity above q* shades the loss on the extra units, below q* the forgone surplus (handout Question 4). `draw_market_step("demand")` treats the marginal unit (W2P = P*) as bought with a surplus of 0. The handout PNGs are unchanged.
- Next candidates: tariff / small open economy, import quota, export tax, subsidies, externalities (market failures I and II), matching the tutorial sequence.
- Open: test first-load time on a phone over 4G (the Tutorial 1 page loads one R engine); on phones the explorer's sidebar stacks above the plot, so the app scrolls inside its 820px frame (content about 1,250px tall at 375px width).
