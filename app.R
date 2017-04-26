library(shinydashboard)
library(plotly)
library(readr)
library(shiny)

source("include/init.R")
source("include/db.R")
source("include/helpers.R")
source("shiny/ui.R")
source("shiny/server.R")

shinyApp(shiny_ui,  shiny_server)