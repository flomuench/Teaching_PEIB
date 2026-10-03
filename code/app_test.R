# ***********************************************************
# Title: SEES0082 Political Economy of International Business, UCL SSEES:
#        course website with interactive diagrams (Teaching_PEIB)
#
# Purpose: test the app of one tutorial page on this computer, as a normal
#          Shiny app, before pushing
#       Part 1: Options: which page, which app
#       Part 2: Function that copies an app out of a page
#       Part 3: Copy the app into a temporary folder and check it
#       Part 4: Run the app
#
# Authors: Florian Münch
# Requires: Part 1 of code/master.R (the path root and the shiny package);
#     the chosen tutorial page and the files its app includes (e.g.
#     code/functions_models.R)
# Creates: a temporary folder with app.R and functions_models.R (deleted
#     when R closes); nothing in the repository
# ***********************************************************

# Explanatory notes:
  # On the website, each app is a {shinylive-r} chunk inside a .qmd page.
  # The chunk holds several "files", each starting with a line
  # "## file: <name>": app.R (written in the page) and functions_models.R
  # (pulled in from code/functions_models.R by Quarto's include shortcode
  # when the site is rendered). This script copies app.R out of the page
  # and the included files from the repository into a temporary folder, and
  # runs it with shiny::runApp(): the same app, but in normal R on this
  # computer. Errors then appear in the RStudio console instead of a blank
  # app on the website.
  #
  # One difference to the browser: here the app can use any package you
  # have installed. In the browser (webR) only shiny and base R are safe, so
  # an app that works here can still fail online if it uses other packages.

# Safety check: stop with a clear message if master.R Part 1 has not run
if (!exists("root")) {
  stop("root is missing. Run code/master.R with Part 14 switched on, or ",
       "run its Part 1 before this script.", call. = FALSE)
}


# ***********************************************************
# Part 1: Options: which page, which app ----
# ***********************************************************
app_qmd   <- "tutorials/tutorial01_market.qmd"  # page, relative to root
app_chunk <- 1        # which app on that page: 1 = the first app chunk
# Run the app at the end? interactive() is TRUE in RStudio. When the script
# runs non-interactively (e.g. Rscript), the app is only copied and checked,
# because runApp() would wait forever for a browser.
app_launch <- interactive()


# ***********************************************************
# Part 2: Function that copies an app out of a page ----
# ***********************************************************
# extract_shinylive_app(): writes the files of one {shinylive-r} chunk of a
# .qmd page into out_dir and returns out_dir.
#   - A file whose content is just Quarto's include shortcode is replaced by
#     a copy of the included file (path relative to the page's folder).
#   - Any other file (e.g. app.R) is written out as it stands in the page.
#   - A chunk without "## file:" lines is a one-file app: it becomes app.R.
# Then every .R file is parsed, to catch syntax errors early.
extract_shinylive_app <- function(qmd_file, chunk = 1,
                                  out_dir = file.path(tempdir(), "app_test")) {
  if (!file.exists(qmd_file)) {
    stop("Cannot find the page ", qmd_file, call. = FALSE)
  }
  # Read the page; drop Windows line endings ("\r") if git added them
  lines <- sub("\r$", "", readLines(qmd_file, warn = FALSE,
                                    encoding = "UTF-8"))

  # Step 1: find the chunk, from its ```{shinylive-r} line to the closing
  # line of backticks
  starts <- grep("^\\s*```+\\s*\\{shinylive-r\\}", lines)
  if (length(starts) == 0) {
    stop(qmd_file, " contains no {shinylive-r} app chunk.", call. = FALSE)
  }
  if (chunk < 1 || chunk > length(starts)) {
    stop(qmd_file, " has ", length(starts), " app chunk(s); app_chunk = ",
         chunk, " does not exist.", call. = FALSE)
  }
  s <- starts[chunk]
  fence <- sub("^\\s*(`+).*$", "\\1", lines[s])
  end <- which(seq_along(lines) > s &
                 grepl(paste0("^\\s*", fence, "\\s*$"), lines))[1]
  if (is.na(end)) {
    stop("App chunk ", chunk, " in ", qmd_file, " is not closed with a ",
         "line of backticks.", call. = FALSE)
  }
  body <- if (end > s + 1) lines[(s + 1):(end - 1)] else character(0)

  # Step 2: split the chunk into its files at the "## file:" lines
  marks <- grep("^## file:", body)
  if (length(marks) == 0) {
    # One-file app: everything except the "#|" option lines is app.R
    files <- list(app.R = body[!grepl("^#\\|", body)])
  } else {
    names_f <- trimws(sub("^## file:", "", body[marks]))
    ends    <- c(marks[-1] - 1, length(body))
    files   <- lapply(seq_along(marks), function(i) {
      if (ends[i] > marks[i]) body[(marks[i] + 1):ends[i]] else character(0)
    })
    names(files) <- names_f
  }
  if (!"app.R" %in% names(files)) {
    stop("App chunk ", chunk, " in ", qmd_file, " has no '## file: app.R' ",
         "part. Files found: ", paste(names(files), collapse = ", "),
         call. = FALSE)
  }

  # Step 3: write the files into a fresh temporary folder
  unlink(out_dir, recursive = TRUE)
  dir.create(out_dir, recursive = TRUE)
  include_re <- "^\\s*\\{\\{<\\s*include\\s+([^>[:space:]]+)\\s*>\\}\\}\\s*$"
  for (nm in names(files)) {
    content <- files[[nm]]
    content_nonempty <- content[nzchar(trimws(content))]
    if (length(content_nonempty) == 1 && grepl(include_re, content_nonempty)) {
      inc <- gsub("[\"']", "", sub(include_re, "\\1", content_nonempty))
      src <- file.path(dirname(qmd_file), inc)
      if (!file.exists(src)) {
        stop("'", nm, "' should be included from ", inc, " (relative to ",
             dirname(qmd_file), "), but that file does not exist.",
             call. = FALSE)
      }
      file.copy(src, file.path(out_dir, nm), overwrite = TRUE)
      message("Copied ", normalizePath(src), " as ", nm)
    } else {
      writeLines(content, file.path(out_dir, nm), useBytes = TRUE)
      message("Wrote ", nm, " (", length(content), " lines from the page)")
    }
  }

  # Step 4: check that every R file parses and every source()d file is there
  for (f in list.files(out_dir, pattern = "\\.[Rr]$", full.names = TRUE)) {
    tryCatch(parse(f, encoding = "UTF-8"), error = function(e) {
      stop("R syntax error in ", basename(f), ": ", conditionMessage(e),
           call. = FALSE)
    })
  }
  app_lines <- readLines(file.path(out_dir, "app.R"), warn = FALSE)
  sourced <- unlist(regmatches(app_lines, gregexpr(
    "source\\(\\s*[\"'][^\"']+[\"']", app_lines)))
  sourced <- gsub("^source\\(\\s*[\"']|[\"']$", "", sourced)
  missing <- sourced[!file.exists(file.path(out_dir, sourced))]
  if (length(missing) > 0) {
    stop("app.R runs source(\"", missing[1], "\"), but the chunk has no ",
         "'## file: ", missing[1], "' part.", call. = FALSE)
  }
  invisible(out_dir)
}


# ***********************************************************
# Part 3: Copy the app into a temporary folder and check it ----
# ***********************************************************
app_dir <- extract_shinylive_app(file.path(root, app_qmd), chunk = app_chunk)
message("App ", app_chunk, " of ", app_qmd, " is ready in ", app_dir)


# ***********************************************************
# Part 4: Run the app ----
# ***********************************************************
# A browser window opens with the app. The console is busy while it runs:
# stop it with the red Stop sign in the console (or Esc), then edit the
# page and run this script again.
if (app_launch) {
  shiny::runApp(app_dir, launch.browser = TRUE)
} else {
  message("Not started (R is not running interactively). To start it, ",
          "run in RStudio:  shiny::runApp(\"", app_dir, "\")")
}
