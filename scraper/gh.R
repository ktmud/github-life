# set this to the directory you want (in environment variable)
kDataDir <- Sys.getenv("GITHUB_DATA_DIR")
if (kDataDir == "") {
  # set default data directory
  kDataDir <- "./github_data"
}
fname <- function(repo, category, ext = ".txt") {
  # generate the local file name for
  # indicating whether a data point has been scraped
  dname <- file.path(kDataDir, category)
  if (!dir.exists(dname)) {
    dir.create(dname, recursive = TRUE)
  }
  file.path(dname, str_c(str_replace(repo, "/", " - "), ext))
}

# Read the list of available GitHub tokens form sys env.
# make tokens a list object, so we can save extra info such as
# rate limit stored with it.
if (!exists("tokens")) {
  .tokens <- Sys.getenv("GITHUB_TOKENS") %>%
    str_trim() %>%
    str_split("\\s+", simplify = TRUE) %>%
    as.character()
  tokens <- as.list(rep(NA, length(.tokens)))
  names(tokens) <- .tokens
  tokens[1:length(tokens)] <- map(.tokens, function(x) {
    list(token = x)
  })
}

# index of current token in use
# each process should begin with a random token
# set NULL to make sure each time the process restart
# we have a random token randomized
set.seed(NULL)
token_i <- sample(1:length(tokens) - 1, 1)

# number of workers running coccurently
n_workers <- .GlobalEnv$n_workers
if (is.null(n_workers)) n_workers <- 1

# interval between each request, only applies to pagination requests
# -0.2s is the average time cost for each request to finish,
sleep_length <- max(0, 60*60 / 5000 / length(tokens) * n_workers - 0.2)

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
  tk <- tokens[[token_i]]
  tried[[tk$token]] <- tk
  
  # if this token needs to wait, try another one
  if (.TokenLimitReached(tk)) {
    # if already tried the last one
    # get the one with minimal wait time and do the wait
    if (length(tried) == length(tokens)) {
      tk <- tried[[which.min(map(tried, function(x) x$wait_until))]]
      # time difference in seconds
      wait_secs <- (tk$wait_until - Sys.time()) %>%
        as.numeric(units = "secs") %>% max(0)
      msg("\n> rate limit reached, wait for ", wait_secs, " secs.")
      Sys.sleep(wait_secs)
      # waited enough time, reset this token's wait time
      tokens[[tk$token]] <<- list(token = tk$token)
    } else {
      tk <- tokens[[GetAToken(tried = tried)]]
    }
  }
  # return the string of token in use
  tk$token
}

.TokenLimitReached <- function(tk) {
  if (is.null(tk$remaining) || is.na(tk$remaining)) return(FALSE)
  if (length(tk$wait_until) == 0 || is.na(tk$wait_until)) return(FALSE)
  # if the wait until time is earlier than now, reset this token
  if (tk$wait_until < Sys.time()) {
    tokens[[tk$token]] <<- list(token = tk$token)
    return(FALSE)
  }
  tk$remaining < (length(tokens) * n_workers)
}

.SaveRateLimit <- function(token, res = NULL, response = NULL) {
  if (is.null(response)) {
    response <- attr(res, "response")
  }
  if (is.null(response)) {
    stop("Must provide response headers")
  }
  if (is.null(response$`x-ratelimit-reset`)) {
    # no information found, skip
    msg("BAD reseponse for rate limit check:", response, "\n")
    return(FALSE)
  }
  remaining <- as.integer(response$`x-ratelimit-remaining`)
  # XXX: for debug
  # if (token_i %% 2 == 0)   remaining <- 1
  # save wait until time to real time, +10s to accomodate
  # time difference between github and our server
  wait_until <- (as.integer(response$`x-ratelimit-reset`) + 10) %>%
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
  if (is.null(response$link)) {
    return(NA)
  }
  str_match(response$link, '<(.*?)>; rel="next"')[1, 2] %>%
    # remove hostname prefix
    str_replace("https://api.github.com/", "")
}


gh <- function(..., verbose = FALSE, retry_count = 0) {
  # GH function with ratelimit. Overriding the function
  # is necessary because we want to handle pagination manually.
  # Args:
  #   verbose - whethere to print debug msgs
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
  
  handle_error <- function(x) {
    if (is.list(x$headers)) {
      err <<- x$headers$status
      .SaveRateLimit(token, response = x$headers)
    } else {
      err <<- x
    }
    # export the last error to globals
    assign("gh_err_full", x, envir = .GlobalEnv)
    msg("\nError for ", args[[2]], ": ", err)
    msg(x)
  }
  
  tryCatch({
    res <- do.call(gh::gh, args)
    # save rate limit whenever we had a response
    .SaveRateLimit(token, res)
  }, error = handle_error)
  
  # handle exceptions
  if (!is.null(err)) {
    # Acceptable failures returns NULL
    # 404: Not Found
    # 451: Blocked
    err <- as.character(err)
    if (err %in% c("404", "404 Not Found")) {
      # msg("Not Found")
      return()
    }
    if (err == "451") {
      # msg("Resource Blocked")
      return()
    }
    if (err %in% c("403", "403 Forbidden")) {
      # if we see 403, but there are still remaining requests
      # then this is the repo's fault, just return non data for it
      if (tokens[[token]]$remaining > 0) {
        return()
      } 
    }
    # if 403, 500 or 502, retry
    if (err %in% c("403", "403 Forbidden",
                   "500", "500 Internal Server Error",
                   "502", "502 Server Error")) {
      # all tokens tried, stop
      if (retry_count > length(tokens)) {
        # return NULL
        # don't break the flow
        return()
      }
      msg("Retry:", retry_count + 1)
      Sys.sleep(10)
      # each retry will get a new token
      return(gh(..., verbose = verbose, retry_count = retry_count + 1))
    }
    # other types of errors, we've warned about the error,
    # So sleep for a while, and return empty values
    Sys.sleep(30)
    return()
  }
  
  retry_count <- 0
  
  # we are rewriting this .limit logic because we need to
  # check rate limit here
  while (!is.null(.limit) && length(res) < .limit && gh_has_next(res)) {
    if (verbose) {
      msg("Fetch: ", next_page(res))
    }
    # get a new token
    new_token <- GetAToken()
    if (new_token != token) {
      headers <- attr(res, ".send_headers")
      headers["Authorization"] <- str_c("token ", new_token)
      attr(res, ".send_headers") <- headers
      token <- new_token
    }
    Sys.sleep(sleep_length)
    res2 <- NULL
    tryCatch({
      res2 <- gh::gh_next(res)
    }, error = handle_error)
    
    # if return is NULL, means request failed
    if (is.null(res2)) {
      if (retry_count < length(tokens)) {
        # this will go back to the beginning of the loop
        # and try to get a new token. If no token is available,
        # it will always wait.
        retry_count <- retry_count + 1
        next
      } else if (is.atomic(res) || length(res) < 1000) {
        # if not every page is successful, and the data are small
        # we might just discard the data any way
        return()
      } else {
        # otherwise we might just as well bear with what we have
        return(res)
      }
    }
    res3 <- c(res, res2)
    attributes(res3) <- attributes(res2)
    res <- res3
    .SaveRateLimit(token, res)
  }
  
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
  
  # check whether the function supports a `since` argument
  has_since <- any(str_detect(attr(scraper, "srcref"), "since *="))
  
  return(function(repo, skip_existing = TRUE,
                  l_name = NULL, l_n = 5, ...) {
    fpath <- fname(repo, category)
    fexists <- file.exists(fpath)
    
    if (!has_since && skip_existing && fexists) {
      if (!is.null(l_name)) {
        cat(pad(".", l_n), l_name)
      }
      return(-1)
    }
    
    if (has_since) {
      since <- "1970-01-01T00:00:00Z"
      if (fexists) {
        since <- read_file(fpath)
        # if file content is all numeric numbers,
        # then from legacy files
        # use file mtime as the since time
        if (str_length(since) != 20) {
          since <- (as.POSIXlt(file.mtime(fpath), tz = "UTC") - seconds(60)) %>%
            format("%Y-%m-%dT%H:%M:%SZ")
        }
      }
      dat <- scraper(repo, since = since)
    } else {
      dat <- scraper(repo)
    }
    
    # return NULL if resource not available
    if (is.null(dat)) {
      if (!is.null(l_name)) msg("(X) GONE.  ")
      return()
    }
    # only save data when there is data
    n <- attr(dat, "real_n")
    if (is.null(n)) {
      n <- nrow(dat)
    }
    if (is.null(n)) {
      msg("(x) BAD data returns")
      return()
    }
    if (n > 0) {
      # save data to database.
      db_save(str_c("g_", category), dat)
      # write the number to a local file,
      # this file will be used to determine whether this data point
      # has been scraped.
      last_item_date <- sort(dat$created_at) %>% last()
      if (is.null(last_item_date)) last_item_date <- Sys.time()
      last_item_date <- (ymd_hms(last_item_date)) %>%
        format("%Y-%m-%dT%H:%M:%SZ")
      write_file(last_item_date, fpath)
      # write_file(as.character(n), fpath)
    }
    if (!is.null(l_name)) {
      cat(pad(n, l_n), l_name)
    }
    return(n)
  })
}