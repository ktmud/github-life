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
            searchField = c("name", "repo", "description"),
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
        div(
          class = "info",
          "Number of commits from top contributors and
          number of new issues reported and new stargazers added each week.",
          tags$br(),
          "Number of stargazers are hidden by default, and is scaled with",
          tags$code("n * mean(issues) / mean(stars)"),
          ". The data sometimes is incomplete because GitHub only returns
             40,000 records at most."
        )
      )
    ),
    column(
      width = 12,
      box(
        width = NULL,
        id = "repo-issue-events",
        title = div(
          "Issue events breakdown"
        ),
        plotlyOutput("repo_issue_events", height = "350px"),
        div(
          class = "info",
          'Issue events break down by',
          tags$a(
            href = "https://developer.github.com/v3/issues/events/#events-1",
            "event types"
          ),
          ". Showing up to only 40,000 events."
        )
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
  HTML(read_file("www/disqus.html")),
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