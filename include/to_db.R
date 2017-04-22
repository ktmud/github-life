#
# Store scraped data into database.
#
source("include/db.R")

ExecuteSQL <- function(sql, con) {
  # execute multi line SQL queries
  strsplit(sql, ";\n") %>% unlist() %>%
    sapply(function(x) dbExecute(con, x)) %>%
    unlist()
}
# schema <- read_file("include/schema.sql") %>%
#   str_split(";\n+")
# ExecuteSQL(schema)

# system("merge.sh")