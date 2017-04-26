library(shinydashboard)
library(plotly)
library(rmarkdown)
library(readr)

render("overview.rmd", html_fragment())

# == Sidebar ----------------------
sidebar <- dashboardSidebar(
  sidebarMenu(
    # menuItem(
    #   "Overview",
    #   icon = icon("globe"),
    #   tabName = "overview"
    # ),
    menuItem(
      "Repositories", icon = icon("github"),
      menuItem(
        "Overview", icon = icon("git-square"), tabName = "repo"
      ),
      menuItem(
        selected = TRUE,
        "Explore a repo", icon = icon("git"), tabName = "single-repo"
      )
    ), 
    menuItem("People", icon = icon("users"), tabName = "usr"),
    menuItem("Organizations", icon = icon("sitemap"), tabName = "org")
  )
)

# === Main body ----------

overview_tab <- fluidRow(
  div(class = "readable", HTML(read_file("overview.html")))
)
repo_tab <- fluidRow(
  box(
    width = 12,
    HTML(read_file("overview.html"))
  )
)

single_repo_tab <- div(
  fluidRow(
    column(
      width = 4,
      style = "margin-right:-15px;",
      box(
        width = NULL,
        selectizeInput(
          "repo", NULL, NULL,
          options = list(
            maxOptions = 50,
            valueField = 'repo',
            labelField = 'repo',
            create = FALSE,
            searchField = c("owner_login", "name", "description"),
            render = I(read_file("selectize_render.js")),
            placeholder = "Select your repository..."
          )) 
      )
    ),
    column(
      width = 8,
      box(
        width = NULL,
        uiOutput("repo_detail")
      )
    )
  ),
  fluidRow(
    column(
      width = 12,
      box(
        width = NULL,
        id = "repo-activity",
        title = div(
          "Activity timeline of",
          htmlOutput("repo_fullname", container = strong)
        ),
        plotlyOutput("repo_timeline", height = "350px"),
        div(class = "info",
          "Number of commits from top contributors and
          number of new issues reported each week.")
      )
    )
  )
)

body <- dashboardBody(
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "style.css")
  ),
  shinyjs::useShinyjs(),
  tabItems(
    tabItem(tabName = "overview",
            h1("Death and Life of Great Open Source Projects"),
            overview_tab),
    tabItem(tabName = "repo", repo_tab),
    tabItem(tabName = "single-repo", single_repo_tab),
    tabItem(tabName = "usr", h2("People")),
    tabItem(tabName = "org", h2("Organizations")
    )
  ),
  HTML("
    <script>
      $('li.treeview').addClass('active')
        .find('.treeview-menu')
        .addClass('menu-open')
    </script>
  ")
)

dashboardPage(
  title = "Death and Life of Great Open Source Projects",
  dashboardHeader(title = "GitHub Life"),
  sidebar,
  body
)