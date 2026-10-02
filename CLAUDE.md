# CLAUDE.md - Teaching_PEIB (course website with interactive diagrams)

Project context for Claude sessions working in this repository.

## 1. What this repo is

The public course website for **SEES0082 Political Economy of International Business** (UCL SSEES, Master's level, ~100 students, mostly without an economics background), taught by Florian Münch from Autumn Term 2026/27.

- Live site: https://flomuench.github.io/Teaching_PEIB/
- Built with **Quarto** (website) + **R Shiny apps running in the student's browser via shinylive** (webR), deployed to **GitHub Pages** by GitHub Actions on every push to `main`.
- Content is added week by week: each tutorial gets a page with a short plain-language explanation, a static figure, an interactive diagram with sliders, and "Things to try" prompts.
- The same R code also produces static PNGs that Florian inserts into his Word tutorial handouts.

Course materials (lectures, handouts, assessment) live elsewhere, in the OneDrive course folder `C:\Users\flori\OneDrive\Documents\Teaching\Political Economy of International Business`, which has its own CLAUDE.md.

## 2. Use the skill

**Always load the `r-shinylive-teaching-site` skill before working in this repo**, in particular before adding a diagram or page, changing `R/models.R`, editing the workflow, or debugging a failed build. It holds the architecture rationale, page and app templates, design rules for the diagrams, testing steps for the Cowork sandbox, and the list of gotchas that have already cost debugging time. This repo is the skill's reference implementation: copy the existing patterns rather than inventing new ones.

## 3. File map

- `_quarto.yml` - website settings, navbar (add each new tutorial page to the "Tutorials" menu), `filters: [shinylive]`.
- `index.qmd` - home page (keep its list of tutorials up to date).
- `tutorials/tutorialNN_<topic>.qmd` - one page per tutorial, one app per page. Template: `tutorials/tutorial01_market.qmd`.
- `R/models.R` - ALL model and plotting functions (base R only). Used by the apps (bundled via the include shortcode) and by `R/make_figures.R`.
- `R/make_figures.R` - run locally in RStudio (open `Teaching_PEIB.Rproj` first); writes 300 dpi PNGs to `figures/` and prints the numbers for answer keys.
- `figures/` - committed PNGs, shown above each app and used in Word handouts.
- `_extensions/quarto-ext/shinylive/` - vendored Quarto extension (v0.2.0). Do not edit.
- `.github/workflows/publish.yml` - render and deploy to GitHub Pages.
- `README.md` - Florian's own how-to (daily workflow, troubleshooting).

## 4. Rules that must not be broken

- Every page containing a `{shinylive-r}` chunk needs `engine: markdown` in its own YAML header (setting it in `_quarto.yml` is ignored by current Quarto; without it the GitHub build fails looking for Jupyter).
- Never duplicate model logic inside an app: put it in `R/models.R` and bundle it with the include shortcode in the chunk. Never write that shortcode literally inside `R/models.R` itself.
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

## 6. Status (2026-10-02)

- Pipeline working end to end: Tutorial 1 "Markets, equilibrium and welfare" (supply and demand with a per-unit tax: CS, PS, tax revenue, DWL) is live.
- Next candidates: tariff / small open economy, import quota, export tax, subsidies, externalities (market failures I and II), matching the tutorial sequence.
- Open: test first-load time on a phone over 4G; consider a larger `viewerHeight` or smaller plot for phones (the app currently scrolls inside an 820px frame).
