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
  
  getDetails <- eventReactive(input$repo, {
    GetRepoDetails(input$repo)
  })
  
  output$repo_fullname <- renderText({
    if (input$repo == "") {
      "..."
    } else {
      input$repo
    }
  })
  output$repo_timeline <- renderPlotly({
    PlotRepoTimeline(input$repo)
  })
  output$repo_detail <- renderUI({
    RenderRepoDetails(getDetails())
  })
  output$repo_meta <- renderUI({
    RenderRepoMeta(getDetails())
  })
  output$repo_issues_timeline <- renderPlotly({
    PlotRepoIssueTimeline(input$repo)
  })
})