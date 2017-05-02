# library(rlang)
# library(purrr)
library(tidyverse)
library(magrittr)
library(stringr)
library(lubridate)

source("include/helpers.R")
source("include/db.R")

# cache all available repos in global memory
if (!exists("available_repos")) {
  available_repos <- ListAvailableRepos(limit = 80000)
}