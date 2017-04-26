library(rlang)
library(tidyverse)
library(purrr)
library(magrittr)
library(stringr)
library(lubridate)

source("include/helpers.R")
source("include/db.R")

read_dat <- function(fpath, sql) {
  # Load data from local file,
  # if file does not exist, read from SQL,
  # and then write the results into local file
  if (file.exists(fpath)) {
    dat <- read_csv(fpath) 
  } else {
    dat <- db_get(sql)
    if (!is.null(dat) && nrow(dat) > 0) {
      write_csv(dat, fpath)
    }
  }
  dat
}

# cache all available repos in global memory
all_repos <- read_dat(
  "data/popular_repos.csv", 
  "SELECT CONCAT(`owner_login`, '/', `nama`) AS repo FROM g_repo"
)

ListRandomRepos <- function(offset = 0, limit = 5, seed = 1984) {
  # List randome repos, helpful when we only want to 
  # scrape a small sample
  # Args:
  #  seed - the seed for randomize the sample
  
  # set a seed so the result can be repeatable
  set.seed(seed)
  repos <- sample_n(all_repos, nrow(all_repos))
  repos[(offset+1):min(nrow(repos), offset+limit), ]
}