#
# Scrape Commits

CreateCommitsTables <- function() {
  dbGetQuery(db$con, sql("DROP TABLE IF EXISTS `ghtorrent_restore`.`g_commits`"))
  dbGetQuery(db$con, sql("DROP TABLE IF EXISTS `ghtorrent_restore`.`g_commit_parents`"))
}

ScrapeCommits <- function(repo, ...) {
  # Scrape issues of all repo
  res <- gh(str_c("/repos/", repo, "/commits"), ...)
  
  if (length(res) == 0 || is.null(names(res[[1]]))) {
    # return an empty data frame if no data available
    return(data.frame())
  }
}
