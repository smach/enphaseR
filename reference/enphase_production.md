# Fetch 15-minute solar production intervals for one or more days

Retrieves production-meter telemetry from the Enphase API, one request
per day in the range, and returns all intervals as a single tidy tibble.
The API serves past dates, so missed days can be backfilled by widening
the range.

## Usage

``` r
enphase_production(
  system_id,
  start_date = Sys.Date() - 1,
  end_date = start_date,
  tz = "America/New_York",
  config_dir = NULL
)
```

## Arguments

- system_id:

  The system's numeric ID, from
  [`enphase_systems()`](https://smach.github.io/enphaseR/reference/enphase_systems.md).

- start_date, end_date:

  The date range to fetch (inclusive). Anything
  [`as.Date()`](https://rdrr.io/r/base/as.Date.html) understands. Both
  default to yesterday.

- tz:

  Time zone of the system's location, used to define each day's midnight
  boundary and to display interval times.

- config_dir:

  Directory for credential and token files. Defaults to the
  `ENPHASER_CONFIG_DIR` environment variable if set, otherwise
  `tools::R_user_dir("enphaseR", "config")`.

## Value

A tibble with one row per 15-minute interval: `date`, `end_at` (the
interval's end time as a POSIXct in `tz`), and `wh_del` (watt-hours
delivered). Saving is up to you – e.g. `readr::write_csv()` or
[`saveRDS()`](https://rdrr.io/r/base/readRDS.html) on the result.

## Details

A full day has 96 fifteen-minute intervals. When the API returns fewer –
typically because Enphase hasn't finished reporting a very recent day –
the function keeps what it got and warns, so you can re-fetch that day
later.

Values come from the site's revenue-grade production meter. Enphase also
records production as reported by the microinverters themselves, which
typically differs by around 1% because the two measure at different
points in the system. The Enlighten app/website may display either
source, so expect small discrepancies between these totals and the app.

The free "Watt" developer plan allows 1,000 requests per month and 10
per minute. One request is made per day in the range; for ranges longer
than 10 days the function paces itself to stay under the per-minute
limit, and rate-limited responses are retried automatically.

## Examples

``` r
if (FALSE) { # \dontrun{
# Yesterday's production:
enphase_production(system_id = 1234567)

# Backfill a month:
enphase_production(1234567, start_date = "2026-06-01",
                   end_date = "2026-06-30")
} # }
```
