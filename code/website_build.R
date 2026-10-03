# ***********************************************************
# Title: SEES0082 Political Economy of International Business, UCL SSEES:
#        course website with interactive diagrams (Teaching_PEIB)
#
# Purpose: build (render) the course website on this computer, to catch
#          errors before pushing
#       Part 1: Options
#       Part 2: Find the tools: the Quarto program, the shinylive package
#               and R's own Rscript
#       Part 3: Check the pages for known pitfalls
#       Part 4: Render the website into _site/
#       Part 5: Live preview in the browser (optional)
#
# Authors: Florian Münch
# Requires: Part 1 of code/master.R (the paths root and d_site, and the
#     shinylive package); the Quarto program (https://quarto.org, or the
#     copy that comes with RStudio)
# Creates: _site/ (the rendered website). git ignores it: GitHub renders
#     and publishes its own copy after every push.
# ***********************************************************

# Explanatory notes:
  # This is what GitHub Actions does after every push (see
  # .github/workflows/publish.yml): run "quarto render" in the repository
  # folder. Doing it here first shows errors on your own screen, before they
  # break the online build. NOTHING GOES ONLINE FROM HERE: to publish,
  # commit and push with GitHub Desktop; the site is live 3-5 minutes later.
  #
  # To test with a specific Quarto version (e.g. the same one GitHub uses),
  # set the environment variable QUARTO_PATH to that quarto program before
  # running, e.g. Sys.setenv(QUARTO_PATH = "C:/quarto-1.10/bin/quarto.exe").

# Safety check: stop with a clear message if master.R Part 1 has not run
if (!exists("root") || !exists("d_site")) {
  stop("root or d_site is missing. Run code/master.R with Part 13 switched ",
       "on, or run its Part 1 before this script.", call. = FALSE)
}


# ***********************************************************
# Part 1: Options ----
# ***********************************************************
website_render  <- TRUE    # FALSE: only run the checks of Part 3
website_preview <- FALSE   # TRUE: afterwards open a live preview (Part 5).
                           # It keeps R busy until you stop it (Esc).


# ***********************************************************
# Part 2: Find the tools: Quarto, shinylive and Rscript ----
# ***********************************************************

### The Quarto program ----
# Looked for in this order:
#   1. the environment variable QUARTO_PATH, if set (see the notes above);
#   2. "quarto" on the system PATH (Quarto installed from quarto.org);
#   3. the copy of Quarto bundled with RStudio (next to RStudio's pandoc).
quarto_bin <- Sys.getenv("QUARTO_PATH")
if (!nzchar(quarto_bin)) quarto_bin <- unname(Sys.which("quarto"))
if (!nzchar(quarto_bin) && nzchar(Sys.getenv("RSTUDIO_PANDOC"))) {
  pandoc_dir <- Sys.getenv("RSTUDIO_PANDOC")
  candidates <- file.path(rep(c(dirname(pandoc_dir),
                                dirname(dirname(pandoc_dir))), each = 3),
                          c("quarto.exe", "quarto.cmd", "quarto"))
  candidates <- candidates[file.exists(candidates)]
  if (length(candidates) > 0) quarto_bin <- candidates[1]
}
if (!nzchar(quarto_bin) || !file.exists(quarto_bin)) {
  stop("Cannot find the Quarto program. Install it from ",
       "https://quarto.org/docs/get-started/ and restart RStudio, or set ",
       "Sys.setenv(QUARTO_PATH = \"<full path to quarto>\").", call. = FALSE)
}
quarto_version <- system2(quarto_bin, "--version", stdout = TRUE)
message("Using Quarto ", quarto_version[1], " (", quarto_bin, ").\n",
        "GitHub always installs the latest Quarto release: if this local ",
        "build works but GitHub's fails, update Quarto here and try again.")

### The shinylive R package ----
# Quarto calls it (through the extension in _extensions/) to turn each
# {shinylive-r} chunk into an app that runs in the browser.
if (!requireNamespace("shinylive", quietly = TRUE)) {
  stop("The R package 'shinylive' is not installed. Run ",
       "install.packages(\"shinylive\") (or Part 1 of code/master.R), ",
       "then try again.", call. = FALSE)
}

### R itself (the program Rscript) ----
# During the render, the shinylive extension starts the program "Rscript"
# to call the shinylive package. On Windows, R's own folder is usually NOT
# on the system PATH (the list of folders where programs are looked for),
# and with several R versions installed the PATH may point to one without
# shinylive. So Parts 4 and 5 put the bin folder of THIS R session first on
# the PATH while Quarto runs, and restore the old PATH afterwards.
path_old    <- Sys.getenv("PATH")
path_quarto <- paste(normalizePath(R.home("bin"), winslash = "\\"),
                     path_old, sep = .Platform$path.sep)


# ***********************************************************
# Part 3: Check the pages for known pitfalls ----
# ***********************************************************
# Explanatory notes:
  # Each check below once broke a build or an app. All problems are
  # collected first and reported together at the end of this part.
  #   Check 1: every page with an app ({shinylive-r} chunk) says
  #            "engine: markdown" in its own YAML header (between the two
  #            --- lines at the top). Without it current Quarto looks for
  #            Jupyter/Python and the GitHub build fails ("No module named
  #            'nbformat'"). Setting it in _quarto.yml is ignored.
  #   Check 2: every picture link to figures/ (including the per-tutorial
  #            subfolders figures/tutorialN/) points to an existing file.
  #   Check 3: inside each app chunk, every file pulled in with Quarto's
  #            include shortcode exists, and every source("x.R") in app.R
  #            has a matching "## file: x.R" line in the same chunk (if the
  #            names differ, the app stays blank in the browser).

### Helpers ----
# Read a text file; drop Windows line endings ("\r") if git added them
read_text <- function(f) sub("\r$", "", readLines(f, warn = FALSE,
                                                   encoding = "UTF-8"))

# The lines of each {shinylive-r} chunk of a page (a list, one per chunk)
shinylive_chunks <- function(lines) {
  starts <- grep("^\\s*```+\\s*\\{shinylive-r\\}", lines)
  lapply(starts, function(s) {
    fence <- sub("^\\s*(`+).*$", "\\1", lines[s])
    after <- seq_along(lines) > s
    end <- which(after & grepl(paste0("^\\s*", fence, "\\s*$"), lines))[1]
    if (is.na(end)) return(NULL)      # unclosed chunk: reported below
    if (end == s + 1) character(0) else lines[(s + 1):(end - 1)]
  })
}

# The lines of the YAML header at the top of a page (empty if it has none)
yaml_header <- function(lines) {
  if (length(lines) == 0 || trimws(lines[1]) != "---") return(character(0))
  end <- which(trimws(lines) == "---")[2]
  if (is.na(end) || end <= 2) return(character(0))
  lines[2:(end - 1)]
}

### Run the checks on every page ----
# All .qmd pages of the site. Like Quarto, skip every file or folder whose
# name starts with "_" or "." (e.g. _site/, _extensions/, _scratch/,
# .quarto/): Quarto does not render them as pages.
qmd_files <- list.files(root, pattern = "\\.qmd$", recursive = TRUE)
qmd_files <- qmd_files[!grepl("(^|/)[_.]", qmd_files)]

problems  <- character(0)
n_apps    <- 0
n_figures <- 0

for (qmd in qmd_files) {
  qmd_path <- file.path(root, qmd)
  qmd_dir  <- dirname(qmd_path)
  lines    <- read_text(qmd_path)
  chunks   <- shinylive_chunks(lines)

  # Check 1: engine: markdown on every page with an app
  if (length(chunks) > 0) {
    n_apps <- n_apps + length(chunks)
    engine_ok <- any(grepl("^engine:\\s*[\"']?markdown[\"']?\\s*(#.*)?$",
                           yaml_header(lines)))
    if (!engine_ok) {
      problems <- c(problems, paste0(
        qmd, ": has an app but no 'engine: markdown' in its YAML header. ",
        "Add the line   engine: markdown   between the two --- lines at ",
        "the top of the page."))
    }
  }

  # Check 2: picture links to figures/ (in ![...](...) or src="...")
  targets <- c(
    sub("^\\]\\(", "", unlist(regmatches(lines,
        gregexpr("\\]\\([^)[:space:]]+", lines)))),
    sub("^src=[\"']", "", unlist(regmatches(lines,
        gregexpr("src=[\"'][^\"']+", lines)))))
  # Keep links into figures/, but not web addresses (https://...): those
  # are not files in this repository.
  targets <- unique(targets[grepl("figures/", targets) &
                              !grepl("^[A-Za-z][A-Za-z0-9+.-]*://", targets)])
  for (t in targets) {
    n_figures <- n_figures + 1
    f <- file.path(qmd_dir, t)
    if (!file.exists(f) || dir.exists(f)) {
      problems <- c(problems, paste0(
        qmd, ": the picture '", t, "' does not exist. Check the file name ",
        "and the subfolder figures/tutorialN/ (and that the figures script ",
        "was run)."))
    }
  }

  # Check 3: include paths and source() files inside each app chunk
  for (k in seq_along(chunks)) {
    chunk <- chunks[[k]]
    if (is.null(chunk)) {
      problems <- c(problems, paste0(qmd, ": app chunk ", k, " is not ",
                                     "closed with a line of backticks."))
      next
    }
    inc <- unlist(regmatches(chunk, gregexpr(
      "\\{\\{<\\s*include\\s+[^>[:space:]]+", chunk)))
    inc <- gsub("[\"']", "", sub("^\\{\\{<\\s*include\\s+", "", inc))
    for (p in inc) {
      if (!file.exists(file.path(qmd_dir, p))) {
        problems <- c(problems, paste0(
          qmd, ": app chunk ", k, " includes '", p, "', which does not ",
          "exist (the path is relative to the page's own folder)."))
      }
    }
    app_files <- trimws(sub("^## file:", "", grep("^## file:", chunk,
                                                  value = TRUE)))
    sourced <- unlist(regmatches(chunk, gregexpr(
      "source\\(\\s*[\"'][^\"']+[\"']", chunk)))
    sourced <- gsub("^source\\(\\s*[\"']|[\"']$", "", sourced)
    for (s in setdiff(sourced, app_files)) {
      problems <- c(problems, paste0(
        qmd, ": app chunk ", k, " runs source(\"", s, "\") but has no ",
        "'## file: ", s, "' line, so that file will not exist in the app."))
    }
  }
}

if (length(problems) > 0) {
  stop("The website checks found ", length(problems), " problem(s):\n- ",
       paste(problems, collapse = "\n- "), call. = FALSE)
}
message("All checks passed: ", length(qmd_files), " pages, ", n_apps,
        " app(s), ", n_figures, " picture link(s) to figures/.")


# ***********************************************************
# Part 4: Render the website into _site/ ----
# ***********************************************************
# Quarto must run in the repository folder (where _quarto.yml is). setwd()
# goes there for the render only (and the PATH gets this R's folder, see
# Part 2); "finally" restores the previous folder and PATH even if the
# render fails. The first render also downloads the shinylive web assets
# (about 60-70 MB, once per shinylive version).
if (website_render) {
  message("Rendering the website with Quarto (about a minute)...")
  old_wd <- setwd(root)
  Sys.setenv(PATH = path_quarto)
  status <- tryCatch(system2(quarto_bin, "render"),
                     finally = {
                       setwd(old_wd)
                       Sys.setenv(PATH = path_old)
                     })
  if (!identical(as.integer(status), 0L)) {
    stop("Quarto could not render the website (exit status ", status, "). ",
         "Read the last lines of Quarto's messages above: usually a typo in ",
         "a .qmd file or in _quarto.yml, or an R error in an app.",
         call. = FALSE)
  }
  message("Done. The rendered website is in ", d_site, "\n",
          "Opening _site/index.html directly shows the pages, but the apps ",
          "need a small web server: use the live preview (Part 5) to try ",
          "them, or code/app_test.R for a single app.\n",
          "Reminder: nothing is online yet. Commit and push with GitHub ",
          "Desktop; GitHub Actions then rebuilds and publishes the site.")
}


# ***********************************************************
# Part 5: Live preview in the browser (optional) ----
# ***********************************************************
# Explanatory notes:
  # "quarto preview" starts a small local web server, opens the site in the
  # browser and re-renders a page whenever you save it. R stays busy until
  # you stop it (Esc or the red Stop sign in the console). Alternative that
  # leaves R free: type   quarto preview   in RStudio's Terminal tab (not
  # the Console) and stop it there with Ctrl+C.
if (website_preview) {
  message("Starting the live preview. Stop it with Esc in the console.")
  old_wd <- setwd(root)
  Sys.setenv(PATH = path_quarto)
  tryCatch(system2(quarto_bin, "preview"),
           finally = {
             setwd(old_wd)
             Sys.setenv(PATH = path_old)
           })
}
