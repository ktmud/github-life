#
# Parallel Scraping with `future`
#
library(future)
library(parallel)

source("include/init.R")

n_workers <- 6

if (exists("cl")) {
  stopCluster(cl)
} else {
  cl <- makeCluster(n_workers)
  plan(cluster, workers = cl)
}

# cleanup log files
unlink("/tmp/github-scrape-*.log")

GenExpression <- function(i, partition, list_fun = "ListRandomRepos") {
  parse(
    text = sprintf(
      'if (!exists("ScrapeAll")) {
        # dont reload if data already loaded
        .GlobalEnv$logfile <- paste0("/tmp/github-scrape-", Sys.getpid(), ".log")
        .GlobalEnv$n_workers <- %s  # this is needed for token control
        # sink("/dev/null")  # all normal messages go to limbo
        source("scrape.R")
      }
      ScrapeAll(offset = %s, n_max = %s, list_fun = %s, verbose = TRUE)
      ',
      n_workers,
      partition[i],
      partition[i + 1],
      list_fun
    )
  )
  }

f <- list()
cl_cleanup <- function() {
  v <- lapply(f, FUN = function(x) {
    if (is.null(x)) return()
    tryCatch(value(x), error = function(err) {
      message("Error at executing:")
      message(x$globals$myexp)
      message(err)
    })
  })
}

n_total <- nrow(kAllRepos)
partition <- seq(0, n_total + 1, 100)

start_time <- Sys.time()

for (i in seq(1, length(partition) - 1)) {
  myexp <- GenExpression(i, partition)
  # myexp <- GenExpression(i, partition, "ListPopularRepos")
  f[[i]] <- future(eval(myexp))
  message("Queued: ", partition[i])
  if (as.numeric(Sys.time() - start_time, units = "mins") > 30) {
    # The memory in forked R sessions seems never recycled.
    # We'd have to restart the whole cluster once in a while (every 20 minutes)
    # in order to keep the memory consumption under control.
    # note the restart might take a while if one of the sessions
    # were blocked by a very large repo.
    message("Restarting a new cluster.. so to release some memory.")
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
cl_cleanup()