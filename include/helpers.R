# set this to the directory you want (in environment variable)
kDataDir <- Sys.getenv("GITHUB_DATA_DIR")
if (kDataDir == "") {
  # set default data directory
  kDataDir <- "./github_data"
}

pad <- function(x, n = 4, side = "left") {
  # pad numbers for better messaging
  str_pad(x, n, side = side)
}
msg <- function(..., appendLF = TRUE) {
  cat(...)
  if (appendLF) cat("\n")
}
if (is.null(.GlobalEnv$logfile)) {
  cat_dest <- NULL
} else {
  cat_dest <- file(.GlobalEnv$logfile, "a")
}
cat <- function(...) {
  if (!is.null(cat_dest)) {
    base::cat(..., file = cat_dest)
  } else {
    base::cat(...)
  }
}

# When we need to save data as a file
fname <- function(repo, category, ext = ".csv") {
  # rename because of existing data
  # if (category == "contributors") {
  #   category = "contributions"
  # }
  dname <- file.path(kDataDir, category)
  if (!dir.exists(dname)) {
    dir.create(dname, recursive = TRUE)
  }
  file.path(dname, str_c(str_replace(repo, "/", " - "), ext))
}

parse_datetime <- function(x) {
  ifelse(
    is.null(x), NA,
    readr::parse_datetime(x) %>% format("%F %T")
  )
}

safe_val <- function(x) {
  # make sure X is not null
  # Args:
  #   x - any object
  #   p - the sub property if any
  if (is.null(x)) return(NA)
  return(x)
}