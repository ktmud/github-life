library(tidyverse)
library(purrr)
library(magrittr)
library(stringr)
library(lubridate)

## Dev version of these pkgs are required.
library(DBI)
library(RMySQL)

source("include/db.R")

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
    host = "localhost",
    # host = Sys.getenv("MYSQL_HOST"),
    port = as.integer(Sys.getenv("MYSQL_PORT")),
    user = Sys.getenv("MYSQL_USER"),
    password = Sys.getenv("MYSQL_PASSWD")
  )
  # access all database tables
  ght.tables <- src_tbls(db)
  names(ght.tables) <- ght.tables
  ght <- lapply(ght.tables, function(x) tbl(db, x))
  
  # Necessary for EMOJIs! :), otherwise the `g_issues.title` column
  # may complain
  dbExecute(db$con, "SET NAMES utf8mb4")
}

kDataDir <- "/srv/github_data/"
# cache all available repos in global memory (this might be faster than you thought)
kAllRepos <- read_csv(str_c(kDataDir, "popular_repos.csv"))
