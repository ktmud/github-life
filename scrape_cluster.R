# ----------------------------------------
# Parallel Scraping with `future`
# ----------------------------------------

library(future)
library(parallel)

source("include/init.R")

n_workers <- 6
# cleanup existing log files
unlink("/tmp/github-scrape-*.log")

if (exists("cl")) {
  stopCluster(cl)
} else {
  cl <- makeCluster(n_workers)
  plan(cluster, workers = cl)
}

GenExpression <- function(i, partition, list_fun = "ListRandomRepos",
                          fetcher = "FetchAll") {
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
    if (!("Future" %in% class(x))) return()
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
    if (as.numeric(Sys.time() - start_time, units = "mins") > 60) {
      # The memory in forked R sessions seems never recycled.
      # We'd have to restart the whole cluster once in a while (every 1 hour)
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
n_total <- nrow(kAllRepos)
n_total <- 2500
partition <- seq(0, n_total + 1, 500)

# Scrape different data categories one by one
# scraping repo details will report number of stars
# cl_execute('FetcherOf(ScrapeContributors, "weeks")')
cl_execute('FetcherOf(ScrapeRepoDetails, "stars")')
cl_execute('FetcherOf(ScrapeIssues, "issues")')
cl_execute('FetcherOf(ScrapeIssueEvents, "i_evts")')
cl_execute('FetcherOf(ScrapeIssueComments, "i_cmts")')
cl_execute('FetcherOf(ScrapePunchCard, NULL)')

# Or, you can chose to scrape repository one by one
# cl_excute("FetchAll")

# must scrape contributors again because github returns empty results
# when the stats were not in their cache
cl_execute('FetcherOf(ScrapeContributors, "weeks")')

# want until every process finishes,
# then cleanup the logs
cl_cleanup()