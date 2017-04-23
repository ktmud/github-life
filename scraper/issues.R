# Since we are saving additional user info in each table,
# there is no need to do this any more
# list of users can be generated later in MySQL
# SaveUsers <- function(items) {
#   users <- items %>%
#     map(function(user) {
#       if (is.null(user)) return(NULL)
#       c(id = user$id, login = user$login)
#     }) %>%
#     do.call(rbind, .) %>%
#     as.data.frame() %>%
#     distinct()
#   SaveToTable("users", users)
# }
ScrapeIssues <- .ScrapeAndSave("issues", function(repo, state = "all", ...) {
  # Scrape all issues of a repo
  dat <- gh("/repos/:repo/issues", repo = repo, state = state, ...)
  if (is.null(dat)) return()
  # return empty data frame if no data available
  if (length(dat) == 0 || is.atomic(dat)) return(data.frame())
  dat %>%
    map(function(x) {
      c(id = x$id,
        is_pull_request = ifelse(is.null(x$pull_request), 0, 1),
        repo = repo,
        user_id = x$user$id, 
        # also save `login` for easier table joins
        user_login = safe_val(x$user$login),
        number = safe_val(x$number),
        state = safe_val(x$state),
        comments = safe_val(x$comments),
        created_at = parse_datetime(x$created_at),
        updated_at = parse_datetime(x$updated_at),
        closed_at = parse_datetime(x$closed_at),
        title = safe_val(x$title),
        body = safe_val(x$body))
    }) %>%
    do.call(rbind, .) %>%
    as.data.frame() %>%
    distinct(id, .keep_all = TRUE)
})

ScrapeIssueEvents <- .ScrapeAndSave("issue_events", function(repo, ...) {
  # Scrape all issue events of a repo
  dat <- gh("/repos/:repo/issues/events", repo = repo, ...)
  if (is.null(dat)) return()
  if (length(dat) == 0 || is.atomic(dat)) return(data.frame())
  dat %>%
    map(function(x) {
      # the order here must in line with the schema
      c(id = x$id,
        repo = repo,
        issue_id = safe_val(x$issue$id),
        actor_id = safe_val(x$actor$id),
        actor_login = safe_val(x$actor$login),
        event = safe_val(x$event),
        commit_id = safe_val(x$commit_id),
        created_at = parse_datetime(x$created_at))
    }) %>%
    do.call(rbind, .) %>%
    as.data.frame() %>%
    # XXX: filter out bad rows!
    filter(!is.na(actor_id) & !is.na(issue_id)) %>%
    distinct(id, .keep_all = TRUE)
})

ScrapeIssueComments <- .ScrapeAndSave("issue_comments", function(repo, ...) {
  # Scrape all issue commens of a repo
  dat <- gh(str_c("/repos/", repo, "/issues/comments"), ...)
  if (is.null(dat)) return()
  if (length(dat) == 0 || is.atomic(dat)) return(data.frame())
  dat %>%
    map(function(x) {
      # the order here must in line with the schema
      c(id = x$id,
        issue_id = x$issue_id,
        user_id = x$user$id, 
        created_at = parse_datetime(x$created_at),
        repo = repo,
        user_login = safe_val(x$user$login),
        updated_at = parse_datetime(x$updated_at),
        body = safe_val(x$body))
    }) %>%
    do.call(rbind, .) %>%
    as.data.frame() %>%
    distinct(id, .keep_all = TRUE)
})
