# Teaching_PEIB - SEES0082 interactive course website

Website with interactive diagrams for SEES0082 "Political Economy of International Business" (UCL SSEES, 2026/27).

Live site: <https://flomuench.github.io/Teaching_PEIB/>

The diagrams are small Shiny apps that run **inside the student's browser** (via [shinylive](https://posit-dev.github.io/r-shinylive/) and webR). There is no server to maintain: GitHub Pages just hosts static files.

## What each file does

| File / folder | Purpose |
|---|---|
| `_quarto.yml` | Website settings: title, navigation bar, theme, footer, shinylive filter. Add new pages to the navbar here. |
| `index.qmd` | Home page. |
| `tutorials/tutorial01_market.qmd` | Tutorial 1 page: short intro, the interactive explorer (one app for all 12 handout figures: choose a figure, move the sliders), the static figures with the key handout text and "things to try", and the welfare ledger. |
| `code/master.R` | **Start here for all R work.** Runs every R step in order (see "The R code" below). |
| `code/functions_models.R` | **The shared model code**: all model and drawing functions (`market_outcomes()`, `draw_market()`, `draw_firm_step()`, `draw_market_step()`, ...), base R only. Used by both the website apps (bundled into each app) and the handout figures. |
| `code/tutorial01_figures.R` | Makes the Tutorial 1 PNGs in `figures/tutorial1/` and prints the answer key numbers. |
| `code/website_build.R` | Optional: checks the pages and builds the website on your computer. |
| `code/app_test.R` | Optional: runs one page's app on your computer as a normal Shiny app. |
| `figures/` | PNG figures (committed to git), one subfolder per tutorial: `figures/tutorial1/`, `figures/tutorial2/`, ... (no leading zero in the folder name); lecture data figures (PNG and PDF) in `figures/lectureN/` (e.g. `figures/lecture5/`). |
| `data/` | Data for the lecture figures: `data/kaopen/raw/` and `data/imf_bop/raw/` (downloads, not committed, re-created by `code/kaopen_import.R` and `code/bop_import.R`) and `data/kaopen/clean/`, `data/imf_bop/clean/` (csv files, committed). |
| `outputs/` | Slide-ready deliverables that are not website figures: `outputs/lecture5_capital_inflows/` (IMF capital inflows figure as PNG, PDF, SVG, PPTX, csv and methodology notes; master Part 14). |
| `Teaching_PEIB.Rproj` | RStudio project: opening it sets the working directory to this folder. |
| `.github/workflows/publish.yml` | GitHub Actions recipe that renders and publishes the site on every push. |
| `_extensions/quarto-ext/shinylive/` | The Quarto shinylive extension (do not edit). |
| `.gitignore` | Files git should ignore (e.g. the rendered `_site/`). |

## The R code (`code/master.R`)

1. Open `Teaching_PEIB.Rproj` (double-click it), so RStudio starts in this folder.
2. Open `code/master.R` and click **Source**. Each step is switched on with `if (1)` and off with `if (0)`; change only the 1 or 0.

| Part | What it does | Default |
|---|---|---|
| 1 | Settings: finds the repository folder, sets the folder paths, loads packages (`shiny`, `shinylive`, `png`, and for the lecture data figures `haven`, `curl`, `jsonlite`, `data.table`, `countrycode`, `ggplot2`, `ggrepel`, `scales`, `ragg`, `systemfonts`, and for the IMF figure `imf.data`, `svglite`, `officer`, `rvg`) | always runs |
| 2 | Loads the functions in `code/functions_models.R` (models, diagrams, apps) and `code/functions_lecture.R` (ggplot theme and save helper for lecture data figures; never in the apps) | always runs |
| 3 | `code/tutorial01_figures.R`: Tutorial 1 PNGs and answer key numbers | on |
| 4-12 | Tutorials 2 to 10: `code/tutorial02_figures.R` ... (create the script when the content exists, then switch it on) | 4-7 on, 8-12 off |
| 13 | Lecture 5 data figures: `code/kaopen_import.R` (downloads the Chinn-Ito financial openness index into `data/kaopen/raw/`, gitignored, once), `code/kaopen_clean.R` (the seven World Bank regions from the `countrycode` package, region-year means into `data/kaopen/clean/`), `code/lecture05_kaopen_figures.R` (three figures as PNG and PDF into `figures/lecture5/`: seven regions, the same on a balanced panel, small multiples with a World panel; plus a headline numbers csv) | on |
| 14 | Lecture 5 IMF capital inflows figure: `code/bop_import.R` (verifies the IMF codes against the code lists and downloads the balance of payments and WEO GDP data via the IMF SDMX 3.0 API into `data/imf_bop/raw/`, gitignored, once; set `BOP_FORCE_DOWNLOAD <- TRUE` to refresh), `code/bop_clean.R` (economy-year panel, world sums, coverage and checks into `data/imf_bop/clean/`), `code/lecture05_bop_figures.R` (stacked-area figure 1980-2025 and a 1996 variant as PNG, PDF and SVG, a 3-slide PPTX on the course template, the figure csv, headline numbers and methodology notes into `outputs/lecture5_capital_inflows/`) | on |
| 15 | `code/website_build.R`: checks the pages and renders the site into `_site/` | off |
| 16 | `code/app_test.R`: runs one page's app as a normal Shiny app | off |
| 17 | Prints R and package versions | always runs |

All scripts in `code/` rely on Parts 1 and 2. To run one script by hand, run Parts 1 and 2 of `master.R` first.

## One-time GitHub setup

1. In GitHub Desktop: **File > Add local repository**, choose this folder (if asked, click "create a repository" here), make a first commit, then click **Publish repository**. Name it `Teaching_PEIB` and **untick "Keep this code private"** (free GitHub Pages needs a public repository). The branch must be called `main`.
2. On github.com, open the repository: **Settings > Pages > Build and deployment > Source: "GitHub Actions"**.
3. The very first run (started by step 1) may show a red cross because Pages was not switched on yet. That is expected: go to **Actions > Publish website > Run workflow** (or push any commit). After 3-5 minutes the site is live.

## Daily workflow

1. Edit a `.qmd` file in RStudio.
2. In GitHub Desktop: write a short summary, **Commit to main**, then **Push origin**.
3. Wait about 3-5 minutes. Check progress in the repository's **Actions** tab (yellow = running, green tick = published, red cross = failed).

## Preview locally (optional but recommended)

One-time: install [Quarto](https://quarto.org/docs/get-started/) and, in R, `install.packages("shinylive")`.

Then, with `Teaching_PEIB.Rproj` open:

- click **Render** on a `.qmd` file, or
- type `quarto preview` in the RStudio **Terminal** tab (not the Console). A browser window opens and refreshes whenever you save, or
- switch on Part 15 of `code/master.R`: it first checks the pages for known pitfalls (missing `engine: markdown`, broken figure links, wrong file names in the app chunk), then renders the whole site into `_site/`. Set `website_preview <- TRUE` at the top of `code/website_build.R` for a live preview afterwards.

To test only one app: switch on Part 16 of `code/master.R` (choose the page at the top of `code/app_test.R`). The app opens in a browser window as a normal Shiny app, and errors appear in the RStudio console.

The first render downloads the shinylive web assets (about 60-70 MB, once per shinylive version).

## Regenerate the PNG figures

1. Open `Teaching_PEIB.Rproj`, then `code/tutorial01_figures.R`.
2. Change the parameters in its Part 1 if needed (so the figures match your handout questions).
3. Open `code/master.R` (Part 3 is on) and click **Source**. The PNGs in `figures/tutorial1/` are overwritten and the answer key numbers appear in the console. Commit and push them.
4. In Word: **Insert > Pictures > This Device** and pick the PNG.

## Add a new app page

1. Copy `tutorials/tutorial01_market.qmd` to e.g. `tutorials/tutorial02_trade.qmd` and change the title and text.
2. Put any new model/plotting functions in `code/functions_models.R` (base R only, no `library()` calls, no file paths). If you use a new file in `code/` instead, change the `include` line at the bottom of the app chunk to point to it, and keep its `## file:` line and the `source()` line in `app.R` on the same file name.
3. Edit the `## file: app.R` part of the `{shinylive-r}` chunk (inputs, outputs).
4. Add the page to the "Tutorials" menu in `_quarto.yml`, and a link on `index.qmd`.
5. For the handout figures: copy `code/tutorial01_figures.R` to `code/tutorialNN_figures.R`, add a path for its folder in Part 1 of `code/master.R` (e.g. `o_fig_t2 <- file.path(o_fig, "tutorial2")`), save the PNGs there, link them from the page as `../figures/tutorial2/<file>.png`, and switch on the script's line in `code/master.R`.
6. Preview locally (`code/master.R` Parts 14 and 15), then commit and push.

Rules for the app code:

- Keep `#| standalone: true` at the top of the chunk, and the `## file: ...` lines exactly as they are.
- Use only packages available for webR. Base R graphics + `shiny` keeps downloads small; every extra package (e.g. ggplot2) adds seconds to the first load for students.
- Never type the Quarto `include` shortcode inside an `.R` file that is itself included (Quarto would try to include the file inside itself).

## Troubleshooting

- **Red cross in the Actions tab**: click the failed run, open the red step and read the last lines of the log. Usually a typo in a `.qmd` or `_quarto.yml` (YAML is sensitive to indentation). Fix, commit, push again.
- **The app area stays blank or grey**: wait 30 seconds (first load). If it is still blank, open the browser's developer console (F12 or Cmd+Option+I > Console) and look for red errors. An R error in `app.R` or `functions_models.R` shows up there; test the app on your computer first with Part 15 of `code/master.R` (`code/app_test.R`), or run Parts 1 and 2 of `code/master.R` and then e.g. `draw_market(tax = 2)`.
- **First load is slow**: expected. The browser downloads R itself (webR) the first time; later visits use the cache. The static PNGs on each page are there so students see the diagrams immediately.
- **Site not updated after a push**: check the Actions tab; then force-refresh the page (Ctrl+F5 / Cmd+Shift+R).
