# == Sidebar ----------------------
sidebar <- dashboardSidebar(
  sidebarMenu(
    menuItem(
      "Overview",
      icon = icon("globe"),
      tabName = "overview"
    ),
    menuItem(
      selected = TRUE,
      "Explore a repository", icon = icon("book"), tabName = "single-repo"
    ),
    menuItem(
      "Repository Groups", icon = icon("git"),
      tabName = "repo"
    ),
    menuItem("People", icon = icon("users"), tabName = "usr"),
    menuItem("Organizations", icon = icon("sitemap"), tabName = "org")
  )
)

# === Main body ----------
library(rmarkdown)
render("www/overview.Rmd", html_fragment(), quiet = TRUE)

repo_tab <- fluidRow(
  column(
    width = 12,
    h2("Explore different repository groups"),
    p("A few fun facts about our top repositories.")
  )
)

single_repo_tab <- div(
  fluidRow(
    column(
      width = 6,
      class = "col-lg-4",
      box(
        width = NULL,
        selectizeInput(
          "repo", NULL, NULL,
          selected = "twbs/bootstrap",
          options = list(
            maxOptions = 100,
            valueField = 'repo',
            labelField = 'repo',
            create = FALSE,
            searchField = c("repo", "description"),
            render = I(read_file("www/selectize_render.js")),
            placeholder = "Pick a repository..."
          )
        ),
        uiOutput("repo_meta")
      )
    ),
    column(
      width = 6,
      class = "col-lg-8",
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
    tabItem(
      tabName = "overview",
      div(class = "readable", HTML(read_file("www/overview.html")))
    ),
    tabItem(tabName = "repo", repo_tab),
    tabItem(tabName = "single-repo", single_repo_tab),
    tabItem(tabName = "usr", h2("People")),
    tabItem(tabName = "org", h2("Organizations")
    )
  ),
  tags$script(read_file("www/app.js"))
)

shiny_ui <- dashboardPage(
  title = "Github Life",
  dashboardHeader(title = div(
    icon("github-alt"),
    "GitHub Life"
  )),
  sidebar,
  body
)