#
# Statistics
#
ScrapeContributors <- .ScrapeAndSave("contributors", function(repo, ...) {
  dat <- gh("/repos/:repo/stats/contributors", repo = repo, ...)
  if (is.null(dat)) return()
  # return empty data frame if no data available
  if (length(dat) == 0 || is.atomic(dat)) return(data.frame())
  dat %<>%
    map(function(x) {
      if (is.atomic(x)) {
        return(NULL)
      }
      df <- bind_rows(x$weeks)
      if (!is.null(x$author)) {
        df$author <- x$author$login
      } else {
        # empty string is allowed, and will be treated as an unknown user
        df$author <- ""
      }
      df
    }) %>%
    do.call(rbind, .)
  if (ncol(dat) == 5) {
    colnames(dat) <- c("week", "additions", "deletes", "commits", "author")
    # set real number of weeks as an attribute, so we can use it for logging
    attr(dat, "real_n") <- nrow(dat) / length(unique(dat$author))
  }
  dat
})
ScrapePunchCard <- .ScrapeAndSave("punch_card", function(repo, ...) {
  dat <- gh("/repos/:repo/stats/punch_card", repo = repo, ...)
  if (is.null(dat)) return()
  # return empty data frame if no data available
  if (length(dat) == 0 || is.atomic(dat)) return(data.frame())
  dat %<>% map(as.integer) %>%
    do.call(rbind, .) %>%
    as.data.frame()
  colnames(dat) <- c("day", "hour", "commits")
  dat$repo <- repo
  dat
})

ScrapeStats <- function(repo, ...) {
  # Return: number of weeks from the punchcard
  ScrapePunchCard(repo, ...)
  ScrapeContributors(repo, ...)
}
