# When we need to save data as a file
fname <- function(repo, category, ext = "csv") {
  # rename because of existing data
  # if (category == "contributors") {
  #   category = "contributions"
  # }
  dname <- str_c(kDataDir, category)
  if (!dir.exists(dname)) {
    dir.create(dname, recursive = TRUE)
  }
  str_c(dname, "/", str_replace(repo, "/", " - "), ".", ext)
}

parse_datetime <- function(x) {
  ifelse(
    is.null(x), NA,
    readr::parse_datetime(x) %>% format("%F %T")
  )
}

safe_val <- function(x) {
  # make sure not NULL value is passed to a vector
  ifelse(is.null(x), NA, x)
}

