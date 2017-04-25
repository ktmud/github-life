#
# Store scraped data into database.
#
source("include/init.R")
source("include/db.R")

ExecuteSQL <- function(sql, con) {
  # execute multi line SQL queries
  sql %>%
    # remove comments
    str_replace_all("--.*?\\n", "\n") %>%
    str_trim() %>%
    str_split(";") %>%
    unlist() %>%
    discard(function(x) x == "") %>%
    str_trim() %>%
    walk(function(x) {
      message("> ", x)
      message("> ", dbExecute(con, x))
    })
}
LoadToMySQL <- function(con) {
  # Use MySQL LOAD INFILE to import stored data
  files <- Sys.glob("/tmp/github__*.csv")
  tables <- files %>%
    str_replace("/tmp/github__", "") %>%
    str_replace(".csv$", "")
  
  load.sql <- "database/load.sql"
  cat("SET foreign_key_checks = 0;\n", file = load.sql)
  for (i in seq_along(tables)) {
    # tables with text field needs true UTF8,
    # others don't need
    charset <- ifelse(tables[i] %in% c("issues", "issue_comments", "repo"),
                      "CHARACTER SET UTF8MB4", "")
    cat(sprintf("
LOAD DATA LOCAL INFILE '%s'
IGNORE INTO TABLE `g_%s` %s
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' ESCAPED BY '\"'
LINES TERMINATED BY '\\n'
IGNORE 1 LINES;
", files[i], tables[i], charset
),
        file = load.sql, append = TRUE)
  }
  # RMySQL doesn't support this,
  # you'd run the scripts manually
  # dbExecute(con, read_file(load.sql))
}

ImportToMySQL <- function() {
  schema <- read_file("database/schema.sql")
  ExecuteSQL(schema, db$con)
  system("database/merge.sh")
  LoadToMySQL(db$con)
}
