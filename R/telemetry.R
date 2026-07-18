#' Fetch 15-minute solar production intervals for one or more days
#'
#' Retrieves production-meter telemetry from the Enphase API, one request
#' per day in the range, and returns all intervals as a single tidy tibble.
#' The API serves past dates, so missed days can be backfilled by widening
#' the range.
#'
#' A full day has 96 fifteen-minute intervals. When the API returns fewer --
#' typically because Enphase hasn't finished reporting a very recent day --
#' the function keeps what it got and warns, so you can re-fetch that day
#' later.
#'
#' Values come from the site's revenue-grade production meter. Enphase also
#' records production as reported by the microinverters themselves, which
#' typically differs by around 1% because the two measure at different
#' points in the system. The Enlighten app/website may display either
#' source, so expect small discrepancies between these totals and the app.
#'
#' The free "Watt" developer plan allows 1,000 requests per month and 10 per
#' minute. One request is made per day in the range; for ranges longer than
#' 10 days the function paces itself to stay under the per-minute limit, and
#' rate-limited responses are retried automatically.
#'
#' @param system_id The system's numeric ID, from [enphase_systems()].
#' @param start_date,end_date The date range to fetch (inclusive). Anything
#'   `as.Date()` understands. Both default to yesterday.
#' @param tz Time zone of the system's location, used to define each day's
#'   midnight boundary and to display interval times.
#' @inheritParams enphase_authorize
#'
#' @return A tibble with one row per 15-minute interval: `date`, `end_at`
#'   (the interval's end time as a POSIXct in `tz`), and `wh_del`
#'   (watt-hours delivered). Saving is up to you -- e.g.
#'   `readr::write_csv()` or `saveRDS()` on the result.
#' @export
#'
#' @examples
#' \dontrun{
#' # Yesterday's production:
#' enphase_production(system_id = 1234567)
#'
#' # Backfill a month:
#' enphase_production(1234567, start_date = "2026-06-01",
#'                    end_date = "2026-06-30")
#' }
enphase_production <- function(system_id, start_date = Sys.Date() - 1,
                               end_date = start_date,
                               tz = "America/New_York", config_dir = NULL) {
  dates <- expand_dates(start_date, end_date)

  # One refresh covers the whole loop; access tokens last about a day
  auth <- enphase_refresh_tokens(config_dir)

  # Watt-plan limit is 10 requests/minute, so pace long backfills
  pause <- if (length(dates) > 10) 6.5 else 0

  days <- lapply(seq_along(dates), function(i) {
    if (i > 1 && pause > 0) Sys.sleep(pause)
    body <- enphase_api_get(
      c("systems", system_id, "telemetry", "production_meter"),
      query = list(
        start_at = day_start_epoch(dates[i], tz),
        granularity = "day"
      ),
      auth = auth
    )
    shape_production_day(body, dates[i], tz)
  })

  do.call(rbind, days)
}

# Epoch seconds at local midnight starting `date` in `tz` -- what the API's
# start_at parameter expects
day_start_epoch <- function(date, tz) {
  as.numeric(as.POSIXct(paste(as.Date(date), "00:00:00"), tz = tz))
}

expand_dates <- function(start_date, end_date) {
  start_date <- as.Date(start_date)
  end_date <- as.Date(end_date)
  if (is.na(start_date) || is.na(end_date)) {
    stop("start_date and end_date must be interpretable as dates.",
         call. = FALSE)
  }
  if (end_date < start_date) {
    stop("end_date must not be before start_date.", call. = FALSE)
  }
  seq(start_date, end_date, by = "day")
}

# Shape one day's production_meter response into a tidy tibble
shape_production_day <- function(body, date, tz) {
  date <- as.Date(date)
  intervals <- body$intervals
  n <- if (is.data.frame(intervals)) nrow(intervals) else 0

  if (n == 0) {
    warning(
      "No production intervals returned for ", format(date),
      "; that day may not be available yet.",
      call. = FALSE
    )
    return(tibble::tibble(
      date = as.Date(character()),
      end_at = as.POSIXct(character(), tz = tz),
      wh_del = numeric()
    ))
  }

  if (n < 96) {
    warning(
      "Only ", n, " of 96 fifteen-minute intervals returned for ",
      format(date), " -- Enphase may not have finished reporting that ",
      "day yet. Re-fetch it later to fill the gap.",
      call. = FALSE
    )
  }

  tibble::tibble(
    date = rep(date, n),
    end_at = as.POSIXct(intervals$end_at, tz = tz,
                        origin = "1970-01-01"),
    wh_del = as.numeric(intervals$wh_del)
  )
}
