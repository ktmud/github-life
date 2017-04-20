#
# Statistics
#
ScrapeStats <- function(repo, save_users = FALSE,
                        skip_existing = TRUE, ...) {
  file_path <- fname(repo, "contributions")
  fsize <- file.size(file_path)
  # will retry statistics of file size zero
  # GitHub says statistics are generated asynchroneously
  if (skip_existing && !is.na(fsize) && fsize != 0) {
    return(NULL)
  }
  contributors <- gh("/repos/:repo/stats/contributors", repo = repo)
  if (is.null(contributors)) {
    return(FALSE)
  }
  if (save_users) {
    SaveUsers(map(contributors, function(x) x$author))
  }
  contributions <- contributors %>%
    map(function(x) {
      if (is.atomic(x)) {
        return(NULL)
      }
      df <- bind_rows(x$weeks)
      if (!is.null(x$author)) {
        df$author_login <- x$author$login
      }
      df
    }) %>% bind_rows()
  
  write_csv(contributions, file_path)
  return(TRUE)
}

# ScrapeStats("twbs/bootstrap")