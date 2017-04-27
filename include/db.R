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
db_save <- function(name, value, id_field = "id", retry_count = 0) {
  # remove existing data then save the latest data to database
  # Args:
  #   name - the name of a table
  #   value - the values in a data frame, must have a `id` column
  # Return: whether writeTable succeed.
  if (nrow(value) < 1) return(TRUE)
  if (is.null(id_field)) id_field = "id"
  
  last_value <<- value
  ids <- str_c(value[, id_field])
  name_q <- dbQuoteIdentifier(db$con, name)
  if (length(id_field) > 1) {
    id_field_q <- vapply(id_field, dbQuoteIdentifier, db$con) %>%
      str_c(collapse = ", ")
    id_field_q <- strc("COCAT(", id_field_q, ")")
  } else {
    id_field_q <- id_field
    id_field_q <- dbQuoteIdentifier(db$con, id_field)
  }
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
      db_save(name, value, id_field, retry_count + 1)
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

# === All sorts of different repos list ====================
read_dat <- function(fpath, sql, .fresh = FALSE) {
  # Load data from local file,
  # if file does not exist, read from SQL,
  # and then write the results into local file
  if (file.exists(fpath) && .fresh == FALSE) {
    dat <- read_csv(fpath) 
  } else {
    dat <- db_get(sql)
    if (!is.null(dat) && nrow(dat) > 0) {
      write_csv(dat, fpath)
    }
  }
  dat
}
subset_dat <- function(dat, offset = 0, limit = 5) {
  dat[(offset+1):min(nrow(dat), offset+limit), , drop = FALSE]
}

ListAvailableRepos <- function(offset = 0, limit = 5, .fresh = FALSE) {
  read_dat(
    "data/available_repos.csv",
    "SELECT
    CONCAT(`owner_login`, '/', `name`) AS `repo`,
    `owner_login`, `name`, `lang`,
    `stargazers_count` AS `stars`,
    `forks_count` AS `forks`,
    `created_at`, `description`
    FROM `g_repo`
    ORDER BY `stars` DESC
    ",
    .fresh = .fresh
  ) %>% 
    subset_dat(offset, limit)
}
ListRandomRepos <- function(offset = 0, limit = 5, seed = 1984) {
  # List randome repos, helpful when we only want to 
  # scrape a small sample
  # Args:
  #  seed - the seed for randomize the sample
  
  # set a seed so the result can be repeatable
  set.seed(seed)
  sample_n(available_repos, nrow(available_repos)) %>%
    subset_dat(offset, limit)
}
ListScrapedRepos <- function(offset = 0, limit = 5, .fresh = FALSE) {
  read_dat(
    "data/scraped_repos.csv",
    # use g_punch_card to identify repositories we already scraped
    "SELECT DISTINCT(repo) FROM g_punch_card", .fresh = .fresh) %>% 
    subset_dat(offset, limit)
}
ListNotScrapedRepos <- function(offset = 0, limit = 5, .fresh = FALSE) {
  # List repos that has are in the `available_list` list, but
  # have not been scraped yet
  scraped_repos <- ListScrapedRepos(limit = 10e5)
  notscraped <- available_repos %>%
    anti_join(scraped_repos, by = "repo")
  notscraped %>%
    subset_dat(offset, limit)
}