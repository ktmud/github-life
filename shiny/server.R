#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinyjs)
library(plotly)

source("include/init.R")
source("repo.R")

# Define server logic required to draw a histogram
shinyServer(function(input, output, session) {
  
  observeEvent(input$repo, {
    output$repo_timeline <- renderPlotly({
      if (is.null(input$repo)) {
        hide("single-repo")
        return(plotly_empty())
      }
      show("single-repo")
      PlotRepoTimeline(input$repo)
    })
  })
  
})
