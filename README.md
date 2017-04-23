# Death and Life of Great Open Source Projects

Explore and learn fro mthe life stories of some of the most liked open source projects on GitHub.

## How to repeat the data collection process?

1. Download from GHTorrent.org the latest MySQL database dumps.
2. Restore the `projects` and `watchers` tables to a local database.
3. Run "database/seed.sql" on the database you restored.
4. Export the generated `popular_projects` table to a csv file and save it under `data/popular_repos.csv`.
5. Run `scrape.R` or `scrape_cluster.R`, you should have the latest data from GitHub scraped to `./github_data/`

Skip Step 1~3 if you are satisfied with current seed file (`data/popular_repos.csv`) we generated from the April 1, 2017 snapshot of GHTorrent data or if you have your own list of repositories to scrape.

