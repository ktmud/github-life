library(DBI)
library(RMySQL)

# ========== Establish database connection ===============

db_connect <- function() {
  # establish a new database connection
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
  # export global variables
  assign("db", db, envir = .GlobalEnv)
  assign("ght", ght, envir = .GlobalEnv)
}

if (!exists("db")) db_connect()

db_get <- function(query, retry_count = 0) {
  # Get Data from our db connection
  res <- NULL
  tryCatch({
    res <- dbGetQuery(db$con, query)
  }, error = function(err) { 
    # if the error was server gone away, try reconnect
    if (err$message == "MySQL server has gone away [2006]") {
      message("MySQL has gone way, try reconnecting..")
      db_connect()
    }
    if (retry_count < 2) {
      res <<- db_get(query, retry_count + 1)
    } else {
      stop(err)
    }
  })
  res
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
  db_get(sprintf(
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
  db_get(sprintf(
    "
    SELECT
      CONCAT(`owner_login`, '/', `name`) AS `repo`,
      `owner_login`, `name`, `lang`,
      `stargazers_count` AS `stars`,
      `forks_count` AS `forks`,
      `created_at`, `description`
    FROM `g_repo`
    ORDER BY `stars` DESC
    LIMIT %d OFFSET %d
    ", limit, offset
  ))
}
ListNonExistingRepos <- function(offset = 0, limit = 5, .fresh = FALSE) {
  # List repos that has are in the `all_repos` list, but
  # have not been scraped yet
  scraped_repos <- read_dat(
    "data/non_existing_repos.csv",
    # use g_punch_card to identify repositories we already scraped
    "SELECT DISTINCT(repo) FROM g_punch_card"
  , fresh = fresh)
  repos <- all_repos %>% anti_join(scraped_repos, by = "repo")
  repos[(offset+1):min(nrow(repos), offset+limit), ]
}
