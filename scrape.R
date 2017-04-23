source("include/init.R")
source("include/helpers.R")
source("scraper/gh.R")
source("scraper/repo.R")
source("scraper/languages.R")
source("scraper/stats.R")
source("scraper/issues.R")
source("scraper/stargazers.R")

# Start Fetching Data -----------
FetchAll <- function(repos,
                     state = "all",
                     skip_existing = TRUE,
                     scrape_languages = TRUE,
                     scrape_stats = TRUE,
                     scrape_issues = TRUE,
                     scrape_issue_events = TRUE,
                     scrape_issue_comments = TRUE,
                     scrape_stargazers = TRUE, ...) {
  # Fetch issues, issue events for a list of repos
  # Args:
  #   repos - a vector of repository names
  #   skip_existing - whether to skip if repo is found in g_issues table
  # Returns:
  #  a list of logical values indicating whether scraping succeeded
  #  for each repo
  names(repos) <- repos
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
    if (scrape_languages) {
      n <- ScrapeLanguages(repo, skip_existing, ...)
      if (is.null(n)) {
        msg("(X) resource unavailable.  ")
        return(FALSE)
      } else if (n == -1) {
        cat("x lang | ")
      } else {
        cat(n, "lang | ")
      }
    }
    if (scrape_stats) {
      n <- ScrapeStats(repo, skip_existing, ...)
      if (is.null(n)) {
        msg("(X) resource unavailable.  ")
        return(FALSE)
      } else if (n == -1) {
        # -1 means data already existed
        cat("xxx w | ")
      } else {
        cat(pad(n, 3), "w | ")
      }
    }
    if (scrape_issues) {
      n <- ScrapeIssues(repo, skip_existing, ...)
      if (is.null(n)) {
        msg("(X) resource unavailable.  ")
        return(FALSE)
      } else if (n == -1) {
        cat("xxxx isu | ")
      } else {
        cat(pad(n), "isu | ")
      }
    }
    if (scrape_issue_events) {
      n <- ScrapeIssueEvents(repo, skip_existing, ...)
      if (is.null(n)) {
        msg("(X) resource unavailable.  ")
        return(FALSE)
      } else if (n == -1) {
        cat("xxxx i_e | ")
      } else {
        cat(pad(n), "i_e | ")
      }
    }
    if (scrape_issue_comments) {
      n <- ScrapeIssueComments(repo, skip_existing, ...)
      if (is.null(n)) {
        msg("(X) resource unavailable.  ")
        return(FALSE)
      } else if (n == -1) {
        cat("xxxx i_c | ")
      } else {
        cat(pad(n), "i_c | ")
      }
    }
    if (scrape_stargazers) {
      n <- ScrapeStargazers(repo, skip_existing, ...)
      if (is.null(n)) {
        msg("(X) resource unavailable.  ")
        return(FALSE)
      } else if (n == -1) {
        cat("xxxx * | ")
      } else {
        cat(pad(n), "* | ")
      }
    }
    cat("\n")
    return(TRUE)
  })
}

ScrapeAll <- function(offset = 0, perpage = 5, n_max = 100,
                      list_fun = ListRandomRepos, ...) {
  # Run queries in small batch, just in case something went wrong
  # have less issues and easier to debug.
  start <- offset + 1
  while (offset < n_max) {
    repos <- list_fun(offset, perpage) 
    if (!is_atomic(repos)) repos <- repos$repo
    if (is.null(repos) || length(repos) == 0) {
      msg("")
      msg("No more. Stop.")
      break
    }
    msg("")
    msg(sprintf("Scraping %s-%s of %s...", offset + 1, offset + perpage, n_max))
    tryCatch(
      FetchAll(repos, ...),
      error = warning
    )
    offset <- offset + perpage
  }
  msg("")
  msg(sprintf("Batch %s ~ %s Done.", start, n_max))
}
# Scrape all stats first, so to  trigger contributors calculation on GitHub
# ScrapeAll(n_max = 60000, 
#           scrape_languages = FALSE,
#           scrape_stats = TRUE,
#           scrape_issues = FALSE,
#           scrape_issue_events = FALSE,
#           scrape_issue_comments = FALSE,
#           scrape_stargazers = FALSE, verbose =TRUE)
# ScrapeAll(offset = 0, n_max = 2500)