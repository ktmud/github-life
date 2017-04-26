#
# Get Repository details
# 
library(plotly)

RangeSelector <- function(mindate, maxdate) {
  btns <- list()
  diffdays <- as.double(maxdate - mindate, units = "days")
  if (diffdays > 30 * 4) {
    btns[[length(btns) + 1]] <- list(
      count = 3,
      label = "3 mo",
      step = "month",
      stepmode = "backward"
    )
  }
  if (diffdays > 30 * 7) {
    btns[[length(btns) + 1]] <- list(
      count = 6,
      label = "6 mo",
      step = "month",
      stepmode = "backward"
    )
  }
  if (diffdays > 400) {
    btns[[length(btns) + 1]] <- list(
      count = 1,
      label = "1 yr",
      step = "year",
      stepmode = "backward"
    )
  }
  if (diffdays > 365 * 2.5) {
    btns[[length(btns) + 1]] <- list(
      count = 2,
      label = "2 yr",
      step = "year",
      stepmode = "backward"
    )
  }
  btns <<- btns
  if (length(btns) > 0) {
    btns[[length(btns) + 1]] <- list(step = "all")
    list(buttons = btns)
  } else {
    NULL    
  }
}

RepoStats <- function(repo,
                      col_name = "commits",
                      group_others = TRUE) {
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
    top_author <- dat %>%
      group_by(author) %>%
      summarize(n = sum(count)) %>%
      # we need this diff rate to filter out
      # very small contributors
      mutate(p = n / max(n)) %>%
      arrange(desc(n)) %>%
      filter(p > .1) %>%
      head(5)
    dat.top <- dat %>%
      filter(author %in% top_author$author)
    dat <- dat %>%
      filter(!(author %in% top_author$author)) %>%
      group_by(week) %>%
      # count of others authors
      summarise(`count` = sum(count)) %>%
      mutate(author = "<i>others</i>") %>%
      bind_rows(dat.top)
    dat$week <- as.Date(dat$week)
  } else {
    # give an empty row
    dat <- data.frame(week = NA, author = NA, count = NA)
  }
  dat
}

FillEmptyWeeks <- function(dat, mindate, maxdate) {
  if (nrow(dat) == 0) return(dat)
  if (any(is.na(dat$week))) return(dat) 
  dat.full <- data.frame(week = seq(mindate, maxdate, 7)) %>%
    full_join(dat, by = "week") 
  dat.full[is.na(dat.full)] <- 0
  dat.full
}

PlotRepoTimeline <- function(repo) {
  issues <- db_get(sprintf("
    SELECT
      `repo`,
      DATE(SUBDATE(SUBDATE(`created_at`, WEEKDAY(`created_at`)), 1)) AS `week`,
      count(*) as `n_issues`
    FROM `g_issues`
    WHERE `repo` = %s
    GROUP BY `week`
  ", DBI::dbQuoteString(db$con, repo)))
  repo_stats <- RepoStats(repo)
  
  mindate <- min(issues$week, repo_stats$week, na.rm = TRUE)
  maxdate <- max(issues$week, repo_stats$week, na.rm = TRUE)
  
  issues %<>% FillEmptyWeeks(mindate, maxdate)
  
  p <- plot_ly(repo_stats, x = ~week, y = ~count, opacity = 0.6,
               color = ~author, type = "bar")
  if (nrow(issues) > 0) {
    p %<>% add_lines(data = issues, x = ~week, y = ~n_issues,
                     opacity = 1,
                     mode = "lines+markers",
                     # line = list(width = 1),
                     name = "<b>issues</b>", color = I("#28A845"))
    p %<>% layout(
      barmode = "stack",
      yaxis = list(title = "Count"),
      xaxis = list(
        title = "Week",
        rangeselector = RangeSelector(mindate, maxdate)
      ))
  }
  p
}

PlotIssuesTimeline <- function(repo) {
  # The detailed metrics of repos
  events <- ght$g_issue_events %>%
    filter(repo == UQ(repo)) %>%
    # inside {} is MySQL functions
    group_by(week = { DATE(
      SUBDATE(SUBDATE(created_at, WEEKDAY(created_at)), 1)
    ) }) %>%
    count(event) %>%
    # show_query() %>%
    collect()
}

GetRepoDetails <- function(repo) {
  tmp <- str_split(repo, "/") %>% unlist()
  db_get(sprintf(
    "SELECT * from `g_repo`
    WHERE `owner_login` = '%s' and `name` = '%s'"
  , tmp[1], tmp[2]))
}
RenderRepoDetails <- function(d) {
  div(
    id = str_c("repo-detail-", d$id),
    class = "repo-details",
    div(class = "desc", d$description),
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