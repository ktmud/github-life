#
# Get Repository details
# 
RepoStats <- function(repo,
                      col_name = "commits",
                      group_others = TRUE) {
  repo <- as.character(repo)
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
    dat <- data.frame()
  }
  dat
}

PlotRepoTimeline <- function(repo) {
  if (is.null(repo) || repo == "") {
    return(EmptyPlot())
  }
  if (!(repo %in% repo_choices$repo)) {
    return(EmptyPlot("No data found! :("))
  }
  issues <- db_get(sprintf("
    SELECT
      `repo`,
      DATE(SUBDATE(SUBDATE(`created_at`, WEEKDAY(`created_at`)), 1)) AS `week`,
      count(*) as `n_issues`
    FROM `g_issues`
    WHERE `repo` = %s
    GROUP BY `week`
  ", dbQuoteString(db$con, repo)))
  repo_stats <- RepoStats(repo)
  
  if (nrow(repo_stats) + nrow(issues) < 1) {
    return(EmptyPlot("No data found! :("))
  }
  
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
  }
  p %<>% layout(
    barmode = "stack",
    yaxis = list(title = "Count"),
    xaxis = list(
      title = "Week",
      rangeselector = RangeSelector(mindate, maxdate)
    ))
  p
}

PlotRepoIssueTimeline <- function(repo) {
  if (is.null(repo) || repo == "") {
    return(EmptyPlot(""))
  }
  if (!(repo %in% repo_choices$repo)) {
    return(EmptyPlot(""))
  }
  # The detailed metrics of repos
  reponame <- repo
  events <- ght$g_issue_events %>%
    filter(repo == reponame) %>%
    # inside {} is MySQL functions
    group_by(week = { DATE(
      SUBDATE(SUBDATE(created_at, WEEKDAY(created_at)), 1)
    ) }) %>%
    count(event) %>%
    # show_query() %>%
    collect()
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

