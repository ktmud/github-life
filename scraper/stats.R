#
# Statistics
#
ScrapeContributors <- .ScrapeAndSave("contributors", function(repo, ...) {
  dat <- gh("/repos/:repo/stats/contributors", repo = repo)
  if (is.null(dat)) return()
  # return empty data frame if no data available
  if (length(dat) == 0 || is.atomic(dat)) return(data.frame())
  # the structure of the data is:
  # [{
  #   author: ...,
  #   weeks: [...]
  # }]
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
    reponame <- repo
    dat %<>%
      mutate(
        repo = reponame,
        week = parse_timestamp(w),
        total = a + d + c) %>%
      # remove unnecessary zero records
      filter(total > 0) %>%
      select(repo, week, author,
             additions = a, deletions = d, commits = c)
    # set real number of weeks as an attribute, so we can use it for logging
    attr(dat, "real_n") <- length(unique(dat$week))
  }
  dat
})
ScrapePunchCard <- .ScrapeAndSave("punch_card", function(repo, ...) {
  dat <- gh("/repos/:repo/stats/punch_card", repo = repo)
  if (is.null(dat)) return()
  # return empty data frame if no data available
  if (length(dat) == 0 || is.atomic(dat)) return(data.frame())
  dat %<>% map(as.integer) %>%
    do.call(rbind, .) %>%
    as_tibble() %>%
    # add `repo` as a column
    mutate(repo = repo) %>%
    select(repo, day = V1, hour = V2, commits = V3) %>%
    # remove unnecessary zero records
    filter(commits > 0)
  dat
})

ScrapeStats <- function(repo, ...) {
  # Return: number of weeks from the punchcard
  ScrapePunchCard(repo, ...)
  ScrapeContributors(repo, ...)
}