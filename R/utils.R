# Shared helpers for the website data pipeline.
# Source files live in data-raw/. The scripts write Markdown files with YAML
# frontmatter into the theme's content folders (src/content/), which Astro reads
# at build time.
#
# Requires R 4.4 or newer (for the %||% operator in base R).

suppressPackageStartupMessages({
  library(here)     # paths relative to the project root (marked by the .here file)
  library(yaml)     # reads config.yml and cv.yml, and writes frontmatter
  library(readr)    # reads CSV files
  library(dplyr)
  library(purrr)
  library(stringr)
  library(tibble)
})

# Read data-raw/config.yml (publication settings)
read_config <- function() {
  yaml::read_yaml(here("data-raw", "config.yml"))
}

# TRUE when a value is missing or empty, so the field can be left out of the file
is_blank <- function(x) {
  if (is.list(x)) return(length(x) == 0)
  length(x) == 0 || all(is.na(x) | x == "")
}

# Turn a title into a file-name slug, for example "Crime & Place" -> "crime-place"
slugify <- function(x) {
  x |>
    str_to_lower() |>
    str_replace_all("[^a-z0-9]+", "-") |>
    str_remove("^-") |>
    str_remove("-$") |>
    str_sub(1, 80)
}

# Stop if two entries would produce the same file name
check_unique_slugs <- function(slugs, folder) {
  dupes <- unique(slugs[duplicated(slugs)])
  if (length(dupes) > 0) {
    stop("Duplicate file names in ", folder, ": ", paste(dupes, collapse = ", "))
  }
}

# Delete the Markdown files in a folder that these scripts generate.
# Only run this on folders the R scripts own (publications/ and projects/).
clear_generated_folder <- function(folder) {
  old <- list.files(folder, pattern = "\\.md$", full.names = TRUE)
  file.remove(old)
  invisible(length(old))
}

# Write a Markdown file with YAML frontmatter.
# Blank fields are dropped from the frontmatter, so optional fields stay optional.
write_markdown <- function(file, frontmatter, body = "") {
  frontmatter <- purrr::discard(frontmatter, is_blank)
  dir.create(dirname(file), showWarnings = FALSE, recursive = TRUE)

  # The yaml package writes TRUE and FALSE as "yes" and "no" (YAML 1.1). Astro reads YAML 1.2,
  # where those are plain text, so write logical values as true and false instead.
  bool_as_yaml <- function(x) {
    out <- ifelse(x, "true", "false")
    class(out) <- "verbatim"
    out
  }

  text <- paste0(
    "---\n",
    yaml::as.yaml(frontmatter, handlers = list(logical = bool_as_yaml)),
    "---\n\n",
    body,
    if (nzchar(body)) "\n"
  )
  cat(text, file = file)
  message("Wrote ", sub(paste0("^", here(), "/"), "", file))
}
