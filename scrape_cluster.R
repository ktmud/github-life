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

clst.offset <- 0
clst.n_max <- 1000
clst.list_fun <- "ListRandomRepos"

GenExpression <- function(i, partition, list_fun = clst.list_fun) {
  parse(
    text = sprintf('
      logfile <- paste0("/tmp/github-scrape-", Sys.getpid() ,".log") 
      sink(file(logfile, open = "a"), type = "message")
      source("scrape.R")
      ScrapeAll(
        offset = %s,
        n_max = %s,
        list_fun = %s,
        scrape_stats = TRUE
      )
    ',
      partition[i],
      partition[i + 1],
      list_fun
    )
  )
}

f <- list()

# When local
n_total <- 1000
partition <- seq(0, n_total, 50)
for (i in seq(1, length(partition) - 1)) {
  myexp <- GenExpression(i, partition, "ListRandomRepos")
  f[[i]] <- future(eval(myexp))
  message("Queued: ", partition[i])
  Sys.sleep(5)
}

# split into small chunks is more efficient
# n_total <- ght$popular_projects %>% count() %>% collect() %>% .$n
# partition <- seq(0, n_total, 50)
# for (i in seq(1, length(partition) - 1)) {
#   myexp <- GenExpression(i, partition, "ListPopularRepos")
#   f[[i]] <- future(eval(myexp))
#   message("Queued: ", partition[i])
#   Sys.sleep(5)
# }

# this ensures every queue runs successfully
v <- lapply(f, FUN = value)

# Ok, we're done.
stopCluster(cl)
