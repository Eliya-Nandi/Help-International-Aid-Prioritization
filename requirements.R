# Required R packages for HELP International aid prioritization project

packages <- c(
  "tidyverse",
  "skimr",
  "ggcorrplot",
  "factoextra",
  "cluster",
  "knitr",
  "rmarkdown",
  "keras3"
)

installed <- rownames(installed.packages())
missing <- packages[!packages %in% installed]

if (length(missing) > 0) {
  install.packages(missing)
}

cat("All required packages are installed.\n")
