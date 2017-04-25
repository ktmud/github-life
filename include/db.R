library(DBI)
library(RMySQL)

# ========== Establish database connection ===============
db.ok <- FALSE
# close existing connection
if (exists("db")) {
  try({
    # if connection is gone, this will throw an error
    dbExecute(db$con, "select 1")
    db.ok <- TRUE
  })
}
if (!db.ok) {
  db <- src_mysql(
    dbname = Sys.getenv("MYSQL_DBNAME"),
    # host = "127.0.0.1",
    host = Sys.getenv("MYSQL_HOST"),
    port = as.integer(Sys.getenv("MYSQL_PORT")),
    user = Sys.getenv("MYSQL_USER"),
    password = Sys.getenv("MYSQL_PASSWD")
  )
  # access all database tables
  ght.tables <- src_tbls(db)
  names(ght.tables) <- ght.tables
  ght <- lapply(ght.tables, function(x) tbl(db, x))
  
  # Necessary for EMOJIs! :), otherwise some text columns
  # such as `g_issues.title` may complain
  dbExecute(db$con, "SET NAMES utf8mb4")
}


# ======== Database functions ====================
#
# These functions are not actually in use.
#
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
  tryCatch({
    dbExecute(db$con,
              sprintf(
                "DELETE FROM %s WHERE %s IN(%s)",
                name_q,
                id_field_q,
                str_c(ids, collapse = ", ")
              ))
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
RepoExistsInTable <- function(fullname, in_table = "g_issues") {
  # Check whether repo exists in a database table
  res <- dbGetQuery(db$con, sprintf(
    "SELECT 1 FROM %s WHERE repo = %s LIMIT 1",
    dbQuoteIdentifier(db$con, in_table),
    dbQuoteString(db$con, fullname)
  ))
  nrow(res) == 1
}
ListPopularRepos <- function(offset = 0, limit = 5, order = TRUE) {
  # List the Top N most popular repos
  # Args:
  #   offset - skip how many repos
  dbGetQuery(db$con, sprintf(
    "
    SELECT `repo`, `n_watchers` FROM `popular_projects` %s
    LIMIT %s OFFSET %s
    ",
    ifelse(order, "ORDER BY `n_watchers`", ""),
    limit, offset
  ))
}
# === For checking of data integerity --------------------
ListExistingRepos <- function(offset = 0, limit = 5) {
  dbGetQuery(db$con, sprintf(
    "
    SELECT concat(`owner_login`, '/', `name`) AS repo,
          `stargazers_count` AS stars
    FROM `g_repo`
    LIMIT %s OFFSET %s
    ", limit, offset
  ))
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
  dbGetQuery(db$con, s)
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
  dbGetQuery(db$con, s)
}