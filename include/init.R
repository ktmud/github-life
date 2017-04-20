library(tidyverse)
library(purrr)
library(magrittr)
library(stringr)
library(lubridate)

## Dev version of these pkgs are required.
library(DBI)
library(RMySQL)

# close existing connection
# if (exists("db")) {
#  try(dbDisconnect(db$con), silent = TRUE)
# }

# Attach database tables into environment
db <- src_mysql(
  dbname = Sys.getenv("MYSQL_DBNAME"),
  host = "127.0.0.1",
  # host = Sys.getenv("MYSQL_HOST"),
  port = as.integer(Sys.getenv("MYSQL_PORT")),
  user = Sys.getenv("MYSQL_USER"),
  password = Sys.getenv("MYSQL_PASSWD")
)
ght.tables <- src_tbls(db)
names(ght.tables) <- ght.tables
ght <- lapply(ght.tables, function(x) tbl(db, x))

# Necessary for EMOJIs! :), otherwise the `g_issues.title` column
# may complain
dbExecute(db$con, "SET NAMES utf8mb4")

