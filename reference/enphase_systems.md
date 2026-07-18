# List the Enphase systems your account can access

Most homeowners have exactly one system; this is where to find its
`system_id` for use with
[`enphase_summary()`](https://smach.github.io/enphaseR/reference/enphase_summary.md)
and
[`enphase_production()`](https://smach.github.io/enphaseR/reference/enphase_production.md).

## Usage

``` r
enphase_systems(config_dir = NULL)
```

## Arguments

- config_dir:

  Directory for credential and token files. Defaults to the
  `ENPHASER_CONFIG_DIR` environment variable if set, otherwise
  `tools::R_user_dir("enphaseR", "config")`.

## Value

A tibble with one row per system, including `system_id`, `name`,
`status`, and other fields returned by the API.

## Examples

``` r
if (FALSE) { # \dontrun{
enphase_systems()
} # }
```
