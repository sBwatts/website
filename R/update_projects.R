# Builds one Markdown file per project in src/content/projects/ from data-raw/projects.csv.
# Edit the CSV by hand. The only required column is title.
# Leave end_year blank for ongoing projects.
# The whole projects/ folder is regenerated on each run, so don't edit those files directly.

source(here::here("R", "utils.R"))

projects <- read_csv(
  here("data-raw", "projects.csv"),
  col_types = cols(.default = col_character()),
  show_col_types = FALSE
) |>
  filter(!is.na(title), title != "") |>
  mutate(
    start_year = as.integer(start_year),
    end_year = as.integer(end_year),
    ongoing = is.na(end_year)
  ) |>
  # Ongoing projects first, then newest start year
  arrange(desc(ongoing), desc(start_year))

slugs <- paste0(projects$start_year, "-", slugify(projects$title))
check_unique_slugs(slugs, "src/content/projects")

clear_generated_folder(here("src", "content", "projects"))

# One file per project
projects |>
  mutate(slug = slugs) |>
  split(seq_len(nrow(projects))) |>
  walk(function(p) {
    period <- if (is.na(p$end_year)) {
      paste0(p$start_year, "-present")
    } else {
      paste0(p$start_year, "-", p$end_year)
    }

    write_markdown(
      here("src", "content", "projects", paste0(p$slug, ".md")),
      frontmatter = list(
        title = p$title,
        date = as.character(p$start_year),
        role = p$role,
        funder = p$funder,
        description = p$summary,
        external_url = p$url
      ),
      body = paste0("**Period:** ", period)
    )
  })
