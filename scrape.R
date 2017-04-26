source("include/init.R")

source("scraper/gh.R")
source("scraper/repo.R")
source("scraper/languages.R")
source("scraper/stats.R")
source("scraper/issues.R")
source("scraper/stargazers.R")
source("scraper/fetcher.R")

# Start Fetching Data -----------
ScrapeAll <- function(offset = 0, perpage = 5, n_max = 100,
                      list_fun = ListRandomRepos,
                      fetcher = FetchAll, ...) {
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
    fetcher(repos, ...)
    offset <- offset + perpage
  }
  msg("")
  msg(sprintf("Batch %s ~ %s Done.", start, n_max))
}

# ScrapeAll(n_max = 2500, fetcher = FetcherOf(ScrapeLanguages))
# ScrapeAll(n_max = 2500, fetcher = FetcherOf(ScrapeContributors))
# ScrapeAll(n_max = 2500, fetcher = FetcherOf(ScrapeRepoDetails, "stars"))
# ScrapeAll(n_max = 2500, fetcher = FetcherOf(ScrapePunchCard, NULL))
# ScrapeAll(n_max = 2500, fetcher = FetcherOf(ScrapeIssues, "issues"), skip_existing = FALSE)
# ScrapeAll(n_max = 2500, fetcher = FetcherOf(ScrapeIssueEvents, "i_evts"))
# ScrapeAll(n_max = 2500, fetcher = FetcherOf(ScrapeIssueComments, "i_cmts"))
# ScrapeAll(offset = 0, n_max = 2500)
