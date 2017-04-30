# Github Life

Explore and learn from the activity patterns of some of the most liked open source projects on GitHub.

## Overview

This project collects and stores data of 1% most starred github repositories, including their [general details](https://developer.github.com/v3/repos/#get), [languages](https://developer.github.com/v3/repos/#list-languages), [stargazers](https://developer.github.com/v3/activity/starring/#list-stargazers), [contributors statistics](https://developer.github.com/v3/repos/statistics/#get-contributors-list-with-additions-deletions-and-commit-counts),
[number of commits per hour each day](https://developer.github.com/v3/repos/statistics/#get-the-number-of-commits-per-hour-in-each-day), [issues](https://developer.github.com/v3/issues/#list-issues-for-a-repository), [issues events](https://developer.github.com/v3/issues/events/#list-events-for-an-issue) and [issue comments](https://developer.github.com/v3/issues/comments/#list-comments-on-an-issue).

The data points are first scraped into separate csv files, then concatenated and imported into MySQL for easier aggregation and analysis. A [Shiny Dashboard] was hence built to use this database to explore activity timelines of single reposities and patterns of different repository groups.

The code consists of four major parts: `database`, `scraper`, `shiny` and `report`.

- **database**: shemas of the database and toolkits to import local csv files.
- **scraper**: scrape the data from GitHub API. Supports parallel scraping with the [future](https://github.com/HenrikBengtsson/future) package.
- **shiny**: the shiny app.
- **report**: data aggregations and preliminary data analysis reports.

## Setup Scraping

### Generate the seed of top repositories

In the `data/` directory, contains a list of top repositories (`data/available_repos.csv`) we generated using the GHTorrent snapshot data on April 1, 2017.

To repeat this seeding process with newer data:

1. Download from GHTorrent.org the latest MySQL database dumps.
2. Restore the `projects` and `watchers` tables to a local database.
3. Run "database/seed.sql" on the database you restored to generate the list of popular projects.
4. Export the generated `popular_projects` table to a csv file and save it as `data/available_repos.csv`.

Of course you can use repository lists from other sources, just make sure you put them in a `csv` file and a `repo` column exists in it.

### Set environment variables

This application uses environemnt variables to connect to MySQL and setting tokens for GitHub. Make sure you have these variables set in your `.Renviron`, which can be put into either your home directory or the working directory of R.

```bash
GITHUB_TOKENS=...
GITHUB_DATA_DIR="./scrape-log"
R_ENV=production
MYSQL_DBNAME=ghtorrent_restore
MYSQL_HOST=127.0.0.1
MYSQL_PORT=3306
MYSQL_USER=ghtorrentuser
MYSQL_PASSWD=ghtorrentpassword
```

## Packages needed

Please make sure these packages were successfully installed before you run the scraper.

```R
install.packages(c("tidyverse", "dplyr", "lubridate", "future"))
install.packages("devtools")
devtools::install_github("r-pkgs/gh")
devtools::install_github("rstats-db/DBI")
devtools::install_github("ktmud/RMySQL@upsert")
devtools::install_github("hadley/ggplot2")
devtools::install_github("ropensci/plotly")
```

Depending on your machine, compling some of the packages may need additional
libraries. If you are using a fresh Ubuntu 17.04 server, you might want to do:

```bash
sudo apt update
sudo apt upgrade
sudo apt install mysql-server r-base 
sudo apt install libmysqlclient-dev libmariadb-client-lgpl-dev
sudo apt install libxml2-dev libssl-dev libcurl4-openssl-dev
```

Feel free to install RStudio Server and Shiny Server, too:

```
sudo apt install gdebi-core
wget https://download2.rstudio.org/rstudio-server-1.0.143-amd64.deb
wget https://download3.rstudio.org/ubuntu-12.04/x86_64/shiny-server-1.5.3.838-amd64.deb

sudo su - \
-c "R -e \"install.packages('shiny', repos='https://cran.rstudio.com/')\""
sudo gdebi rstudio-server-1.0.143-amd64.deb
sudo gdebi shiny-server-1.5.3.838-amd64.deb
```

### Start Scraping

1. Start a MySQL service, create a database and the tables using `database/schema.sql`. DON'T add any indexes yet.
2. Make sure all packages required are successfully installed.
3. If you want parallel scraping, run `scrape_cluser.R`, otherwise dive into `scrape.R` and run appropriate functions as you needed.
4. After the scraping is done, then you can add MySQL indexes using `database/indexes.sql`. There are other scripts in the `database` folders as well, but they were for when you want to scrape all data into local csv files before importing to the database (which would not be necessary if you can have the mysql service up and running from the start).

## TODO

- [ ] Make this app a docker dontainer
- [ ] Split the scraper and shiny app
- [ ] More detailed analysis
- [ ] User relationship data

