library(shiny)
library(plotly)

source("include/init.R")
source("include/db.R")
source("include/helpers.R")
source("repo.R")

# load the names of all repos in memory
all_repos <- ListExistingRepos(limit = 40000)
# all_repos <- ListRandomRepos(limit = 2000)
repo_choices <- all_repos %>%
  arrange(desc(n_watchers)) %>%
  mutate(label = str_c(repo, " (", n_watchers, ")"),
         value = repo)

# Define server logic required to draw a histogram
shinyServer(function(input, output, session) {
  
  observeEvent(input$repo, {
    if (!str_detect(input$repo, "/")) {
      shinyjs::hide("single-repo")
      return()
    } else {
      shinyjs::show("single-repo")
    }
    if (input$repo %in% repo_choices$repo) {
      output$repo_timeline <- renderPlotly({
        PlotRepoTimeline(input$repo)
      })
    }
    output$repo_timeline_title <- renderText({
      str_c("Activity Timeline of <strong>", input$repo, "</strong>")
    })
  })
  
  updateSelectizeInput(session, 'repo',
                       choices = repo_choices, server = TRUE)
  
})
