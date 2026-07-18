# Internal request machinery for the Enphase API v4.

# Build an authenticated GET request. `auth` is the list returned by
# enphase_refresh_tokens(); `path` is a vector of path segments appended
# after /api/v4. Building is separate from performing so tests can inspect
# requests without network access. Both auth headers are redacted so they
# never appear in printed requests or error output.
enphase_build_request <- function(auth, path, query = list()) {
  req <- httr2::request(api_base)
  req <- do.call(
    httr2::req_url_path_append,
    c(list(req, "api", "v4"), as.list(as.character(path)))
  )
  req <- httr2::req_headers_redacted(
    req,
    Authorization = paste("Bearer", auth$access_token)
  )
  # The API key goes in the query string, not a header -- sending it as a
  # header yields a 401 with no other explanation.
  query$key <- auth$api_key
  req <- do.call(httr2::req_url_query, c(list(req), query))
  # Surface the API's own message/details in error output -- a bare
  # "HTTP 401" hides whether the problem is the token, the key, or the plan
  req <- httr2::req_error(req, body = function(resp) {
    body <- tryCatch(httr2::resp_body_json(resp), error = function(e) NULL)
    unlist(body[c("message", "details")])
  })
  # 429 (rate limit) and 503 are retried by default, honoring Retry-After
  httr2::req_retry(req, max_tries = 5)
}

# Perform an authenticated GET and return the parsed body. Refreshes tokens
# first unless the caller passes an `auth` it already holds (so a multi-day
# loop refreshes once, not per request).
enphase_api_get <- function(path, query = list(), config_dir = NULL,
                            auth = NULL) {
  if (is.null(auth)) {
    auth <- enphase_refresh_tokens(config_dir)
  }
  resp <- httr2::req_perform(enphase_build_request(auth, path, query))
  httr2::resp_body_json(resp, simplifyVector = TRUE)
}
