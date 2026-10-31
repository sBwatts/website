# Academic website

A personal academic website built on the [academic-portfolio-astro](https://github.com/rubzip/academic-portfolio-astro) theme (MIT). R scripts generate the content (bio, CV, publications, projects) from source files in `data-raw/`, and Astro builds the site.

## Layout

```
data-raw/                     Source files you edit
  cv.yml                      Name, bio, appointments, education, awards, service
  projects.csv                One row per project
  publications_manual.csv     Works OpenAlex misses (chapters, reports, etc.)
  config.yml                  ORCID and excluded DOIs

R/                            Data scripts. Run these; they write Markdown into src/content/
  update_all.R                Runs everything
  update_cv.R                 -> src/content/bio.md, src/content/cv.md
  update_projects.R           -> src/content/projects/*.md (regenerated each run)
  update_publications.R       -> src/content/publications/*.md (regenerated each run)
  openalex.R, utils.R         Helper functions

src/
  content/                    Markdown content. bio.md and cv.md are generated;
                              projects/ and publications/ are regenerated on every run.
                              Blog, talks, and teaching folders are empty and disabled.
  config/                     Site settings (see "Customizing" below)
  components/, layouts/, pages/, styles/, utils/   Theme code. Edit only if you need to.

public/                       Static files: favicon, headshot, CV PDF
```

## Updating the site

1. Edit a source file in `data-raw/`.
2. Run the R scripts from the project root:
   ```sh
   Rscript R/update_all.R
   ```
   Or run one script, for example `Rscript R/update_projects.R`.
3. Preview locally with `npm run dev`, then open http://localhost:4321.
4. Commit and push. GitHub Actions builds and deploys the site.

Don't edit the files in `src/content/publications/` or `src/content/projects/` by hand. They are overwritten on each run. Make changes in `data-raw/` instead.

## First-time setup

1. **Install Node.js 22.12 or newer**, then install the site's dependencies:
   ```sh
   npm install
   ```
2. **Install the R packages** (one time):
   ```r
   install.packages(c("here", "yaml", "readr", "dplyr", "purrr", "stringr", "tibble", "httr2"))
   ```
   Requires R 4.4 or newer.
3. **Publications:** add your ORCID iD to `data-raw/config.yml`. OpenAlex then supplies your works automatically. Add anything it misses to `data-raw/publications_manual.csv`.
4. **Profile and CV:** fill in `data-raw/cv.yml`, starting with the `person` block.
5. **Headshot:** put your photo in `public/images/` and set `person.avatar` in `cv.yml`, for example `images/headshot.jpg`.
6. **Domain:** set `site` in `astro.config.mjs` and `SITE.website` in `src/config/site.ts` to your domain.
7. **GitHub:** push the project to a GitHub repo. Then in Settings > Pages, set Source to "GitHub Actions."

## Customizing

| File | What it controls |
| :--- | :--- |
| `src/config/site.ts` | Site name, author, description, default theme colors, analytics IDs |
| `src/config/pages.ts` | Section titles, subtitles, and which sections are turned on |
| `src/config/navigation.ts` | Top navigation links. Set `isActive: true` to show Talks, Teaching, Blog, or Tags |
| `src/config/social.ts` | Email, ORCID, and Google Scholar links in the sidebar and footer |
| `src/config/themes.ts` | Color palettes. Pick names in `THEME_CONFIG` in `site.ts` |
| `src/styles/global.css` | Global styles |

## Notes

- **OpenAlex API key (optional).** Without a key, OpenAlex shares a small free daily budget across all users on your network. For reliable runs, get a free key at openalex.org and put `OPENALEX_API_KEY=your-key` in a `.Renviron` file in the project root. The file is git-ignored.
- **Projects.** Leave `end_year` blank for ongoing projects. The theme lists projects by start year, newest first.
- **CV sections.** Experience and education become timelines on the CV page. Any other section in `cv.yml` becomes a list in the body of the CV page.
- **Excluding a work.** If OpenAlex attributes a paper to you by mistake, add its DOI to `exclude_dois` in `config.yml`.
- **Duplicates.** Works are matched by DOI, or by title when there is no DOI. A manual entry overrides the OpenAlex entry.
- **Stale content after a change.** If the site shows old content, delete `node_modules/.astro` and rebuild. Astro caches content there.
- **Build warnings.** The build prints "collection ... does not exist or is empty" for disabled sections (talks, teaching, blog). They don't cause a failure.
- **Theme credit.** Keep the theme's `LICENSE` file, which is required by the MIT license. Its `AGENTS.md` and `DESIGN-GUIDE.md` describe the theme's conventions.
