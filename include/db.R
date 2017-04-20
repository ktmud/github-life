# this version of this function was used before
# I put a `repo` column for every table
RepoExists.old <- function(fullname, tname = "g_issues") {
  # Check whether a repo exists in a Github data table
  res <- dbGetQuery(db$con, sprintf(
    "SELECT id as issue_id, repo FROM g_issues
    WHERE repo = %s 
    -- state is either `closed` or `open`
    -- `closed` issues must have a `close` event
    -- if not closed issues found, the oldest repo first
    ORDER BY `state` ASC, `created_at` ASC
    LIMIT 1",
    dbQuoteString(db$con, fullname)
  ))
  if (nrow(res) == 1 && tname != "g_issues") {
    # if other tables, filter by `issue_id` column
    # TODO: might want to use `repo_id` instead
    res <- dbGetQuery(db$con, sprintf(
      "SELECT issue_id FROM %s WHERE issue_id = %s LIMIT 1",
      dbQuoteIdentifier(db$con, tname), res$issue_id[1]
    ))
  }
  nrow(res) == 1
}

RepoExists <- function(fullname, in_table = "g_issues") {
  # Check whether repo existed locally
  res <- dbGetQuery(db$con, sprintf(
    "SELECT 1 FROM %s WHERE repo = %s LIMIT 1",
    dbQuoteIdentifier(db$con, in_table), fullname
  ))
  nrow(res) == 1
}
  
SaveToTable <- function(name, value, id_field = "id", retry_count = 0) {
  # remove existing data then save the latest data to database
  # Args:
  #   name - the name of a table
  #   value - the values in a data frame, must have a `id` column
  # Return: whether writeTable succeed.
  if (nrow(value) < 1) return(TRUE)
  
  last_value <<- value
  ids <- value$id
  name_q <- dbQuoteIdentifier(db$con, name)
  id_field_q <- dbQuoteIdentifier(db$con, id_field)
  dbExecute(db$con, sprintf("DELETE FROM %s WHERE %s IN(%s)",
                            name_q, id_field_q,
                            str_c(ids, collapse = ", ")))
  tryCatch({
    dbWriteTable(db$con, name, value, append = TRUE)
  }, error = function(e) {
    if (retry_count > 2) {
      # have already retried two times
      message(e)
    } else {
      # try one more time
      SaveToTable(name, value, id_field, retry_count + 1)
    }
  })
  return(TRUE)
}

# === For checking of data integerity --------------------
ListPopularRepos <- function(offset = 0, limit = 5, order = TRUE) {
  # List the Top N most popular repos
  # Args:
  #   offset - skip how many repos
  res <- dbGetQuery(db$con, sprintf(
    "
    SELECT `repo`, `n_watchers` FROM `popular_projects` %s
    LIMIT %s OFFSET %s
    ",
    ifelse(order, "ORDER BY `n_watchers`", ""),
    limit, offset
  ))
  res$repo
}

ListRandomRepos <- function(offset = 0, limit = 5, seed = 1984) {
  # List randome repos, helpful when we only want to 
  # scrape a small sample
  # Args:
  #  seed - the seed for randomize the sample
  
  # get 50,000 popular repos, although the actual total
  # number is just 36,000 somthing
  all_repos <- ListPopularRepos(limit = 50000, order = FALSE)
  set.seed(seed)
  # shuffle the order based on the `seed`
  all_repos <- sample(all_repos)
  all_repos[(offset+1):(offset+limit)]
}

ListNoIssueRepos <- function(offset = 0, limit = 5, .fresh = FALSE) {
  # List repos that has no issues at all
  tname <- "bad_repos_1"
  bad_repos <- NULL
  try(bad_repos <- tbl(db, tname), silent = TRUE)
  if (is.null(bad_repos) || .fresh) {
    try(dbRemoveTable(db$con, tname), silent = TRUE)
    bad_repos <- ght$g_issues %>% distinct(repo) %>%
      anti_join(ght$popular_projects, by = "repo") %>%
      compute(tname, temporary = FALSE)
  }
  s <- sprintf("SELECT * FROM %s LIMIT %s OFFSET %s", tname, limit, offset)
  dbGetQuery(db$con, s)$repo
}
ListNoIssueEventRepos <- function(offset = 0, limit = 5, .fresh = FALSE) {
  # List repos without any issue events
  tname <- "bad_repos_2"
  bad_repos <- NULL
  try(bad_repos <- tbl(db, tname), silent = TRUE)
  if (is.null(bad_repos) || .fresh) {
    try(dbRemoveTable(db$con, tname), silent = TRUE)
    bad_repos <- ght$popular_projects %>%
      anti_join(
        ght$g_issues %>%
          semi_join(ght$g_issue_events, by = c("id" = "issue_id")) %>%
          distinct(repo),
        by = "repo"
      ) %>%
      distinct(repo) %>%
      compute(tname, temporary = FALSE)
  }
  s <- sprintf("SELECT * FROM %s LIMIT %s OFFSET %s", tname, limit, offset)
  dbGetQuery(db$con, s)$repo
}
