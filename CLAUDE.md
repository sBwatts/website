# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

- `npm install` once, then `npm run dev` for the local site at http://localhost:4321
- `npm run build` for a production build into `dist/`. Run this before reporting a change as done, since there are no lint, typecheck, or test scripts.
- `npm run preview` serves the built `dist/`
- Regenerate content from the R pipeline, run from the project root (the `.here` file marks the root):
  - `Rscript R/update_all.R` runs everything
  - `Rscript R/update_publications.R`, `R/update_projects.R`, or `R/update_cv.R` runs one part
- R 4.4 or newer. Packages: here, yaml, readr, dplyr, purrr, stringr, tibble, httr2, jsonlite (httr2 needs it for `resp_body_json()`).

## Architecture

The site has two halves that meet at the Markdown files in `src/content/`.

**1. R pipeline (writes content).** Sources in `data-raw/` are the only files to edit:
- `cv.yml` feeds `src/content/bio.md` and `src/content/cv.md`.
- `projects.csv` feeds `src/content/projects/*.md`.
- `config.yml` holds the ORCID, the DOI list, preprint rules, and exclusions.
- `publications_manual.csv` adds works that have no DOI or that Crossref misses.

`src/content/publications/` and `src/content/projects/` are wiped and rewritten on every run. Do not hand-edit those files; change the sources instead. `R/utils.R` writes the Markdown frontmatter. It writes logical values as `true` and `false`, because the `yaml` package's default `yes`/`no` breaks Astro's schema.

**Publication data flow** (`R/update_publications.R`, with `R/crossref.R`):
- Crossref is the only source. Works are found by ORCID and by each DOI in the config. Do not add OpenAlex; the user has rejected it as a source because it misattributes and misses his articles. `R/openalex.R` is no longer sourced.
- `is_preprint` is true for Crossref type `preprint`, for CrimRxiv (`10.21428`) and OSF (`10.31219`) DOIs, and for DOIs in `preprint_dois`. Crossref often types CrimRxiv items as `journal-article`, so the DOI prefix check is required.
- A preprint is dropped when it has the same normalized title as a journal or book version, or when Crossref links the two. A DOI listed in `preprint_dois` is kept regardless.
- Category: `Preprint`, `Reports and Briefings` (venue is Applied Police Briefings), or `Publication`.
- `preprint_pairs` gives a journal entry a CrimRxiv link. Abstracts come from Crossref; open access is inferred from a Creative Commons license URL.
- Filenames are `year-slug`, with a `-preprint` suffix for preprints. A missing year becomes `forthcoming`.

**2. Astro theme (renders content).** `academic-portfolio-astro` (MIT) with changes:
- `src/content.config.ts` defines the collections and their frontmatter schema. A new frontmatter field needs three changes: the schema, the R writer, and the component that displays it.
- Site configuration lives in `src/config/`: `site.ts` (identity, theme names, analytics), `pages.ts` (titles, `isActive` per section), `navigation.ts`, `social.ts`, `themes.ts` (palettes). Blog, talks, teaching, and tags are turned off with `isActive: false`. Their folders are kept with `.gitkeep`.
- Listings share `src/utils/adapters.ts` (`getListingItem`) and `src/components/ui/BaseItemCard.astro`. The publications page (`src/pages/publications/index.astro`) is custom: it defines the tab categories, filters with a small inline script, and passes extra props to the card.
- `BaseItemCard` has an inline script that toggles abstracts. It guards against a second listener after Astro page navigations.
- `CrimRxivCard.astro` is the orange CrimRxiv link. The DOI link on journal entries uses the accent style. Both share base classes so they match in size.
- `astro.config.mjs` holds the `site` domain. Set `base` only for a project repo.

## Design system

Read `src/styles/global.css` before changing visuals. The rules below come from the theme's design guide.

- **No `<style>` blocks in `.astro` files.** Use the classes in `global.css` or Tailwind utilities in the markup.
- **Tailwind CSS v4** via `@tailwindcss/vite`. There is no `tailwind.config.js`. Color tokens are defined in `@theme` in `global.css` and map to CSS variables (`--background`, `--foreground`, `--accent`, `--border`, `--text-muted`, `--surface`).
- **Palettes:** `BaseLayout.astro` writes the variables from `THEMES` in `themes.ts`. `THEME_CONFIG` in `site.ts` picks the light and dark palettes. Dark mode follows `prefers-color-scheme`, with a manual override on `data-theme`.
- **Class system** in `global.css`:
  - Typography: `title-xl`, `title-lg`, `title-md`, `body`, `body-sm`, `body-xs`, `mono`
  - Layout: `container-narrow` (800px), `space-y-1` to `space-y-4`, `gap-1` to `gap-4`
  - Components: `card`, `card-title`, `card-meta`, `card-desc`, `card-link`, `btn`, `btn-sm`, `btn-icon`, `icon-btn`, `social-link`, `link`
  - Shell: `sidebar` (280px, sticky), `navbar`, `nav-links`, `main-content`, `main-body`, `footer`
  - Prose: `.prose` for Markdown bodies, with accent list markers and bordered code blocks
- The design guide describes `card` as having a bottom border. The current `global.css` gives it only padding, so trust the CSS.
- Avoid `Tag.astro` on new listings. It links to `/tags/…`, which is disabled.
- Math renders through remark-math and rehype-katex.

## Working notes

- Publication categories and rules are defined in the R script and the config. Changes to what counts as a preprint or a report belong in `config.yml` or `update_publications.R`, not in the page.
- `npm run build` passing is the check for Astro changes. A successful R run writes the content, and a clean build with the schema matching the frontmatter confirms it.
