# Functions for pulling publication metadata from Crossref (https://api.crossref.org).
# Crossref is the registry for DOIs. Works are found two ways:
#   - by ORCID, for works where the publisher included your ORCID iD
#   - one at a time by DOI, for works Crossref doesn't link to your ORCID
# No API key is needed. To use Crossref's faster "polite" pool, add
# CROSSREF_MAILTO=you@example.edu to .Renviron.

suppressPackageStartupMessages({
  library(httr2)
  library(purrr)
  library(tibble)
  library(stringr)
})

# Send one GET request to Crossref and return the parsed JSON
crossref_get <- function(url, query = list()) {
  mailto <- Sys.getenv("CROSSREF_MAILTO")
  if (nzchar(mailto)) query$mailto <- mailto

  request(url) |>
    req_url_query(!!!query) |>
    req_user_agent("academic-website-pipeline") |>
    req_retry(max_tries = 3) |>
    req_perform() |>
    resp_body_json()
}

# Download every work Crossref links to an ORCID iD, following cursor paging
fetch_crossref_by_orcid <- function(orcid) {
  items <- list()
  cursor <- "*" # "*" asks for the first page

  repeat {
    page <- crossref_get("https://api.crossref.org/works", list(
      filter = paste0("orcid:https://orcid.org/", orcid),
      rows = 100,
      cursor = cursor
    ))

    items <- c(items, page$message$items)
    cursor <- page$message$`next-cursor`
    if (is.null(cursor) || length(page$message$items) == 0) break
  }

  items
}

# Look up one work by DOI. Returns NULL with a warning if Crossref doesn't have it.
fetch_crossref_by_doi <- function(doi) {
  tryCatch(
    crossref_get(paste0("https://api.crossref.org/works/", doi))$message,
    error = function(e) {
      warning("Crossref has no record for DOI ", doi, call. = FALSE)
      NULL
    }
  )
}

# Readable labels for Crossref's work types. Unlisted types are kept as-is.
type_labels <- c(
  "journal-article" = "article",
  "book-chapter" = "book-chapter",
  "posted-content" = "preprint",
  "book" = "book",
  "report" = "report"
)

# Crossref stores some text as HTML: "&amp;" for an ampersand, and <i> tags for italics.
# Decode the entities and remove the tags so they don't show up on the site.
clean_crossref_text <- function(x) {
  x |>
    str_remove_all("<[^>]+>") |>
    str_replace_all(c("&amp;" = "&", "&lt;" = "<", "&gt;" = ">", "&quot;" = "\"", "&#39;" = "'", "&nbsp;" = " ")) |>
    str_squish()
}

# Turn Crossref work records into one row per publication
crossref_items_to_tibble <- function(items) {
  map(items, function(x) {
    type <- x$type %||% NA_character_
    year <- x$issued$`date-parts`[[1]][[1]] %||% NA_integer_

    # Every DOI Crossref links to this record (for example, a preprint's journal version)
    related <- unlist(lapply(x$relation %||% list(), \(r) map_chr(r, \(i) tolower(i$id %||% ""))))

    tibble(
      title = clean_crossref_text(as.character(unlist(x$title)[1] %||% NA_character_)),
      authors = clean_crossref_text(paste(
        map_chr(x$author %||% list(), \(a) trimws(paste(a$given %||% "", a$family %||% ""))),
        collapse = ", "
      )),
      year = as.integer(year),
      venue = clean_crossref_text(as.character(unlist(x$`container-title`)[1] %||% NA_character_)),
      doi = x$DOI %||% NA_character_,
      type = if (type %in% names(type_labels)) unname(type_labels[type]) else type,
      citations = as.integer(x$`is-referenced-by-count` %||% NA_integer_),
      related_dois = paste(related, collapse = ";"),
      abstract = clean_crossref_text(x$abstract %||% NA_character_),
      # Crossref has no open-access flag. A Creative Commons license on the record is the best signal.
      open_access = any(map_lgl(x$license %||% list(), \(l) str_detect(l$URL %||% "", "creativecommons")))
    )
  }) |>
    list_rbind()
}
