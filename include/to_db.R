#
# Store scraped data into database.
#
source("include/db.R")

schema <- read_file("include/schema.sql") %>% str_split(";\n+")

ExecuteSQL <- function(sql, con) {
  # apply multi line SQL query to a DB connection
  strsplit(sql, ";\n") %>% unlist() %>%
    sapply(function(x) dbExecute(con, x)) %>%
    unlist()
}
# ExecuteSQL(schema)