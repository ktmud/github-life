library(rlang)
library(tidyverse)
library(purrr)
library(magrittr)
library(stringr)
library(lubridate)

# cache all available repos in global memory (this might be faster than you thought)
if (!exists("kAllRepos")) {
  kAllRepos <- read_csv("data/popular_repos.csv") 
}

ListRandomRepos <- function(offset = 0, limit = 5, seed = 1984) {
  # List randome repos, helpful when we only want to 
  # scrape a small sample
  # Args:
  #  seed - the seed for randomize the sample
  
  # set a seed so the result can be repeatable
  set.seed(seed)
  repos <- sample_n(kAllRepos, nrow(kAllRepos))
  repos[(offset+1):min(nrow(repos), offset+limit), ]
}