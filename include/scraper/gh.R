# make tokens a list, so we can save extra info such as rate limit
.tokens <- Sys.getenv("GITHUB_TOKENS") %>% str_trim() %>%
  str_split("\\s+", simplify = TRUE) %>%
  as.character()
tokens <- as.list(rep(NA, length(.tokens)))
names(tokens) <- .tokens
tokens[1:length(tokens)] <- map(.tokens, function(x) {
  list(token = x)
})
token_i <- 0  # index of current token in use

GetAToken <- function(tried = list()) {
  # Get a new token to use. Will check rate limit automatically.
  #  1. pick tokens in turn from the tokens list
  #  1. if rate limit has reached, try next new token
  #  2. if all token's rate limit reached, wait until the shortest one
  #     is done
  
  # if current token has reached the end of the list
  # start from the beginning
  if (token_i == length(tokens)) {
    token_i <<- 0
  }
  token_i <<- token_i + 1
  token <- tokens[[token_i]]
  tried[[token$token]] <- token
  
  # if this token needs to wait, try another one
  if (!is.null(token$remaining) && token$remaining < length(tokens) * 1.5 &&
      token$wait_until > Sys.time()) {
    # if already tried the last one
    # get the one with minimal wait time and do the wait
    if (length(tried) == length(tokens)) {
      token <- tried[[which.min(map(tried, function(x) x$wait_until))]]
      # time difference in seconds
      wait_secs <- (token$wait_until - Sys.time()) %>%
        as.numeric(units = "secs") %>% max(0)
      message("")  # An empty new line to separate this message with others
      message("> rate limit reached, wait for ", wait_secs, " secs.")
      Sys.sleep(wait_secs)
      # waited enough time, reset this token's wait time
      tokens[[token$token]] <<- list(token = token$token)
    } else {
      token <- tokens[[GetAToken(tried = tried)]]
    }
  }
  
  # return the token in use
  token$token
}

.SaveRateLimit <- function(token, res = NULL, response = NULL) {
  if (is.null(response)) {
    response <- attr(res, "response")
  }
  if (is.null(response)) {
    stop("Must provide response headers")
  }
  remaining <- as.integer(response$`x-ratelimit-remaining`)
  wait_until <- as.integer(response$`x-ratelimit-reset`) %>%
    as.POSIXct(origin="1970-01-01", tz = "UTC")
  tokens[[token]] <<- list(
    token = token,
    remaining = remaining,
    wait_until = wait_until
  )
}

# the names of these two function are in consistent with what are in `gh`
gh_has_next <- function(res) {
  # A mask for the internal function of `gh`
  # indicate whether a response has a next page
  !is.na(next_page(res))
}
next_page <- function(res) {
  # get the URL for next page
  response <- attr(res, "response")
  if (is.null(response$link)) return(NA)
  str_match(response$link, '<(.*?)>; rel="next"')[1, 2] %>%
    # remove hostname prefix
    str_replace("https://api.github.com/", "")
}


gh <- function(..., verbose = FALSE, retry_count = 0) {
  # GH function with ratelimit. Overriding the function
  # is necessary because we want to handle pagination manually.
  # Args:
  #   verbose - whethere to print debug messages
  # All others arguments are the same as `gh`
  # Return:
  #   NULL - when resource is not available
  #       (either deleted or blocked by github)
  #   otherwise just a `gh_list` object that's basically a json
  
  args <- list(...)
  # default limit is Inf
  .limit <- ifelse(is.null(args$.limit), Inf, args$.limit)
  
  token <- GetAToken()
  args$.token <- token
  args$.limit <- NULL  # clear `.limit`` for raw `gh` method
  args$per_page <- 100  # always request maximum number of data
  
  err <- NULL
  err_full <- NULL
  tryCatch({
    res <- do.call(gh::gh, args)
  }, error = function(x) {
    err_full <<- x
    if (is.list(x$headers)) {
      err <<- x$headers$status
      .SaveRateLimit(token, response = x$headers)
    } else {
      err <<- x
    }
  })
  gh_err <<- err_full
  # handle exceptions
  if (!is.null(err)) {
    # Acceptable failures returns NULL
    # 404: Not Found
    # 451: Blocked
    err <- as.character(err)
    if (err %in% c("404", "404 Not Found")) {
      # message("Not Found")
      return()
    }
    if (err == "451") {
      # message("Resource Blocked")
      return()
    }
    if (err == "403 Forbidden") {
      # if we see 403, but there are still remaining requests
      # then this is the repo's fault, just return non data for it
      if (tokens[[token]]$remaining > 0) {
        return()
      } 
    }
    # if 403 or 500, retry
    if (err %in% c("403", "403 Forbidden", "500", "500 Internal Server Error")) {
      # all tokens tried, stop
      if (retry_count > length(tokens)) {
        stop(err)
      }
      return(gh(..., verbose = verbose, retry_count = retry_count + 1))
    }
    # other types of errors, we let it fail, but will
    # try to save rate limit first
    stop(err)
  }
  
  # we are rewriting this .limit logic because we need to
  # check rate limit here
  while (!is.null(.limit) && length(res) < .limit && gh_has_next(res)) {
    if (verbose) message("Fetching: ", next_page(res))
    # save rate limit first
    .SaveRateLimit(token, res)
    # get a new token
    new_token <- GetAToken()
    if (new_token != token) {
      headers <- attr(res, ".send_headers")
      headers["Authorization"] <- str_c("token ", new_token)
      attr(res, ".send_headers") <- headers
      token <- new_token
    }
    res2 <- gh::gh_next(res)
    res3 <- c(res, res2)
    attributes(res3) <- attributes(res2)
    res <- res3
  }
  
  # save rate limit for the last page request
  .SaveRateLimit(token, res)
  
  if (!is.null(.limit) && length(res) > .limit) {
    res_attr <- attributes(res)
    res <- res[seq_len(.limit)]
    attributes(res) <- res_attr
  }
  res
}

.ScrapeAndSave <- function(category, scraper) {
  # Generate a function to scrape and save to a local file
  # Return:
  #  a scraper function that returns
  #  if file exists
  #    -1
  #  else if resource unavailable on github
  #    NULL
  #  else
  #    number of records scraped
  #  whose first two parameters will always be `repo` and `skip_existing`
  return(function(repo, skip_existing = TRUE, ...) {
    fpath <- fname(repo, category)
    fsize <- file.size(fpath)
    # if ths file exists and size is not zero, skip
    if (skip_existing && !is.na(fsize) && fsize != 0) {
      return(-1)
    }
    dat <- scraper(repo, ...)
    # return NULL if resource not available
    if (is.null(dat)) return()
    # only save data when there is data
    n <- attr(dat, "real_n")
    if (is.null(n)) {
      n <- nrow(dat)
    }
    if (n > 0) {
      # last_dat <<- dat
      # last_path <<- fpath
      write_csv(dat, fpath)
    }
    return(n)
  })
}