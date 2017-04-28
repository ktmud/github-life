# ----------------------------------------
# Parallel Scraping with `future`
# ----------------------------------------

library(future)
library(parallel)

source("include/init.R")

n_workers <- 4
# cleanup existing log files
unlink("/tmp/github-scrape-*.log")

if (exists("cl")) {
  stopCluster(cl)
} else {
  cl <- makeCluster(n_workers)
  plan(cluster, workers = cl)
}

GenExpression <- function(i, partition, fetcher = "FetchAll") {
  list_fun <- "ListRandomRepos"
  # list_fun <- "ListNotScrapedRepos"
  parse(
    text = sprintf(
      'if (!exists("ScrapeAll")) {
        # dont reload if data already loaded
        .GlobalEnv$logfile <- paste0("/tmp/github-scrape-", Sys.getpid(), ".log")
        .GlobalEnv$n_workers <- %s  # this is needed for token control
        # sink("/dev/null")  # all normal messages go to limbo
        source("scrape.R")
      }
      ScrapeAll(offset = %s, n_max = %s, list_fun = %s, fetcher = %s)
      ',
      n_workers,
      partition[i],
      partition[i + 1],
      list_fun,
      fetcher
    )
  )
}

f <- list()
cl_wait <- function(f) {
  lapply(f, FUN = function(x) {
    if (is.null(x) || !("Future" %in% class(x))) return()
    tryCatch(value(x), error = function(err) {
      message("Error at executing:")
      message(x$globals$myexp)
      message(err)
    })
  })
}
cl_cleanup <- function(.f = f) {
  cl_wait(.f)
  unlink("/tmp/github-scrape-*.log")
}

cl_execute <- function(fetcher) {
  start_time <- Sys.time()
  for (i in seq(1, length(partition) - 1)) {
    myexp <- GenExpression(i, partition, fetcher = fetcher)
    # this .GlobalEnv is actually the env of the child process
    f[[length(f) + 1]] <<- future(eval(myexp, envir = .GlobalEnv))
    message("Queued: ", partition[i])
    if (as.numeric(Sys.time() - start_time, units = "mins") > 15) {
      # The memory in forked R sessions seems never recycled.
      # We'd have to restart the whole cluster once in a while
      # in order to keep the memory consumption under control.
      # note such restart might take a while if one of the sessions
      # were blocked by a very large repo.
      message("Restarting the cluster.. so to release some memory.")
      cl_cleanup()
      stopCluster(cl)
      cl <- makeCluster(n_workers)
      setDefaultCluster(cl)
      start_time <- Sys.time()
    }
    # Give the process a little time to breath
    # so to avoid the `sink stack is full` error
    # Sys.sleep(1)
  }
  return()
}

# change this `n_total` for a smaller sample
# nonexisting <- ListNotScrapedRepos(limit = 50000)
# n_total <- nrow(nonexisting)
n_total <- nrow(available_repos)
partition <- seq(0, n_total + 1, 500)

# 1. Scrape different data categories one by one
# go through though each data category at least twice,
# so to eleminate zero results from GitHub's missing cache
cl_execute('FetcherOf(ScrapeRepoDetails, "stars")')
cl_execute('FetcherOf(ScrapeRepoDetails, "stars")')
cl_execute('FetcherOf(ScrapeLanguages, "lang")')
cl_execute('FetcherOf(ScrapeLanguages, "lang")')
cl_execute('FetcherOf(ScrapePunchCard, NULL)')
cl_execute('FetcherOf(ScrapePunchCard, NULL)')
cl_execute('FetcherOf(ScrapeContributors, "weeks")')
cl_execute('FetcherOf(ScrapeContributors, "weeks")')
cl_execute('FetcherOf(ScrapeStargazers, "stars")')
cl_execute('FetcherOf(ScrapeStargazers, "stars")')
cl_execute('FetcherOf(ScrapeIssues, "issues")')
cl_execute('FetcherOf(ScrapeIssues, "issues")')
cl_execute('FetcherOf(ScrapeIssueEvents, "i_evts")')
cl_execute('FetcherOf(ScrapeIssueEvents, "i_evts")')
cl_execute('FetcherOf(ScrapeIssueComments, "i_cmts")')
cl_execute('FetcherOf(ScrapeIssueComments, "i_cmts")')

# 2. Or, you can chose to scrape repository one by one
# cl_excute("FetchAll")

# 3. wait until every process finishes, then cleanup the logs
cl_cleanup()