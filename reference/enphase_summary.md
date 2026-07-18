# Get a summary of one system's current status and lifetime production

Get a summary of one system's current status and lifetime production

## Usage

``` r
enphase_summary(system_id, config_dir = NULL)
```

## Arguments

- system_id:

  The system's numeric ID, from
  [`enphase_systems()`](https://smach.github.io/enphaseR/reference/enphase_systems.md).

- config_dir:

  Directory for credential and token files. Defaults to the
  `ENPHASER_CONFIG_DIR` environment variable if set, otherwise
  `tools::R_user_dir("enphaseR", "config")`.

## Value

A one-row tibble of the system's summary fields, such as
`current_power`, `energy_today`, `energy_lifetime`, and `status`.

## Examples

``` r
if (FALSE) { # \dontrun{
enphase_summary(system_id = 1234567)
} # }
```
