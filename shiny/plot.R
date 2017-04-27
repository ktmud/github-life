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
