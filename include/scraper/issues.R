
SaveUsers <- function(items) {
  users <- items %>%
    map(function(user) {
      if (is.null(user)) return(NULL)
      c(id = user$id, login = user$login)
    }) %>%
    do.call(rbind, .) %>%
    as.data.frame() %>%
    distinct()
  SaveToTable("g_users", users)
}

ScrapeIssues <- function(repo, save_users = TRUE, ...) {
  # Scrape issues of all repo
  res <- gh(str_c("/repos/", repo, "/issues"), ...)
  last_res <<- res
  
  # empty string
  if (length(res) == 0 || is.null(names(res[[1]]))) {
    # return an empty data frame if no data available
    return(data.frame())
  }
  
  if (save_users) {
    SaveUsers(map(res, function(x) x$user))
  }
  
  res %>%
    map(function(x) {
      c(id = x$id,
        repo = repo,
        reporter_id = x$user$id, 
        # also save `login` for easier table joins
        reporter_login = safe_val(x$user$login),
        number = safe_val(x$number),
        title = safe_val(x$title),
        state = safe_val(x$state),
        comments = safe_val(x$comments),
        created_at = parse_datetime(x$created_at),
        updated_at = parse_datetime(x$updated_at),
        closed_at = parse_datetime(x$closed_at),
        is_pull_request = ifelse(is.null(x$pull_request), 0, 1))
    }) %>%
    do.call(rbind, .) %>%
    as.data.frame() %>%
    distinct(id, .keep_all = TRUE)
}

ScrapeIssueEvents <- function(repo, save_users = TRUE, ...) {
  # Scrape issues of all repo
  res <- gh(str_c("/repos/", repo, "/issues/events"), ...)
  
  if (length(res) == 0 || is.null(names(res[[1]]))) {
    # return an empty data frame if no data available
    return(data.frame())
  }
  
  if (save_users) {
    # save users concorrently
    SaveUsers(map(res, function(x) x$actor))
  }
  # return the issue events list
  evts <- map(res, function(x) {
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
    # still must add distinc restriction, just in case new events
    # were created while pagination
    filter(!is.na(actor_id) & !is.na(issue_id)) %>%
    distinct(id, .keep_all = TRUE)
  evts
}
