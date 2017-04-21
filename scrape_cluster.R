#
# Parallel Scraping with `future`
#
library(future)
library(parallel)

source("include/init.R")

if (exists("cl")) stopCluster(cl)

n_wokers <- 5
cl <- makeCluster(n_wokers)
plan(cluster, workers = cl)

GenExpression <- function(i, partition, list_fun = "ListRandomRepos") {
  parse(
    text = sprintf(
      '
      logfile <- paste0("/tmp/github-scrape-%s", ".log")
      sink(file(logfile, open = "a"), type = "message")
      source("scrape.R")
      ScrapeAll(offset = %s, n_max = %s, list_fun = %s, scrape_stats = TRUE)
      ',
      i %% n_wokers,
      partition[i],
      partition[i + 1],
      list_fun
    )
  )
}

f <- list()

# When local
# n_total <- 1000
# partition <- seq(0, n_total, 50)
# for (i in seq(1, length(partition) - 1)) {
#   myexp <- GenExpression(i, partition, "ListRandomRepos")
#   f[[i]] <- future(eval(myexp))
#   message("Queued: ", partition[i])
#   Sys.sleep(5)
# }

cl_cleanup <- function() {
  v <- lapply(f, FUN = function(x) if (!is.null(x)) value(x))
  stopCluster(cl)
  Sys.sleep(5)
}

# split into small chunks is more efficient
n_total <- nrow(kAllRepos)
# n_total <- 2000
partition <- seq(0, n_total + 1, 50)
for (i in seq(1, length(partition) - 1)) {
  myexp <- GenExpression(i, partition)
  # myexp <- GenExpression(i, partition, "ListPopularRepos")
  f[[i]] <- future(eval(myexp))
  message("Queued: ", partition[i])
  if (i %% (n_wokers * 2) == 0) {
    # The memory in forked R sessions seems never recycled.
    # We'd have to restart the whole cluster once in a while (every 2 rounds)
    # in order to keep the memory consumption under control.
    message("Restart a new cluster.. so to release some memory.")
    cl_cleanup()
    cl <- makeCluster(n_wokers)
    setDefaultCluster(cl)
  }
  Sys.sleep(2)
}

cl_cleanup()

# cleanup old log files
unlink("/tmp/github-scrape-*.log")