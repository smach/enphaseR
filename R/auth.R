#' Authorize enphaseR with your Enphase developer application
#'
#' One-time interactive setup. Opens the Enphase authorization page in your
#' browser, where you log in with your Enphase homeowner (Enlighten) account
#' and approve access; Enphase then displays an authorization code that you
#' paste back into the R console. The code is exchanged for an access token
#' (valid about a day) and a refresh token (valid about a month), and both
#' are saved -- along with your application credentials -- to the enphaseR
#' config directory with restrictive file permissions.
#'
#' After this one call, you should never need to authorize in the browser
#' again *as long as your tokens get refreshed at least monthly*. Every
#' enphaseR data function refreshes and rotates the token pair before
#' calling the API, so any scheduled job that runs at least once a month
#' (daily is typical) keeps authentication alive indefinitely. See
#' `vignette("enphaseR")` for how to set that up.
#'
#' If the refresh token ever lapses (for example, your machine was off for
#' over a month), data functions will fail with a message telling you to
#' re-run this function. On a re-run you can omit all credential arguments --
#' the saved ones are reused -- so recovery is a single no-argument call.
#'
#' @param client_id,client_secret,api_key Credentials from your application's
#'   page at <https://developer-v4.enphase.com> (free "Watt" plan is fine).
#'   The application must be granted access to both "System Details" and
#'   "Site Level Production Monitoring" when you create it -- an application
#'   missing a category gets a 401 from those endpoints even though its
#'   credentials are valid. Required the first time; afterward they default
#'   to the saved values.
#' @param config_dir Directory for credential and token files. Defaults to
#'   the `ENPHASER_CONFIG_DIR` environment variable if set, otherwise
#'   `tools::R_user_dir("enphaseR", "config")`.
#'
#' @return `TRUE`, invisibly, on success.
#' @export
#'
#' @examples
#' \dontrun{
#' # First-time setup:
#' enphase_authorize(
#'   client_id = "your-client-id",
#'   client_secret = "your-client-secret",
#'   api_key = "your-api-key"
#' )
#'
#' # Re-authorizing after a lapsed refresh token:
#' enphase_authorize()
#' }
enphase_authorize <- function(client_id = NULL, client_secret = NULL,
                              api_key = NULL, config_dir = NULL) {
  if (!interactive()) {
    stop(
      "enphase_authorize() needs an interactive R session so you can paste ",
      "the authorization code from your browser.",
      call. = FALSE
    )
  }

  creds_file <- credentials_path(config_dir)

  # Reuse saved credentials when none are supplied, so re-authorizing after
  # a lapsed refresh token is a single no-argument call
  if (is.null(client_id) || is.null(client_secret) || is.null(api_key)) {
    if (file.exists(creds_file)) {
      saved <- jsonlite::read_json(creds_file)
      if (is.null(client_id)) client_id <- saved$client_id
      if (is.null(client_secret)) client_secret <- saved$client_secret
      if (is.null(api_key)) api_key <- saved$api_key
    }
  }
  if (is.null(client_id) || is.null(client_secret) || is.null(api_key)) {
    stop(
      "client_id, client_secret, and api_key are all required the first ",
      "time you authorize. Find them on your application's page at ",
      "https://developer-v4.enphase.com.",
      call. = FALSE
    )
  }

  redirect_uri <- paste0(api_base, "/oauth/redirect_uri")
  auth_url <- paste0(
    api_base, "/oauth/authorize",
    "?response_type=code",
    "&client_id=", client_id,
    "&redirect_uri=", redirect_uri
  )

  message(
    "Opening the Enphase authorization page in your browser.\n",
    "Log in with your Enphase homeowner (Enlighten) account, approve ",
    "access,\nand copy the authorization code it displays."
  )
  utils::browseURL(auth_url)

  code <- trimws(readline("Paste the authorization code here: "))
  if (!nzchar(code)) {
    stop("No authorization code entered; nothing was saved.", call. = FALSE)
  }

  resp <- tryCatch(
    httr2::request(paste0(api_base, "/oauth/token")) |>
      httr2::req_method("POST") |>
      httr2::req_auth_basic(client_id, client_secret) |>
      httr2::req_url_query(
        grant_type = "authorization_code",
        code = code,
        redirect_uri = redirect_uri
      ) |>
      httr2::req_perform(),
    httr2_http = function(e) {
      stop(
        "Enphase rejected the authorization code. Codes are single-use and ",
        "short-lived, so re-run enphase_authorize() and paste a fresh one. ",
        "Also double-check the client_id and client_secret.",
        call. = FALSE
      )
    }
  )

  tokens <- httr2::resp_body_json(resp)
  write_json_secure(
    list(client_id = client_id, client_secret = client_secret,
         api_key = api_key),
    creds_file
  )
  write_json_secure(tokens, tokens_path(config_dir))

  message(
    "Authorization complete. Credentials and tokens saved to ",
    enphase_config_dir(config_dir)
  )
  invisible(TRUE)
}

#' Refresh and rotate the saved Enphase tokens
#'
#' Exchanges the saved refresh token for a new access/refresh token pair and
#' saves the rotated pair back to disk. Access tokens last about a day and
#' refresh tokens about a month, so refreshing on every run -- which all
#' enphaseR data functions do automatically -- keeps both perpetually fresh.
#' You only need to call this directly if you want a scheduled job to keep
#' tokens alive without fetching any data.
#'
#' @inheritParams enphase_authorize
#'
#' @return Invisibly, a list with elements `access_token` and `api_key`,
#'   suitable for authenticating API requests.
#' @export
#'
#' @examples
#' \dontrun{
#' enphase_refresh_tokens()
#' }
enphase_refresh_tokens <- function(config_dir = NULL) {
  creds <- read_json_file(credentials_path(config_dir), "credentials")
  tokens <- read_json_file(tokens_path(config_dir), "tokens")

  resp <- tryCatch(
    httr2::request(paste0(api_base, "/oauth/token")) |>
      httr2::req_method("POST") |>
      httr2::req_auth_basic(creds$client_id, creds$client_secret) |>
      httr2::req_url_query(
        grant_type = "refresh_token",
        refresh_token = tokens$refresh_token
      ) |>
      httr2::req_retry(max_tries = 3) |>
      httr2::req_perform(),
    httr2_http = function(e) {
      stop(
        "Enphase rejected the token refresh. The refresh token has likely ",
        "expired (they last about a month) -- run enphase_authorize() to ",
        "re-authorize in the browser, then try again.",
        call. = FALSE
      )
    }
  )

  new_tokens <- httr2::resp_body_json(resp)
  write_json_secure(new_tokens, tokens_path(config_dir))

  # read_json()/resp_body_json() return length-1 lists, not strings; coerce
  # so callers can use these directly as header and query values
  invisible(list(
    access_token = as.character(new_tokens$access_token),
    api_key = as.character(creds$api_key)
  ))
}
