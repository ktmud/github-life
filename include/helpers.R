# where the `cat` output goes
if (is.null(.GlobalEnv$logfile)) {
  cat_dest <- NULL
} else {
  cat_dest <- file(.GlobalEnv$logfile, "a")
}

pad <- function(x, n = 4, side = "left") {
  # add spaces to numbers for better messaging
  str_pad(x, n, side = side)
}
cat <- function(...) {
  args <- str_c(..., collapse = " ")
  if (!is.null(cat_dest)) {
    base::cat(..., file = cat_dest)
  } else {
    base::cat(...)
  }
}
msg <- function(..., appendLF = TRUE) {
  # the different between `cat` and `msg`
  # is that `msg` by default appendLF
  args <- str_c(..., collapse = " ")
  cat(args)
  if (appendLF) cat("\n")
}
fmt <- function(...) {
  # format big numbers
  format(..., big.mark = ",")
}
parse_datetime <- function(x) {
  # use conditional comparing so x can be a vector
  if (length(x) == 0) return(NA)
  readr::parse_datetime(x) %>% format("%F %T")
}
parse_timestamp <- function(x) {
  # parse UNIX timestamp into standard date string
  if (length(x) == 0) return(NA)
  x %>% unlist() %>%
    as.integer() %>%
    as.POSIXct(origin = "1970-01-01", tz = "UTC") %>%
    format("%F %T")
}
safe_val <- function(x, fallback = NA) {
  # make sure X is not null
  # Args:
  #   x - any object
  #   p - the sub property if any
  if (is.null(x)) return(fallback)
  return(x)
}