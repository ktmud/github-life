library(plotly)

EmptyPlot <- function(msg = "Pick a repository to start exploring...") {
  p <-
    ggplot(data.frame(
      x = as.Date("2014-01-01"),
      y = 10,
      text = msg
    )) +
    geom_text(aes(x, y, label = text),
              vjust = "inward",
              hjust = "inward") +
    xlim(as.Date("2011-01-01"), as.Date("2017-01-01")) +
    ylim(0, 20) + theme_void() +
    labs(x = "Week", y = "Count")
  ggplotly(p) %>%
    layout(xaxis = list(fixedrange = T),
           yaxis = list(fixedrange = T)) %>%
    config(displayModeBar = F)
}

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

FillEmptyWeeks <- function(dat, mindate, maxdate) {
  if (nrow(dat) == 0) return(dat)
  if (any(is.na(dat$week))) return(dat) 
  dat.full <- data.frame(week = seq(mindate, maxdate, 7)) %>%
    full_join(dat, by = "week") 
  dat.full[is.na(dat.full)] <- 0
  dat.full
}