source("include/init.R")
source("include/helpers.R")
source("include/db.R")
source("include/scraper/gh.R")
source("include/scraper/issues.R")
source("include/scraper/stats.R")

# Start Fetching Data -----------
FetchAll <- function(repos,
                     state = "all",
                     skip_existing = TRUE,
                     scrape_issue_events = TRUE,
                     scrape_issues = TRUE,
                     scrape_stats = do_scrape_stats,
                     ...) {
  # Fetch issues, issue events for a list of repos
  # Args:
  #   repos - a vector of repository names
  #   skip_existing - whether to skip if repo is found in g_issues table
  # Returns:
  #  a list of logical values indicating whether scraping succeeded
  #  for each repo
  names(repos) <- repos
  
  walk(repos, function(repo) {
    message(str_pad(str_trunc(repo, 28), 32, side = "right"), appendLF = FALSE)
    if (scrape_stats) {
      stats_ret <- ScrapeStats(repo, skip_existing = skip_existing)
      if (is.null(stats_ret)) {
        message(" stats pass", appendLF = FALSE)
      } else if (stats_ret == FALSE) {
        message(" (X) resource unavailable.")
        return(FALSE)
      } else {
        message(" stats OK", appendLF = FALSE)
      }
    }
    
    if (!scrape_issues) {
      # do nothing is not scrape issues
    } else if (skip_existing && RepoExists(repo, "g_issues")) {
      message("\t XXX issues", appendLF = FALSE)
    } else {
      issues <- ScrapeIssues(repo, state = state, ...)
      if (is.null(issues)) {
        message("Error: repo deleted or blocked.")
        return(FALSE)
      }
      n <- nrow(issues)
      if (n == 0 && state == "all") {
        # No need to proceed if there were no issues at all.
        message("\t   0 issues \tOK.")
        return(TRUE)
      }
      message("\t ", str_pad(n, 3, side = "left"), " issues", appendLF = FALSE)
      if (n > 0) {
        SaveToTable("g_issues", issues)
      }
    }
    
    if (!scrape_issue_events) {
      # do nothing is dont need to scrape events
    } else if (skip_existing && RepoExists(repo, "g_issue_events")) {
      message("\t XXXX issue_events", appendLF = FALSE)
    } else {
      issue_events <- ScrapeIssueEvents(repo, state = state, ...)
      n <- nrow(issue_events)
      message("\t ", str_pad(n, 4, side = "left"), " issue_events", appendLF = FALSE)
      if (n > 0) {
        SaveToTable("g_issue_events", issue_events)
      }
    }
    message("  OK.")
    return(TRUE)
  })
}

ScrapeAll <- function(offset = 0, perpage = 5, n_max = 100,
                      list_fun = ListPopularRepos, ...) {
  # Run queries in small batch, just in case something went wrong
  # have less issues and easier to debug.
  start <- offset + 1
  while (offset < n_max) {
    repos <- list_fun(offset, perpage) 
    if (is.null(repos) || length(repos) == 0) {
      message("")
      message("No more. Stop.")
      break
    }
    message("")
    message(sprintf("Scraping %s-%s of %s...", offset + 1, offset + perpage, n_max))
    FetchAll(repos, ...)
    offset <- offset + perpage
  }
  message("")
  message(sprintf("Batch %s ~ %s Done.", start, n_max))
}

ScrapeAll(
  offset = clst.offset,
  n_max = clst.n_max,
  list_fun = clst.list_fun,
  scrape_stats = TRUE
)