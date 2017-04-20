library(shinydashboard)
library(plotly)
library(rmarkdown)
library(readr)

# render("overview.rmd", html_fragment())

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
    box(
      width = 12,
      title = "Search a repository",
      textInput("repo", NULL, value = "integrity/integrity",
                placeholder = "owner/repo")
    )
  ),
  div(
    id = "single-repo",
    fluidRow(
      box(
        width = 6,
        title = "Activity Timeline",
        plotlyOutput("repo_timeline")
      )
    )
  )
)

body <- dashboardBody(
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
  dashboardHeader(title = "GitHub Life"),
  sidebar,
  body
)