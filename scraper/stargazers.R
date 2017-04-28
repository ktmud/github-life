#
# Scrape stargazers and when did they starred
#
ScrapeStargazers <- .ScrapeAndSave("stargazers", function(repo, ...) {
  # Scrape all issues of a repo
  dat <- gh("/repos/:repo/stargazers", repo = repo,
            .send_headers = c("Accept" = "application/vnd.github.v3.star+json"),
            ...)
  if (is.null(dat)) return()
  # return empty data frame if no data available
  if (is.atomic(dat) || length(dat) == 0) return(data.frame())
  dat %<>%
    map(function(x) {
      c(
        repo = repo,
        user_id = safe_val(x$user$id, 0),
        starred_at = parse_datetime(x$starred_at)
      )
    }) %>%
    do.call(rbind, .) %>%
    as_tibble() %>%
    distinct(user_id, .keep_all = TRUE)
  dat
})