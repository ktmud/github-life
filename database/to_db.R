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

system("merge.sh")

LoadToMySQL <- function() {
  # Use MySQL LOAD INFILE to import stored data
  files <- Sys.glob("/tmp/github__*.csv")
  tables <- files %>%
    str_replace("/tmp/github__", "") %>%
    str_replace(".csv$", "")
  for (i in seq_along(tables)) {
    dbExecute(sprintf("
      SET foreign_key_checks = 0;
      LOAD DATA INFILE '%s' INTO TABLE %s CHARACTER SET UTF8
      FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"'
      LINES TERMINATED BY '\n';
    ", files[i], tables[i]))
  }
}
LoadToMySQL()