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
  if (length(dat) == 0 || is.atomic(dat)) return(data.frame())
  dat %>%
    map(function(x) {
      c(repo = repo,
        starred_at = x$starred_at,
        user_id = x$user$id, 
        # also save `login` for easier table joins
        user_login = safe_val(x$user$login))
    }) %>%
    do.call(rbind, .) %>%
    as.data.frame() %>%
    distinct(user_id, .keep_all = TRUE)
})