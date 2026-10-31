# Builds two theme content files from data-raw/cv.yml:
#   src/content/bio.md  (name, sidebar text, and the About page)
#   src/content/cv.md   (experience and education timelines, plus other sections in the body)

source(here::here("R", "utils.R"))

cv <- yaml::read_yaml(here("data-raw", "cv.yml"))
person <- cv$person

# Catch common mistakes here, so they don't show up as a broken page later
stopifnot(
  "cv.yml needs person: name" = !is.null(person$name),
  "each cv.yml section needs a title and entries" =
    all(map_lgl(cv$sections, \(s) !is.null(s$title) && !is.null(s$entries)))
)

# Format one CV entry as a Markdown bullet, dropping any blank parts
entry_line <- function(e) {
  parts <- c(e$primary, e$secondary, e$date, e$detail)
  parts <- parts[!is.na(parts) & nzchar(parts)]
  paste0("- ", paste(parts, collapse = ", "))
}

# Format one CV section as a heading followed by a bullet list
format_section <- function(section) {
  if (length(section$entries) == 0) return(character(0))
  c(paste0("## ", section$title), "", map_chr(section$entries, entry_line), "")
}

# 1. Bio: name, avatar, and sidebar text come from frontmatter. The About page uses the body.
write_markdown(
  here("src", "content", "bio.md"),
  frontmatter = list(
    name = person$name,
    avatar = person$avatar,
    shortBio = person$short_bio,
    institution = paste(person$department, person$university, sep = ", ")
  ),
  body = person$summary
)

# 2. CV: experience and education are timelines in frontmatter.
#    Every other section is written into the body as a Markdown list.
cv_body <- c(
  if (!is_blank(person$pdf_url)) paste0("[Download PDF](", person$pdf_url, ")"),
  "",
  unlist(map(cv$sections, format_section))
)

write_markdown(
  here("src", "content", "cv.md"),
  frontmatter = list(
    name = person$name,
    title = person$title,
    experience = cv$experience,
    education = cv$education
  ),
  body = paste(cv_body, collapse = "\n")
)
