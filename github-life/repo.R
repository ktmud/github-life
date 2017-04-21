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
  f <- fname(repo, "contributions")
  dat <- data.frame()
  if (file.exists(f)) {
    dat <- read_csv(f)
  }
  if (nrow(dat) > 0) {
    dat <- dat %>%
      rename(
        week = w,
        author = author_login,
        commits = c,
        additions = a,
        deletions = d
      ) %>%
      mutate(author = as.character(author))
    # filter zero cols
    dat <- dat[, c("week", col_name, "author")]
    dat$count <- dat[[col_name]]
    dat$week %<>%
      as.integer() %>%
      as.POSIXct(origin="1970-01-01") %>%
      as.Date()
    top_author <- dat %>%
      group_by(author) %>%
      summarize(n = sum(count)) %>%
      arrange(desc(n)) %>%
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
    # the data column will always be named "count"
    dat[[col_name]] <- NULL
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
  issues <- ght$g_issues %>%
    filter(repo == UQ(repo)) %>%
    # inside {} is MySQL functions
    group_by(week = { DATE(
      SUBDATE(SUBDATE(created_at, WEEKDAY(created_at)), 1)
    ) }) %>%
    summarise(n_issues = n()) %>%
    show_query() %>%
    collect()
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
    show_query() %>%
    collect()
  repo_stats <- RepoStats(repo)
}

PlotRepoTimeline("futuresimple/android-floating-action-button")
