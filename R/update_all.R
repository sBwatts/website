# Runs every data update in order. Run from anywhere:
#   Rscript R/update_all.R
#
# After it finishes, preview with `npm run dev` and commit src/data/ with your changes.

source(here::here("R", "update_cv.R"))
source(here::here("R", "update_projects.R"))
source(here::here("R", "update_publications.R"))

message("All data files updated. Preview the site with: npm run dev")
