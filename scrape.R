source("include/init.R")
source("include/helpers.R")
source("include/db.R")
source("include/scraper/gh.R")
source("include/scraper/stats.R")
source("include/scraper/issues.R")
source("include/scraper/stargazers.R")

pad <- function(x, n = 4, side = "left") {
  # pad numbers for better messaging
  str_pad(x, n, side = side)
}
msg <- function(x, ..., appendLF = FALSE) {
  message(x, ..., appendLF = appendLF)
}
  
# Start Fetching Data -----------
FetchAll <- function(repos,
                     state = "all",
                     skip_existing = TRUE,
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
    msg(pad(str_trunc(repo, 28), 30, side = "right"))
    if (scrape_stats) {
      n <- ScrapeStats(repo, skip_existing)
      if (is.null(n)) {
        msg("(X) resource unavailable.  ", appendLF = TRUE)
        # don't scrape others if the resource is known unavailable
        return(FALSE)
      } else if (n == -1) {
        # -1 means data already existed
        msg("xxx w   ")
      } else {
        msg(pad(n, 3), " w  ")
      }
    }
    if (scrape_issues) {
      n <- ScrapeIssues(repo, skip_existing)
      if (is.null(n)) {
        msg("(X) resource unavailable.  ", appendLF = TRUE)
        return(FALSE)
      } else if (n == -1) {
        msg("xxxx isu  ")
      } else {
        msg(pad(n), " isu  ")
      }
    }
    if (scrape_issue_events) {
      n <- ScrapeIssueEvents(repo, skip_existing)
      if (is.null(n)) {
        msg("(X) resource unavailable.  ", appendLF = TRUE)
        return(FALSE)
      } else if (n == -1) {
        msg("xxxx i_evt  ")
      } else {
        msg(pad(n), " i_evt  ")
      }
    }
    if (scrape_issue_comments) {
      n <- ScrapeIssueComments(repo, skip_existing)
      if (is.null(n)) {
        msg(" (X) resource unavailable.  ", appendLF = TRUE)
        return(FALSE)
      } else if (n == -1) {
        msg("xxxx i_cmt  ")
      } else {
        msg(pad(n), " i_cmt  ")
      }
    }
    if (scrape_stargazers) {
      n <- ScrapeStargazers(repo, skip_existing)
      if (is.null(n)) {
        msg(" (X) resource unavailable.  ", appendLF = TRUE)
        return(FALSE)
      } else if (n == -1) {
        msg("xxxx stars  ")
      } else {
        msg(pad(n), " stars  ")
      }
    }
    message("OK.")
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
    if (!is_atomic(repos)) {
      repos <- repos$repo
    }
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
ScrapeAll(n_max = 10)