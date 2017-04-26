source("shiny/repo.R")

repo_choices <- available_repos

# Define server logic required to draw a histogram
shiny_server <- shinyServer(function(input, output, session) {
  observeEvent(input$repo, {
    if (input$repo != "") {
      output$repo_fullname <- renderText(input$repo)
    }
    if (input$repo %in% repo_choices$repo) {
      details <- GetRepoDetails(input$repo)
      output$repo_detail <- renderUI(RenderRepoDetails(details))
      output$repo_meta <- renderUI(RenderRepoMeta(details))
      output$repo_timeline <- renderPlotly({
        PlotRepoTimeline(input$repo)
      })
    }
  })
  
  output$repo_fullname <- renderUI(span("..."))
  output$repo_detail <- renderUI(div(
    class = "repo-detail-placeholder",
    "Please select a repository from the dropdown on the left."
  ))
  
  updateSelectizeInput(
    session, 'repo',
    choices = repo_choices,
    server = TRUE
  )
})