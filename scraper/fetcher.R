#
# Utility functions to start fetching data.
# Also includes logics for progress reporting.
#
FetchAll <- function(repos, skip_existing = TRUE) {
  # Fetch all available data for a list of repos
  # Args:
  #   repos - a vector of repository names
  #   skip_existing - whether to skip if repo is found in g_issues table
  # Returns:
  #  a list of logical values indicating whether scraping succeeded
  #  for each repo
  walk(repos, function(repo) {
    # Begin scraping ...
    cat("$", pad(str_trunc(repo, 45), 45, "right"))
    # always scrape repo details
    n <- ScrapeRepoDetails(repo, skip_existing, ...)
    if (is.null(n)) {
      # don't scrape others if the resource is known unavailable
      cat(pad("(X) GONE .", 13), "\n")
      return(FALSE)
    } else if (n == -1) {
      # -1 means data already existed, do nothing
      cat(pad(".", 13))
    } else {
      cat(pad(n, 5), "stars .")
    }
    cat("\n  ")
    ScrapeLanguages(repo, skip_existing, "lang")
    ScrapeStats(repo, skip_existing, "w", 3)
    ScrapeIssues(repo, skip_existing, "isu")
    ScrapeIssueEvents(repo, skip_existing, "i_e")
    ScrapeIssueComments(repo, skip_existing, "i_c")
    ScrapeStargazers(repo, skip_existing, "stars")
    cat("\n")
    return(TRUE)
  })
}

FetcherOf <- function(FUN, l_name = ".", l_n = 5) {
  # Create a fetcher of a given ScrapeXXX function
  return(function(repos, skip_existing = TRUE, ...) {
    walk(repos, function(repo) {
      cat("$", pad(str_trunc(repo, 40), 40, "right"))
      FUN(repo, skip_existing, l_name, l_n, l_add_pipe = FALSE, ...)
      cat("\n")
    })
  })
}
