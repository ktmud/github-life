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

GenExpression <- function(i, partition, list_fun = "ListRandomRepos") {
  parse(
    text = sprintf(
      '
      if (!exists("ScrapeAll")) {
        # dont reload if data already loaded
        .GlobalEnv$logfile <- paste0("/tmp/github-scrape-%s", ".log")
        .GlobalEnv$n_workers <- %s  # this is needed for token control
        sink("/dev/null")  # all normal messages will just go to limbo
        source("scrape.R")
      }
      ScrapeAll(offset = %s, n_max = %s, list_fun = %s, scrape_stats = TRUE)
      ',
      i %% n_workers,
      n_workers,
      partition[i],
      partition[i + 1],
      list_fun
    )
  )
  }

f <- list()
cl_cleanup <- function() {
  v <- lapply(f, FUN = function(x) if (!is.null(x)) value(x))
  Sys.sleep(5)
  stopCluster(cl)
}

n_total <- nrow(kAllRepos)
# split into small chunks to avoid being blocked by
# very large repos
partition <- seq(0, n_total + 1, 10)

start_time <- Sys.time()

for (i in seq(1, length(partition) - 1)) {
  myexp <- GenExpression(i, partition)
  # myexp <- GenExpression(i, partition, "ListPopularRepos")
  f[[i]] <- future(eval(myexp))
  message("Queued: ", partition[i])
  if (as.numeric(Sys.time() - start_time, units = "mins") > 10) {
    # The memory in forked R sessions seems never recycled.
    # We'd have to restart the whole cluster once in a while (every 10 minutes)
    # in order to keep the memory consumption under control.
    # note the restart might take a while if one of the sessions
    # were blocked by a very large repo.
    message("Restart a new cluster.. so to release some memory.")
    cl_cleanup()
    cl <- makeCluster(n_workers)
    setDefaultCluster(cl)
    start_time <- Sys.time()
  }
  # Give the process a little time to breath
  # so to avoid the `sink stack is full` error
  Sys.sleep(1)
}

cl_cleanup()

# cleanup log files
unlink("/tmp/github-scrape-*.log")
