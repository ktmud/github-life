#
# SQL schema of additional tables
#

# Create Additional table ==============
schema <- read_file("include/schema.sql") %>% str_split(";\n+")

ExecuteSQL <- function(sql, con) {
  # apply multi line SQL query to a DB connection
  strsplit(sql, ";\n") %>% unlist() %>%
    sapply(function(x) dbExecute(con, x)) %>%
    unlist()
}
# ExecuteSQL(schema)