#
# Parallel Scraping with `future`
#
library(future)
library(parallel)

source("include/init.R")

cl <- makeCluster(6)
plan(cluster, workers = cl)

# cleanup old log files
unlink("/tmp/github-scrape-*.log")

GenExpression <- function(i, partition,
                          list_fun = "ListPopularRepos",
                          scrape_stats = TRUE) {
  parse(
    text = sprintf('
      source("scrape.R")
      sink(
        file(str_c("/tmp/github-scrape-", Sys.getpid() ,".log"), open = "a"),
        type = "message"
      )
      ScrapeAll(offset = %s, n_max = %s, list_fun = %s, scrape_stats = %s)',
      partition[i],
      partition[i + 1],
      list_fun, scrape_stats
    )
  )
}

f <- list()
n_total <- ght$popular_projects %>% count() %>% collect() %>% .$n

# split into small chunks is more efficient
partition <- seq(0, n_total, 50)
f <- list()
for (i in seq(1, length(partition) - 1)) {
  myexp <- GenExpression(i, partition)
  f[[i]] <- future(eval(myexp))
  message("Queued: ", partition[i])
  Sys.sleep(5)
}

# this ensures every queue runs successfully
v <- lapply(f, FUN = value)

# Ok, we're done.
stopCluster(cl)