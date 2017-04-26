library(shiny)
library(plotly)

source("include/init.R")
source("include/db.R")
source("include/helpers.R")
source("repo.R")

# load the names of all repos in memory
all_repos <- ListExistingRepos(limit = 80000)
repo_choices <- all_repos %>%
  mutate(repo = str_c(owner_login, "/", name))

# Define server logic required to draw a histogram
shinyServer(function(input, output, session) {
  
  observeEvent(input$repo, {
    if (input$repo %in% repo_choices$repo) {
      shinyjs::show("repo-activity")
      output$repo_timeline <- renderPlotly({
        PlotRepoTimeline(input$repo)
      })
      output$repo_detail <- renderUI({
      })
    } else {
      shinyjs::hide("repo_detail")
    }
    if (input$repo != "") {
      output$repo_fullname <- renderText({ input$repo })
    }
  })
  
  output$repo_fullname <- renderText({ "..." })
  output$repo_detail <- renderText({ "..." })
  
  updateSelectizeInput(
    session, 'repo',
    choices = repo_choices,
    server = TRUE
  )
})
