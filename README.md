# Death and Life of Great Open Source Projects

Explore and learn from the activity patterns of some of the most liked open source projects on GitHub.

## Overview

This project collects and stores data of 1% most starred github repositories, including their [general details](https://developer.github.com/v3/repos/#get), [languages](https://developer.github.com/v3/repos/#list-languages), [stargazers](https://developer.github.com/v3/activity/starring/#list-stargazers), [contributors statistics](https://developer.github.com/v3/repos/statistics/#get-contributors-list-with-additions-deletions-and-commit-counts),
[number of commits per hour each day](https://developer.github.com/v3/repos/statistics/#get-the-number-of-commits-per-hour-in-each-day), [https://developer.github.com/v3/issues/#list-issues-for-a-repository](issues), [issues events](https://developer.github.com/v3/issues/events/#list-events-for-an-issue) and [issue comments](https://developer.github.com/v3/issues/comments/#list-comments-on-an-issue).

The data points are first scraped into separate csv files, then concatenated and imported into MySQL for easier aggregation and analysis. A [Shiny Dashboard] was hence built to use this database to explore activity timelines of single reposities and patterns of different repository groups.

The code consists of four major parts: `database`, `scraper`, `shiny` and `report`.

- **database**: shemas of the database and toolkits to import local csv files.
- **scraper**: scrape the data from GitHub API. Supports parallel scraping with the [future](https://github.com/HenrikBengtsson/future) package.
- **shiny**: the shiny app.
- **report**: data aggregations and preliminary data analysis reports.

## Rerun the data collection process

1. Download from GHTorrent.org the latest MySQL database dumps.
2. Restore the `projects` and `watchers` tables to a local database.
3. Run "database/seed.sql" on the database you restored to generate the list of popular projects.
4. Export the generated `popular_projects` table to a csv file and save it as `data/available_repos.csv`.
5. Run `scrape.R` or `scrape_cluster.R`, you should have the latest data from GitHub scraped to `./github_data/` (you may change this path by updating environment variable `GITHUB_DATA_DIR` in `.Renviron`).

You can skip step 1~3 if you have your own list of data that you wnat to scrape, or are satisfied with the seed file (`data/popular_repos.csv`) shipped with thise repository. We generated the list using the April 1, 2017 snapshot of GHTorrent data.


## Packages needed

Must have these packages installed in order to run the scraper and the shiny app.

```
install.packages(c("tidyverse", "dplyr", "lubridate", "future"))
devtools::install_github("rstats-db/DBI")
devtools::install_github("rstats-db/RMySQL")
devtools::install_github("hadley/ggplot2")
devtools::install_github("ropensci/plotly")
```

If you are using a fresh Ubuntu 17.04 server, start by installing these 

```
sudo apt update
sudo apt upgrade
sudo apt install libmysqlclient-dev libmariadb-client-lgpl-dev
sudo apt install mysql-server r-base
sudo apt install libxml2-dev libssl-dev curl
sudo apt install gdebi-core
wget https://download2.rstudio.org/rstudio-server-1.0.143-amd64.deb
wget https://download3.rstudio.org/ubuntu-12.04/x86_64/shiny-server-1.5.3.838-amd64.deb

sudo su - \
-c "R -e \"install.packages('shiny', repos='https://cran.rstudio.com/')\""
sudo gdebi rstudio-server-1.0.143-amd64.deb
sudo gdebi shiny-server-1.5.3.838-amd64.deb
```

