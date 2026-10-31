# Functions for pulling works from the OpenAlex API (https://openalex.org).
# OpenAlex is free, has a documented API, and does not scrape websites,
# so it is more stable than scraping Google Scholar.
#
# An API key is optional. To use one, add OPENALEX_API_KEY=your-key to .Renviron.

suppressPackageStartupMessages({
  library(httr2)
  library(purrr)
  library(tibble)
  library(stringr)
})

# Send one GET request to OpenAlex and return the parsed JSON
openalex_get <- function(url, query = list()) {
  req <- request(url) |>
    req_url_query(!!!query) |>
    req_user_agent("academic-website-pipeline") |>
    req_retry(max_tries = 3) # retry on rate limits and temporary server errors

  # Attach the API key only if one is set
  key <- Sys.getenv("OPENALEX_API_KEY")
  if (nzchar(key)) req <- req_url_query(req, api_key = key)

  req |>
    req_perform() |>
    resp_body_json()
}

# Look up the OpenAlex author ID (a full URL) for an ORCID iD
openalex_author_id <- function(orcid) {
  author <- openalex_get(paste0("https://api.openalex.org/authors/orcid:", orcid))
  author$id
}

# Download every work attributed to an author.
# OpenAlex returns results in pages, so keep requesting until no cursor is returned.
fetch_openalex_works <- function(author_id) {
  works <- list()
  cursor <- "*" # "*" asks for the first page

  repeat {
    page <- openalex_get("https://api.openalex.org/works", list(
      filter = paste0("authorships.author.id:", author_id),
      select = "id,doi,title,publication_year,type,authorships,primary_location,cited_by_count",
      per_page = 200,
      cursor = cursor
    ))

    works <- c(works, page$results)
    cursor <- page$meta$next_cursor
    if (is.null(cursor) || length(page$results) == 0) break
  }

  works
}

# Look up one work by its DOI. Returns NULL with a warning if OpenAlex doesn't have it.
fetch_openalex_work_by_doi <- function(doi) {
  tryCatch(
    openalex_get(paste0("https://api.openalex.org/works/doi:", doi)),
    error = function(e) {
      warning("OpenAlex has no record for DOI ", doi, call. = FALSE)
      NULL
    }
  )
}

# Turn OpenAlex work records into one row per publication.
# Only the fields the website needs are kept.
openalex_works_to_tibble <- function(works) {
  map(works, function(w) {
    tibble(
      title = w$title %||% NA_character_,
      authors = paste(map_chr(w$authorships, \(a) a$author$display_name %||% ""), collapse = ", "),
      year = w$publication_year %||% NA_integer_,
      venue = w$primary_location$source$display_name %||% NA_character_,
      doi = str_remove(w$doi %||% NA_character_, "^https://doi.org/"),
      type = w$type %||% NA_character_,
      citations = w$cited_by_count %||% NA_integer_
    )
  }) |>
    list_rbind()
}
