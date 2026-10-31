# Builds one Markdown file per publication in src/content/publications/.
# Three sources, merged:
#   1. Crossref, by the ORCID iD in data-raw/config.yml (automatic)
#   2. Crossref, by each DOI in config.yml under dois (for works not linked to your ORCID)
#   3. data-raw/publications_manual.csv (for anything with no DOI, such as OSF preprints)
#
# Duplicates are matched by normalized title. When a work appears more than once,
# the manual row wins, then a journal or book version over a preprint.
# DOIs listed under exclude_dois in config.yml are dropped.
# The whole publications/ folder is regenerated on each run, so don't edit those files directly.

source(here::here("R", "utils.R"))
source(here::here("R", "crossref.R"))

config <- read_config()
orcid <- config$publications$orcid %||% ""
preprint_dois <- tolower(unlist(config$publications$preprint_dois %||% list()))
# Preprint DOIs are fetched too, so they need to be in the lookup list
manual_dois <- unique(c(unlist(config$publications$dois %||% list()), preprint_dois))
exclude_dois <- tolower(unlist(config$publications$exclude_dois %||% list()))

# 1. Crossref works linked to your ORCID
crossref_orcid_rows <- if (nzchar(orcid)) {
  message("Fetching works from Crossref for ORCID ", orcid)
  crossref_items_to_tibble(fetch_crossref_by_orcid(orcid))
} else {
  message("No ORCID set in data-raw/config.yml. Skipping the ORCID lookup.")
  tibble()
}

# 2. Crossref works from the DOI list
crossref_doi_rows <- manual_dois |>
  map(fetch_crossref_by_doi) |>
  compact() |>
  crossref_items_to_tibble()

# 3. Manual rows: everything is read as text, then the year is converted
manual_rows <- read_csv(
  here("data-raw", "publications_manual.csv"),
  col_types = cols(.default = col_character()),
  show_col_types = FALSE
) |>
  filter(!is.na(title), title != "") |>
  mutate(
    year = as.integer(year),
    citations = NA_integer_ # manual rows have no citation counts
  )

# 4. Merge, find preprints that duplicate a journal or book version, and drop excluded works
normalize_title <- function(x) {
  str_to_lower(str_remove_all(x, "[^[:alnum:]]"))
}

all_rows <- bind_rows(
  mutate(manual_rows, source = "manual", related_dois = NA_character_),
  mutate(crossref_doi_rows, source = "crossref"),
  mutate(crossref_orcid_rows, source = "crossref")
) |>
  mutate(
    doi = str_to_lower(doi), # DOIs are case-insensitive
    key = normalize_title(title),
    # Crossref often types CrimRxiv (10.21428) and OSF (10.31219) preprints as journal
    # articles, so the DOI prefix is checked too
    is_preprint = type == "preprint" | str_starts(doi, "10.21428/") | str_starts(doi, "10.31219/") |
      doi %in% preprint_dois
  )

# Journal and book versions, which a preprint can duplicate
journal_rows <- filter(all_rows, !is_preprint)
journal_dois <- journal_rows$doi
journal_keys <- journal_rows$key
# DOIs that Crossref links to a journal version, in either direction
linked_to_journal <- unlist(str_split(journal_rows$related_dois, ";"))

all_rows <- all_rows |>
  mutate(
    # Preprints listed in config.yml are kept, even when a journal version exists
    duplicate_of_journal = is_preprint & !doi %in% preprint_dois & (
      key %in% journal_keys |
        doi %in% linked_to_journal |
        map_lgl(related_dois, \(r) any(unlist(str_split(r, ";")) %in% journal_dois))
    )
  )

dropped <- filter(all_rows, duplicate_of_journal)
if (nrow(dropped) > 0) {
  message("Dropped ", nrow(dropped), " preprint(s) that duplicate a journal or book version:")
  message(paste0("  ", dropped$title, " [", dropped$doi, "]", collapse = "\n"))
}

publications <- all_rows |>
  filter(!duplicate_of_journal) |>
  filter(is.na(doi) | !doi %in% exclude_dois) |>
  mutate(
    # Lower rank wins when a work appears more than once with the same title
    rank = case_when(
      source == "manual" ~ 0,
      is_preprint ~ 3,
      type == "book-chapter" ~ 2,
      TRUE ~ 1
    ),
    # Listed preprints use their DOI as the key, so they aren't merged with the journal version
    dedupe_key = if_else(doi %in% preprint_dois, doi, key)
  ) |>
  arrange(rank) |>
  distinct(dedupe_key, .keep_all = TRUE) |>
  arrange(desc(year), title)

if (nrow(publications) == 0) {
  warning("No publications found. Check config.yml and publications_manual.csv.")
}

# Titles can change between a preprint and its journal version, so check the final list
# for near-identical titles with different DOIs. Each pair needs a manual decision:
# add the preprint's DOI to exclude_dois in config.yml if it's a duplicate.
keys <- coalesce(publications$key, "")
similarity <- 1 - adist(keys) / pmax(outer(nchar(keys), nchar(keys), pmax), 1)
near <- which(similarity > 0.8 & upper.tri(similarity), arr.ind = TRUE)
near <- near[publications$doi[near[, 1]] != publications$doi[near[, 2]], , drop = FALSE]
# Listed preprints are expected to share a title with their journal version
listed <- publications$doi[near[, 1]] %in% preprint_dois | publications$doi[near[, 2]] %in% preprint_dois
near <- near[!listed, , drop = FALSE]
if (nrow(near) > 0) {
  warning("Possible duplicates with similar titles. Check these pairs:\n", paste0(
    "  ", publications$title[near[, 1]], " [", publications$doi[near[, 1]], "]  vs  ",
    publications$title[near[, 2]], " [", publications$doi[near[, 2]], "]", collapse = "\n"
  ), call. = FALSE)
}

# Readable badge text for each Crossref work type
type_label <- function(type) {
  labels <- c(
    "article" = "Journal article",
    "book-chapter" = "Book chapter",
    "book" = "Book",
    "report" = "Report"
  )
  if (is.na(type)) return(NA_character_)
  if (type %in% names(labels)) unname(labels[type]) else str_to_sentence(type)
}

# BibTeX entry type. Preprints are unpublished, reports and briefings are tech reports,
# and book chapters are incollection entries.
bibtex_type <- function(p) {
  if (isTRUE(p$is_preprint)) return("unpublished")
  if (!is.na(p$venue) && p$venue == "Applied Police Briefings") return("techreport")
  switch(coalesce(p$type, "article"),
    "book-chapter" = "incollection",
    "book" = "book",
    "article"
  )
}

# One BibTeX entry for a publication. The key is first author's last name + year + first word of the title.
make_bibtex <- function(p) {
  authors <- if (is.na(p$authors)) character(0) else trimws(strsplit(p$authors, ",")[[1]])
  family <- if (length(authors) > 0) sub(".* ", "", authors[1]) else "anon"
  first_word <- str_extract(p$title, "[[:alpha:]]+")
  key <- str_to_lower(str_remove_all(paste0(family, p$year, first_word), "[^[:alnum:]]"))

  # Which field holds the venue depends on the entry type
  venue_field <- switch(bibtex_type(p),
    "article" = "journal",
    "incollection" = "booktitle",
    "techreport" = "institution",
    "unpublished" = "howpublished",
    NULL
  )

  fields <- c(
    author = if (length(authors) > 0) paste(authors, collapse = " and "),
    title = p$title,
    year = as.character(p$year),
    if (!is.null(venue_field)) setNames(p$venue, venue_field),
    doi = p$doi,
    url = if (!is.na(p$doi)) paste0("https://doi.org/", p$doi)
  )
  fields <- fields[!is.na(fields) & nzchar(fields)]

  lines <- paste0("  ", names(fields), " = {", unname(fields), "}")
  paste0("@", bibtex_type(p), "{", key, ",\n", paste(lines, collapse = ",\n"), "\n}")
}

# Page body for a publication: the abstract (when there is one), then the BibTeX code
publication_body <- function(p) {
  abstract_block <- if (!is_blank(p$abstract)) c("## Abstract", "", p$abstract, "")
  bibtex_block <- c("## BibTeX", "", "```bibtex", make_bibtex(p), "```")
  paste(c(abstract_block, bibtex_block), collapse = "\n")
}

# 5. Write one file per publication. Forthcoming works have no year.
# Preprints get a "-preprint" suffix, so a preprint and its journal version don't share a file name
slugs <- paste0(
  coalesce(as.character(publications$year), "forthcoming"), "-",
  slugify(publications$title),
  if_else(publications$is_preprint, "-preprint", "")
)
check_unique_slugs(slugs, "src/content/publications")

clear_generated_folder(here("src", "content", "publications"))

# Preprint links: each journal DOI in preprint_pairs gets the DOI of its CrimRxiv preprint
pair_list <- config$publications$preprint_pairs %||% list()
preprint_for <- setNames(
  map_chr(pair_list, \(p) tolower(p$preprint)),
  map_chr(pair_list, \(p) tolower(p$journal))
)

publications |>
  mutate(
    slug = slugs,
    preprint_doi = unname(preprint_for[doi])
  ) |>
  split(seq_len(nrow(publications))) |>
  walk(function(p) {
    write_markdown(
      here("src", "content", "publications", paste0(p$slug, ".md")),
      frontmatter = list(
        title = p$title,
        author = p$authors,
        date = as.character(p$year),
        journal = p$venue,
        external_url = if (!is.na(p$doi)) paste0("https://doi.org/", p$doi),
        preprint_url = if (!is.na(p$preprint_doi)) paste0("https://doi.org/", p$preprint_doi),
        # The publications page groups entries by this field: "Publication" or "Preprint"
        category = if (p$is_preprint) {
          "Preprint"
        } else if (!is.na(p$venue) && p$venue == "Applied Police Briefings") {
          "Reports and Briefings"
        } else {
          "Publication"
        },
        # Shown as a badge on the card. Preprints are typed as journal articles by Crossref, so skip them
        # Preprints show "Preprint"; reports and briefings show "Report"
        type = if (p$is_preprint) {
          "Preprint"
        } else if (!is.na(p$venue) && p$venue == "Applied Police Briefings") {
          "Report"
        } else {
          type_label(p$type)
        },
        open_access = if (!is.na(p$open_access)) p$open_access,
        abstract = p$abstract
      ),
      body = publication_body(p)
    )
  })
