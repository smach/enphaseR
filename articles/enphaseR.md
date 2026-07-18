# Getting started with enphaseR

enphaseR pulls solar production data for your own Enphase system from
the official Enphase Enlighten cloud API (v4). It handles the awkward
part — OAuth authentication — so that after a one-time browser step, a
scheduled job can fetch data forever without you ever logging in again.

Two honest limitations, up front, because they’re built into Enphase’s
API and no package can remove them:

1.  **The first authorization must happen in a browser.** Enphase
    requires you to log in and approve access once.
    [`enphase_authorize()`](https://smach.github.io/enphaseR/reference/enphase_authorize.md)
    walks you through it in a couple of minutes.
2.  **Tokens stay alive only if something refreshes them at least
    monthly.** Access tokens last about a day and refresh tokens about a
    month. enphaseR rotates both on every API call, so any job that runs
    daily or weekly keeps authentication perpetually fresh. But if
    nothing runs for over a month — say, the machine was off — you’ll
    have to repeat the browser step (a single
    [`enphase_authorize()`](https://smach.github.io/enphaseR/reference/enphase_authorize.md)
    call).

## One-time setup

### 1. Create an Enphase developer application

You need three credentials, all free:

1.  Go to <https://developer-v4.enphase.com> and create a **developer
    account** (separate from your homeowner/Enlighten account).
2.  Choose the free **Watt** plan (1,000 API requests per month, 10 per
    minute — plenty for a daily fetch).
3.  Create an **application**, and grant it access to both **System
    Details** and **Site Level Production Monitoring** when asked what
    the application can use. This matters: Enphase checks each endpoint
    against the application’s access list, and an application missing a
    category gets `401 Not authorized to access this resource` from
    those endpoints even with valid credentials.
    [`enphase_systems()`](https://smach.github.io/enphaseR/reference/enphase_systems.md)
    and
    [`enphase_summary()`](https://smach.github.io/enphaseR/reference/enphase_summary.md)
    need System Details;
    [`enphase_production()`](https://smach.github.io/enphaseR/reference/enphase_production.md)
    needs Site Level Production Monitoring. The application’s page shows
    the three values you need: **Client ID**, **Client Secret**, and
    **API Key**.

### 2. Authorize in the browser

In an interactive R session:

``` r

library(enphaseR)

enphase_authorize(
  client_id = "your-client-id",
  client_secret = "your-client-secret",
  api_key = "your-api-key"
)
```

Your browser opens Enphase’s authorization page. Log in with your
**homeowner** (Enlighten) account — the one you use in the Enphase app —
approve access, copy the code it displays, and paste it into the R
console.

That’s it. Credentials and tokens are saved (with restrictive
permissions) to `tools::R_user_dir("enphaseR", "config")`, or wherever
the `ENPHASER_CONFIG_DIR` environment variable or the `config_dir`
argument points.

### 3. Find your system ID

``` r

enphase_systems()
```

Most homeowners have one row; note its `system_id`.

## Fetching production data

[`enphase_production()`](https://smach.github.io/enphaseR/reference/enphase_production.md)
returns a tibble with one row per 15-minute interval: the `date`, the
interval’s end time (`end_at`), and watt-hours delivered (`wh_del`).

``` r

# Yesterday (the default):
prod <- enphase_production(system_id = 1234567)

# A specific day:
enphase_production(1234567, start_date = "2026-06-15")

# A range -- one API request per day, automatically paced to respect
# the free plan's rate limit:
june <- enphase_production(
  1234567,
  start_date = "2026-06-01",
  end_date = "2026-06-30"
)
```

A completed day has 96 intervals. If Enphase hasn’t finished reporting a
recent day you’ll get fewer rows and a warning; just re-fetch that day
later.

Don’t expect the totals to match the Enlighten app exactly. Enphase
records production two ways — the site’s revenue-grade production meter
and the microinverters’ own reports — and the two typically differ by
around 1% because they measure at different points in the system.
[`enphase_production()`](https://smach.github.io/enphaseR/reference/enphase_production.md)
returns the meter values; the app may display either source. A mismatch
of that size isn’t a bug on anyone’s part.

**Saving is up to you** — the result is an ordinary tibble, so use
whatever format you like:

``` r

readr::write_csv(prod, "production.csv")
# or saveRDS(prod, "production.rds"), arrow::write_parquet(), ...
```

There’s also `enphase_summary(system_id)` for a one-row snapshot of
current power, today’s energy, and lifetime production.

## Automating it (so you never re-authenticate)

The whole point: Schedule a small script that runs daily. Every run
refreshes and rotates the tokens as a side effect, which keeps
authentication alive indefinitely.

A complete example script, `fetch_solar.R`, that appends yesterday’s
data to a CSV:

``` r

library(enphaseR)

system_id <- 1234567
csv_path <- "~/solar/production.csv"

new_rows <- enphase_production(system_id)

if (file.exists(csv_path)) {
  old <- readr::read_csv(csv_path, show_col_types = FALSE)
  # Keep only intervals we don't already have
  new_rows <- dplyr::anti_join(new_rows, old, by = c("date", "end_at"))
  readr::write_csv(new_rows, csv_path, append = TRUE)
} else {
  readr::write_csv(new_rows, csv_path)
}

message(nrow(new_rows), " new rows written")
```

### Linux/macOS: cron

Run it every morning at 6:05 (production for yesterday is complete by
then):

    5 6 * * * /usr/bin/Rscript /home/you/solar/fetch_solar.R >> /home/you/solar/fetch.log 2>&1

Add the entry with `crontab -e`. If cron runs as a different user than
the one who ran
[`enphase_authorize()`](https://smach.github.io/enphaseR/reference/enphase_authorize.md),
set `ENPHASER_CONFIG_DIR` in the script (or pass `config_dir=`) so it
finds the token files.

### Windows: Task Scheduler

Either use Task Scheduler directly — create a daily task whose action
runs `Rscript.exe C:\path\to\fetch_solar.R` — or set it up from R with
the [taskscheduleR](https://cran.r-project.org/package=taskscheduleR)
package:

``` r

taskscheduleR::taskscheduler_create(
  taskname = "enphase_daily",
  rscript = "C:/path/to/fetch_solar.R",
  schedule = "DAILY",
  starttime = "06:05"
)
```

Note that a scheduled task only runs while the machine is on; if your
computer sleeps through the scheduled time, enable “Run task as soon as
possible after a scheduled start is missed” in the task’s settings.

### Make failures visible

A silent cron job can fail for a month without you noticing — which is
exactly how a refresh token lapses. Have the script log to a file (as
the cron line above does) and, ideally, alert you on failure. A minimal
pattern:

``` r

result <- try(enphase_production(system_id))
if (inherits(result, "try-error")) {
  # write to a log, send an email (e.g. with the emayili package),
  # or trigger any notification you already use
}
```

## If the refresh token lapses anyway

You’ll see an error like:

    Enphase rejected the token refresh. The refresh token has likely expired
    (they last about a month) — run enphase_authorize() to re-authorize in
    the browser, then try again.

Recovery is one no-argument call in an interactive session — your saved
credentials are reused, so there’s nothing to look up:

``` r

enphase_authorize()
```

Then your scheduled job resumes working, and past days can be backfilled
with a `start_date`/`end_date` range.
