##
# Scrape repo details
#
ScrapeRepoDetails <- .ScrapeAndSave("repo", function(repo, ...) {
  # Scrape all issues of a repo
  dat <- gh("/repos/:repo", repo = repo, ...)
  if (is.null(dat)) return()
  # return empty data frame if no data available
  if (length(dat) == 0 || is.atomic(dat)) return(data.frame())
  x <- dat
  ret <- c(
    id = x$id,
    owner_id = safe_val(x$owner$id),
    owner_login = safe_val(x$owner$login),
    name = safe_val(x$name),
    lang = safe_val(x$language),
    forks_count = safe_val(x$forks_count, 0),
    stargazers_count = safe_val(x$stargazers_count, 0),
    size = safe_val(x$size, 0),
    created_at = parse_datetime(x$created_at),
    updated_at = parse_datetime(x$updated_at),
    pushed_at = parse_datetime(x$pushed_at),
    # parent_id = safe_val(x$parent$id),
    # source_id = safe_val(x$source$id),
    description = safe_val(x$description)
  ) %>% t() %>%
    # always return a data frame
    as.data.frame()
  # the `real_n` is for logging purpose
  # report number of stars to downstream functions
  attr(ret, "real_n") <- x$stargazers_count
  ret
})