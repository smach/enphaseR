# Build a fake production_meter response body with n 15-minute intervals
# starting at local midnight of `date`
fake_body <- function(date, n, tz = "America/New_York") {
  start <- day_start_epoch(date, tz)
  list(
    system_id = 123,
    granularity = "day",
    intervals = data.frame(
      end_at = start + 900 * seq_len(n),
      devices_reporting = 18L,
      wh_del = seq_len(n) * 10
    )
  )
}

test_that("a full day shapes cleanly with no warning", {
  tz <- "America/New_York"
  out <- expect_no_warning(
    shape_production_day(fake_body("2026-06-15", 96), "2026-06-15", tz)
  )
  expect_s3_class(out, "tbl_df")
  expect_equal(names(out), c("date", "end_at", "wh_del"))
  expect_equal(nrow(out), 96)
  expect_equal(unique(out$date), as.Date("2026-06-15"))
  expect_s3_class(out$end_at, "POSIXct")
  expect_equal(attr(out$end_at, "tzone"), tz)
  # First interval ends at 00:15 local, last at midnight the next day
  expect_equal(format(out$end_at[1], "%H:%M"), "00:15")
  expect_equal(out$wh_del, seq_len(96) * 10)
})

test_that("an incomplete day warns but still returns its rows", {
  out <- NULL
  expect_warning(
    out <- shape_production_day(
      fake_body("2026-06-15", 40), "2026-06-15", "America/New_York"
    ),
    "40 of 96"
  )
  expect_equal(nrow(out), 40)
})

test_that("a day with no intervals warns and returns an empty tibble", {
  body <- list(system_id = 123, intervals = NULL)
  out <- NULL
  expect_warning(
    out <- shape_production_day(body, "2026-06-15", "America/New_York"),
    "No production intervals"
  )
  expect_equal(nrow(out), 0)
  expect_equal(names(out), c("date", "end_at", "wh_del"))
})

test_that("multiple shaped days row-bind into one consistent tibble", {
  tz <- "America/New_York"
  days <- list(
    shape_production_day(fake_body("2026-06-15", 96), "2026-06-15", tz),
    shape_production_day(fake_body("2026-06-16", 96), "2026-06-16", tz)
  )
  out <- do.call(rbind, days)
  expect_equal(nrow(out), 192)
  expect_equal(as.numeric(table(out$date)), c(96, 96))
})
