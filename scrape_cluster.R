# ----------------------------------------
# Parallel Scraping with `future`
# ----------------------------------------

library(future)
library(parallel)

source("scrape.R")

n_workers <- 4
# cleanup existing log files
unlink("/tmp/github-scrape-*.log")

if (exists("cl")) {
  stopCluster(cl)
} else {
  cl <- makeCluster(n_workers)
  plan(cluster, workers = cl)
}

f <- list()
cl_wait <- function(f) {
  lapply(f, FUN = function(x) {
    if (is.null(x) || !("Future" %in% class(x))) return()
    tryCatch(value(x), error = function(err) {
      message("Error at executing:")
      message(x$expr)
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
    f[[length(f) + 1]] <<- future({
      .GlobalEnv$logfile <- paste0("/tmp/github-scrape-", Sys.getpid(), ".log")
      errlog <- file("/tmp/github-scrape-error.log", "a")
      sink(errlog, append = TRUE, type = "message")
      source("scrape.R")
      ScrapeAll(offset = p_start, n_max = p_end,
                list_fun = ListRandomRepos,
                fetcher = fetcher)
    },
    globals = list(
      p_start = partition[i],
      p_end = partition[i + 1],
      fetcher = fetcher,
      n_workers = n_workers,
      # pass in two already loaded variable,
      # so child processes doesn't have to load them again
      tokens = tokens,
      available_repos = available_repos
    ),
    gc = TRUE)
    message("Queued: ", partition[i])
    if (as.numeric(Sys.time() - start_time, units = "mins") > 60) {
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
partition <- seq(0, n_total + 1, 200)

# 1. Scrape different data categories one by one
# cl_execute(FetcherOf(ScrapeRepoDetails, "stars"))
# cl_execute(FetcherOf(ScrapeLanguages, "lang"))
# cl_execute(FetcherOf(ScrapeLanguages, "lang"))
# cl_execute(FetcherOf(ScrapePunchCard, NULL))

# run though each data category at least twice, to avoid zero results
# becauses of GitHubs mssing cache
# cl_execute(FetcherOf(ScrapeContributors, "weeks"))
# cl_execute(FetcherOf(ScrapeStargazers, "stars"))
cl_execute(FetcherOf(ScrapeIssues, "issues"))
cl_execute(FetcherOf(ScrapeIssueComments, "i_cmts"))
cl_execute(FetcherOf(ScrapeIssueEvents, "i_evts"))

cl_execute(FetcherOf(ScrapeContributors, "weeks"))
cl_execute(FetcherOf(ScrapeStargazers, "stars"))
cl_execute(FetcherOf(ScrapeIssues, "issues"))
cl_execute(FetcherOf(ScrapeIssueComments, "i_cmts"))
cl_execute(FetcherOf(ScrapeIssueEvents, "i_evts"))

# 2. Or, you can chose to scrape repository one by one
# cl_excute("FetchAll")

# 3. wait until every process finishes, then cleanup the logs
cl_cleanup()