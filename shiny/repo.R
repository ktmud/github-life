#
# Get Repository details
# 
library(cacher)

if (!exists("cache")) {
  cache <- LRUcache("100mb") 
}

RepoStats <- function(repo,
                      col_name = "commits",
                      group_others = TRUE) {
  repo <- as.character(repo)
  key <- str_c("issue_stats_", repo)
  if (cache$exists(key)) {
    return(cache$get(key))
  }
  dat <- db_get(sprintf(
    "
      SELECT week, author, %s FROM g_contributors
      WHERE repo = %s
      ",
    dbQuoteIdentifier(db$con, col_name),
    dbQuoteString(db$con, repo)
  ))
  if (nrow(dat) > 0) {
    dat <- dat %>%
      .[, c("week", "author", col_name)]
    names(dat) <- c("week", "author", "count")
    dat <- CollapseOthers(dat, "author", "count")
    dat$week <- as.Date(dat$week)
  } else {
    # give an empty row
    dat <- data.frame()
  }
  dat %<>% FillEmptyWeeks()
  cache$set(key, dat)
  dat
}

CollapseOthers <-
  function(dat,
           keycol = "author",
           valcol = "count",
           keep_n = 5,
           others = "<i>others</i>") {
    
    dat$keycol <- dat[[keycol]]
    dat$valcol <- dat[[valcol]]
    
    top_author <- dat %>%
      group_by(keycol) %>%
      summarize(n = sum(valcol)) %>%
      # we need this diff rate to filter out
      # very small contributors
      mutate(p = n / max(n)) %>%
      arrange(desc(n)) %>%
      filter(p > .1) %>%
      head(keep_n)
    dat.top <- dat %>%
      filter(keycol %in% top_author$keycol)
    dat <- dat %>%
      filter(!(keycol %in% top_author$keycol)) %>%
      group_by(week) %>%
      # count of others authors
      summarise(valcol = sum(valcol)) %>%
      mutate(keycol = "<i>others</i>") %>%
      bind_rows(dat.top, .)
    dat[[keycol]] <- dat$keycol
    dat[[valcol]] <- dat$valcol
    dat$keycol <- NULL
    dat$valcol <- NULL
    dat
  }

RepoIssues <- function(repo) {
  db_get(
    sprintf(
      "
      SELECT
      `repo`,
      DATE(SUBDATE(SUBDATE(`created_at`, WEEKDAY(`created_at`)), 1)) AS `week`,
      count(*) as `n_issues`
      FROM `g_issues`
      WHERE `repo` = %s
      GROUP BY `week`
      ",
      dbQuoteString(db$con, repo)
    )
  ) %>% FillEmptyWeeks()
}
RepoIssueEvents <- function(repo) {
  key <- str_c('issue_events_', repo)
  if (cache$exists(key)) {
    return(cache$get(key))
  }
  dat <- db_get(
    sprintf(
      "
      SELECT
        `repo`,
        DATE(SUBDATE(SUBDATE(`created_at`, WEEKDAY(`created_at`)), 1)) AS `week`,
        `event`,
        count(*) as `count`
        FROM `g_issue_events`
        WHERE `repo` = %s
      GROUP BY `week`, `event`
      ",
      dbQuoteString(db$con, repo)
    )
  ) %>% CollapseOthers("event", keep_n = 6)
  cache$set(key, dat)
  dat
}
RepoStargazers <- function(repo) {
  db_get(sprintf("
    SELECT
      `repo`,
      DATE(SUBDATE(SUBDATE(`starred_at`, WEEKDAY(`starred_at`)), 1)) AS `week`,
      count(*) as `n_stargazers`
    FROM `g_stargazers`
    WHERE `repo` = %s
    GROUP BY `week`
  ", dbQuoteString(db$con, repo))) %>%
    FillEmptyWeeks()
}

PlotRepoTimeline <- function(repo) {
  if (is.null(repo) || repo == "") {
    return(EmptyPlot())
  }
  if (!(repo %in% repo_choices$repo)) {
    return(EmptyPlot("No data found! :("))
  }
  issues <- RepoIssues(repo)
  repo_stats <- RepoStats(repo)
  stargazers <- RepoStargazers(repo)
  
  # remove first week of data because for some large repositories
  # the first week of data can be very very large,
  # often screws the whole time line
  if (nrow(stargazers) > 10) {
    stargazers <- stargazers[-1, ]
    issues <- issues[-1, ]
  }
  
  if (nrow(repo_stats) + nrow(issues) + nrow(stargazers) < 1) {
    return(EmptyPlot("No data found! :("))
  }
  
  p <- plot_ly(repo_stats, x = ~week, y = ~count, opacity = 0.6,
               color = ~author, type = "bar")
  if (nrow(issues) > 0) {
    p %<>% add_lines(data = issues, x = ~week, y = ~n_issues,
                     opacity = 1,
                     mode = "lines+markers",
                     # line = list(width = 1),
                     name = "<b>issues</b>", color = I("#28A845"))
  }
  if (nrow(stargazers) > 0) {
    diffrate <- mean(issues$n_issues) / mean(stargazers$n_stargazers)
    stargazers %<>%
      mutate(star_scaled = n_stargazers * diffrate)
    p %<>% add_lines(data = stargazers, x = ~week, y = ~star_scaled,
                     opacity = 1,
                     visible = "legendonly",
                     mode = "lines+markers",
                     # line = list(width = 1),
                     name = "<b>stars (scaled)</b>", color = I("#fb8532"))
  }
  
  mindate <- min(issues$week, repo_stats$week,
                 stargazers$week, na.rm = TRUE)
  maxdate <- max(issues$week, repo_stats$week,
                 stargazers$week, na.rm = TRUE)
  p %<>% layout(
    barmode = "stack",
    yaxis = list(title = "Count"),
    xaxis = list(
      title = "Week",
      rangemode = "nonnegetive",
      rangeselector = RangeSelector(repo_stats$week)
    ))
  p
}

PlotRepoIssueEventsTimeline <- function(repo) {
  if (is.null(repo) || repo == "") {
    return(EmptyPlot(""))
  }
  if (!(repo %in% repo_choices$repo)) {
    return(EmptyPlot(""))
  }
  repo_stats <- RepoStats(repo)
  events <- RepoIssueEvents(repo) %>%
    FillEmptyWeeks(mindate = min(repo_stats$week), max(repo_stats$week))
  p <- plot_ly(
    events,
    x = ~ week,
    y = ~ count,
    color = ~ event,
    type = "bar"
  )
  p %<>% layout(
    barmode = "stack",
    yaxis = list(title = "Count"),
    xaxis = list(
      title = "Week",
      rangeselector = RangeSelector(events$week)
    ))
  p
}

GetRepoDetails <- function(repo) {
  if (is.null(repo) || !str_detect(repo, ".+/.+")) return()
  tmp <- str_split(repo, "/") %>% unlist()
  dat <- db_get(sprintf(
    "SELECT * from `g_repo`
    WHERE `owner_login` = '%s' and `name` = '%s'"
  , tmp[1], tmp[2]))
  if (is.null(dat) || nrow(dat) < 1) {
    return(tibble(repo = repo, exists = FALSE))
  }
  dat$repo <- repo
  dat$exists <- TRUE
  dat
}
RenderRepoDetails <- function(d) {
  if (is.null(d)) {
    return(
      div(class = "repo-detail-placeholder",
        "Please select a repository from the dropdown on the left.",
        tags$br(),
        "You may also type to search."
      )
    )
  }
  if (!d$exists) {
    return(
      div(class = "repo-detail-placeholder",
        "Could not found data for this repository.",
        tags$br(),
        "Either it doesn't exists or we didn't scrape it yet."
      )
    )
  }
  div(
    id = str_c("repo-detail-", d$id),
    class = "repo-details",
    div(
      class = "desc",
      tags$a(
        class = "to-github",
        target = "_blank",
        href = str_c("http://github.com/", d$repo),
        icon("external-link")
      ),
      d$description
    ),
    tags$ul(
      class = "list-inline time-points",
      tags$li(
        tags$span("Created at"),
        tags$strong(d$created_at)
      ),
      tags$li(
        tags$span("last updated at"),
        tags$strong(d$updated_at)
      ),
      tags$li(
        tags$span("last pushed at"),
        tags$span(d$pushed_at)
      )
    )
  )
}
RenderRepoMeta <- function(d) {
  if (is.null(d) || !d$exists) return()
  tags$ul(
    class = "list-inline repo-meta",
    tags$li(
      style = "width:6em",
      tags$span(d$lang)
    ),
    tags$li(
      icon("star"),
      tags$strong(fmt(d$stargazers_count)),
      tags$span("stars")
    ),
    tags$li(
      icon("code-fork"),
      tags$strong(fmt(d$forks_count)),
      tags$span("forks")
    )
  )
}

