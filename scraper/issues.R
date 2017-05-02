
ScrapeIssues <-
  .ScrapeAndSave("issues", function(repo,
                                    state = "all",
                                    direction = "asc",
                                    ...) {
  # Scrape all issues of a repo
  # Use direction `asc` to always scrape the latest items last
  dat <- gh("/repos/:repo/issues", repo = repo,
            state = state, direction = direction, ...)
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
        # text body increases data size and
        # slowing down insertions tremendously,
        # maybe we dont really need it
        body = safe_val(x$body)
        )
    }) %>%
    do.call(rbind, .) %>%
    as_tibble() %>%
    distinct(id, .keep_all = TRUE)
}, TRUE)

ScrapeIssueEvents <- .ScrapeAndSave("issue_events",
                                    function(repo, ...) {
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
    as_tibble() %>%
    # XXX: filter out bad rows!
    filter(!is.na(actor_id) & !is.na(issue_id)) %>%
    distinct(id, .keep_all = TRUE)
})

get_issue_number <- function(x) {
  safe_val(x$issue_url) %>%
    str_match("/issues/([0-9]+)") %>%
    .[1, 2] %>% as.integer()
}
ScrapeIssueComments <- .ScrapeAndSave("issue_comments",
                                      function(repo,
                                               direction = "asc",
                                               ...) {
                                        
  # Scrape all issue commens of a repo
  dat <- gh("/repos/:repo/issues/comments", repo = repo,
            direction = direction, ...)
  if (is.null(dat)) return()
  if (length(dat) == 0 || is.atomic(dat)) return(data.frame())
  dat %>%
    map(function(x) {
      # the order here must in line with the schema
      c(id = x$id,
        issue_number = get_issue_number(x),
        user_id = x$user$id, 
        created_at = parse_datetime(x$created_at),
        repo = repo,
        user_login = safe_val(x$user$login),
        updated_at = parse_datetime(x$updated_at),
        body = safe_val(x$body))
    }) %>%
    do.call(rbind, .) %>%
    as_tibble() %>%
    distinct(id, .keep_all = TRUE)
}, TRUE)
