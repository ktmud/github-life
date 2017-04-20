#
# Get Repository details
# 
library(plotly)

PlotRepoTimeline <- function(repo) {
  fullname <- repo
  weekly_issues <- ght$g_issues %>%
    filter(repo == fullname) %>%
    # inside {} is MySQL functions
    group_by(week = { DATE(
      SUBDATE(SUBDATE(created_at, WEEKDAY(created_at)), 1)
    ) }) %>%
    summarise(n_issues = n()) %>%
    show_query() %>%
    collect()
  dat <- read_csv(fname(fullname, "contributions")) %>%
    select(w, c, author_login) %>%
    filter(c > 0)
  colnames(dat) <- c("week", "commits", "author")
  dat$week %<>%
    as.integer() %>%
    as.POSIXct(origin="1970-01-01") %>%
    as.Date()
  top_author <- dat %>%
    group_by(author) %>%
    summarize(n = sum(commits)) %>%
    arrange(desc(n)) %>%
    head(5)
  dat <- dat %>%
    filter(author %in% top_author$author) %>%
    spread(author, commits)
  dat <- full_join(dat, weekly_issues, by = "week")
  dat[is.na(dat)] <- 0
  p <- plot_ly(dat, x = ~week, y = ~n_issues,
            name = 'issues count', type = 'scatter', mode = 'lines') 
  if (nrow(weekly_issues) > 0) {
    for (author in top_author$author) {
      print(author)
      p %<>% add_trace(x = ~ week, y = dat[[author]],
                       name = str_c(author, '\'s commits'))
    }
  }
  p
}
PlotRepoTimeline("integrity/integrity")
