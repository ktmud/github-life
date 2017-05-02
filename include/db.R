library(DBI)
library(RMySQL)

# ========== Establish database connection ===============

db_connect <- function(retry_count = 0) {
  # establish a new database connection
  tryCatch({
    db <- src_mysql(
      dbname = Sys.getenv("MYSQL_DBNAME"),
      # host = "127.0.0.1",
      host = Sys.getenv("MYSQL_HOST"),
      port = as.integer(Sys.getenv("MYSQL_PORT")),
      user = Sys.getenv("MYSQL_USER"),
      password = Sys.getenv("MYSQL_PASSWD")
    )
  }, error = function(err) {
    # assign("last_err", err, envir = .GlobalEnv)
    # retry connecting for 3 times, wait for 5 secs between each retry
    Sys.sleep(5)
    if (retry_count > 3) {
      stop(err)
    }
    message("Retry connecting to MySQL...")
    db_connect(retry_count + 1)
  })
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
  db
}

if (!exists("db")) db_connect()

db_get <- function(query, retry_count = 0) {
  # Get Data from our db connection
  res <- NULL
  tryCatch({
    res <- dbGetQuery(db$con, query)
  }, error = function(err) { 
    assign("last_err", err, envir = .GlobalEnv)
    # if the error was server gone away, try reconnect
    if (str_detect(err$message, "gone away")) {
      message("MySQL has gone way, try reconnecting..")
      db_connect()
    }
    if (retry_count > 2) {
      stop(err)
    }
    Sys.sleep(5)  # retry at most 5 times every 10 secs
    message("This query got an error:")
    message(query)
    message(err)
    res <<- db_get(query, retry_count + 1)
  })
  res
}

# ======== Database functions ====================
db_save <- function(name, value, retry_count = 0) {
  # remove existing data then save the latest data to database
  # we are doing this because there's no easy way to do upsert
  # Args:
  #   name - the name of a table
  #   value - the values in a data frame, must have a `id` column
  # Return: whether writeTable succeed.
  n <- nrow(value)
  if (!is.null(n) && n < 1) return(TRUE)
  
  # each chunk at most 2MB
  n_parts <- as.integer(ceiling(object.size(value) / (1024*1024*2)))
  if (n_parts > 1) {
    message("Object too large, split into ", n_parts, " parts.")
    return(db_split_save(name, value, n_parts))
  }
  
  name_q <- dbQuoteIdentifier(db$con, name)
  tryCatch({
    dbWriteTable(db$con, name, value, append = TRUE,
                 onduplicate = "replace")
  }, error = function(err) {
    assign("last_err", err, envir = .GlobalEnv)
    # if the error was server gone away, try reconnect
    if (str_detect(err$message, "gone away")) {
      message("MySQL has gone way, try reconnecting..")
      db_connect()
      if (retry_count > 0) {
        # if gone away happens too often, it is most likely because of
        # packet size too large, split the chunks in to half, then try again.
        return(db_split_save(name, value))
      }
    }
    # have already retried 5 times
    if (retry_count > 5) {
      message(err$msssage)
      stop(err)
    }
    # wait a while before next retry
    Sys.sleep(2)
    db_save(name, value, retry_count + 1)
  })
  return(TRUE)
}
db_split_save <- function(name, value, n_parts = 2) {
  # cut data into half and retry, until it succeed
  n <- nrow(value)
  perbatch <- floor(n / n_parts)
  for (i in seq(0, n, perbatch)) {
    j <- min(n, i + perbatch)
    if (i < j) {
      db_save(name, value[(i+1):j, ])
    }
  }
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
