#
# Languages
#
ScrapeLanguages <- .ScrapeAndSave("languages", function(repo, ...) {
  dat <- gh("/repos/:repo/languages", repo = repo)
  if (is.null(dat)) return()
  # return empty data frame if no data available
  if (is.atomic(dat) || length(dat) == 0) return(data.frame())
  dat %<>% as_tibble() %>% t()
  tibble(
    repo = repo,
    lang = rownames(dat),
    size = dat[,1]
  )
})
ScrapeLanguages("twbs/bootstrap")