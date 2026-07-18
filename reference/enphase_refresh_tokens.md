# Refresh and rotate the saved Enphase tokens

Exchanges the saved refresh token for a new access/refresh token pair
and saves the rotated pair back to disk. Access tokens last about a day
and refresh tokens about a month, so refreshing on every run – which all
enphaseR data functions do automatically – keeps both perpetually fresh.
You only need to call this directly if you want a scheduled job to keep
tokens alive without fetching any data.

## Usage

``` r
enphase_refresh_tokens(config_dir = NULL)
```

## Arguments

- config_dir:

  Directory for credential and token files. Defaults to the
  `ENPHASER_CONFIG_DIR` environment variable if set, otherwise
  `tools::R_user_dir("enphaseR", "config")`.

## Value

Invisibly, a list with elements `access_token` and `api_key`, suitable
for authenticating API requests.

## Examples

``` r
if (FALSE) { # \dontrun{
enphase_refresh_tokens()
} # }
```
