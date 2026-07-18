# Authorize enphaseR with your Enphase developer application

One-time interactive setup. Opens the Enphase authorization page in your
browser, where you log in with your Enphase homeowner (Enlighten)
account and approve access; Enphase then displays an authorization code
that you paste back into the R console. The code is exchanged for an
access token (valid about a day) and a refresh token (valid about a
month), and both are saved – along with your application credentials –
to the enphaseR config directory with restrictive file permissions.

## Usage

``` r
enphase_authorize(
  client_id = NULL,
  client_secret = NULL,
  api_key = NULL,
  config_dir = NULL
)
```

## Arguments

- client_id, client_secret, api_key:

  Credentials from your application's page at
  <https://developer-v4.enphase.com> (free "Watt" plan is fine). The
  application must be granted access to both "System Details" and "Site
  Level Production Monitoring" when you create it – an application
  missing a category gets a 401 from those endpoints even though its
  credentials are valid. Required the first time; afterward they default
  to the saved values.

- config_dir:

  Directory for credential and token files. Defaults to the
  `ENPHASER_CONFIG_DIR` environment variable if set, otherwise
  `tools::R_user_dir("enphaseR", "config")`.

## Value

`TRUE`, invisibly, on success.

## Details

After this one call, you should never need to authorize in the browser
again *as long as your tokens get refreshed at least monthly*. Every
enphaseR data function refreshes and rotates the token pair before
calling the API, so any scheduled job that runs at least once a month
(daily is typical) keeps authentication alive indefinitely. See
[`vignette("enphaseR")`](https://smach.github.io/enphaseR/articles/enphaseR.md)
for how to set that up.

If the refresh token ever lapses (for example, your machine was off for
over a month), data functions will fail with a message telling you to
re-run this function. On a re-run you can omit all credential arguments
– the saved ones are reused – so recovery is a single no-argument call.

## Examples

``` r
if (FALSE) { # \dontrun{
# First-time setup:
enphase_authorize(
  client_id = "your-client-id",
  client_secret = "your-client-secret",
  api_key = "your-api-key"
)

# Re-authorizing after a lapsed refresh token:
enphase_authorize()
} # }
```
