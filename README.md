# Teaching_PEIB - SEES0082 interactive course website

Website with interactive diagrams for SEES0082 "Political Economy of International Business" (UCL SSEES, 2026/27).

Live site: <https://flomuench.github.io/Teaching_PEIB/>

The diagrams are small Shiny apps that run **inside the student's browser** (via [shinylive](https://posit-dev.github.io/r-shinylive/) and webR). There is no server to maintain: GitHub Pages just hosts static files.

## What each file does

| File / folder | Purpose |
|---|---|
| `_quarto.yml` | Website settings: title, navigation bar, theme, footer, shinylive filter. Add new pages to the navbar here. |
| `index.qmd` | Home page. |
| `tutorials/tutorial01_market.qmd` | Tutorial 1 page: explanation, static figure, interactive app, "things to try". |
| `R/models.R` | **The shared model code**: `market_outcomes()` (all the numbers) and `draw_market()` (the base R diagram). Used by both the website apps and the handout figures. |
| `R/make_figures.R` | Run locally in RStudio to (re)create the PNGs in `figures/` for Word handouts and the website. |
| `figures/` | PNG figures (committed to git). |
| `Teaching_PEIB.Rproj` | RStudio project: opening it sets the working directory to this folder. |
| `.github/workflows/publish.yml` | GitHub Actions recipe that renders and publishes the site on every push. |
| `_extensions/quarto-ext/shinylive/` | The Quarto shinylive extension (do not edit). |
| `.gitignore` | Files git should ignore (e.g. the rendered `_site/`). |

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
- type `quarto preview` in the RStudio **Terminal** tab (not the Console). A browser window opens and refreshes whenever you save.

The first render downloads the shinylive web assets (about 60-70 MB, once per shinylive version).

## Regenerate the PNG figures

1. Open `Teaching_PEIB.Rproj`, then `R/make_figures.R`.
2. Change the parameters in the clearly marked block at the top if needed (so the figures match your handout questions).
3. Click **Source**. The PNGs in `figures/` are overwritten. Commit and push them.
4. In Word: **Insert > Pictures > This Device** and pick the PNG.

## Add a new app page

1. Copy `tutorials/tutorial01_market.qmd` to e.g. `tutorials/tutorial02_trade.qmd` and change the title and text.
2. Put any new model/plotting functions in `R/models.R` (or a new file in `R/`, then change the `include` line at the bottom of the app chunk to point to it).
3. Edit the `## file: app.R` part of the `{shinylive-r}` chunk (inputs, outputs).
4. Add the page to the "Tutorials" menu in `_quarto.yml`, and a link on `index.qmd`.
5. Preview locally, then commit and push.

Rules for the app code:

- Keep `#| standalone: true` at the top of the chunk, and the `## file: ...` lines exactly as they are.
- Use only packages available for webR. Base R graphics + `shiny` keeps downloads small; every extra package (e.g. ggplot2) adds seconds to the first load for students.
- Never type the Quarto `include` shortcode inside an `.R` file that is itself included (Quarto would try to include the file inside itself).

## Troubleshooting

- **Red cross in the Actions tab**: click the failed run, open the red step and read the last lines of the log. Usually a typo in a `.qmd` or `_quarto.yml` (YAML is sensitive to indentation). Fix, commit, push again.
- **The app area stays blank or grey**: wait 30 seconds (first load). If it is still blank, open the browser's developer console (F12 or Cmd+Option+I > Console) and look for red errors. An R error in `app.R` or `models.R` shows up there; test the code in RStudio first, e.g. by running `source("R/models.R"); draw_market(tax = 2)`.
- **First load is slow**: expected. The browser downloads R itself (webR) the first time; later visits use the cache. The static PNG above each app is there so students see the diagram immediately.
- **Site not updated after a push**: check the Actions tab; then force-refresh the page (Ctrl+F5 / Cmd+Shift+R).
