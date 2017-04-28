repo_choices <- available_repos

source("shiny/plot.R")
source("shiny/repo.R")

# Define server logic required to draw a histogram
shiny_server <- shinyServer(function(input, output, session) {
  
  cdata <- session$clientData
  
  updateSelectizeInput(
    session, 'repo',
    choices = repo_choices,
    server = TRUE
  )
  
  # handle repo changes
  observeEvent(input$repo, {
    if (input$repo != "") {
      params <- str_c("?repo=", input$repo)
      updateQueryString(params, mode = "push")
    }
  })
  
  getDetails <- eventReactive(input$repo, {
    repo <- input$repo
    if (is.null(input$repo) || input$repo == "") {
      # try read from URL if no repo selected in input
      repo <- getQueryString()$repo
    }
    GetRepoDetails(repo)
  })
  
  output$repo_fullname <- renderText({
    repo <- getDetails()$repo
    if (is.null(repo)) {
      "..."
    } else {
      repo
    }
  })
  output$repo_timeline <- renderPlotly({
    PlotRepoTimeline(getDetails()$repo)
  })
  output$repo_detail <- renderUI({
    RenderRepoDetails(getDetails())
  })
  output$repo_meta <- renderUI({
    RenderRepoMeta(getDetails())
  })
  output$repo_issues_timeline <- renderPlotly({
    PlotRepoIssueTimeline(getDetails()$repo)
  })
})