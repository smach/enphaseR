test_that("expand_dates handles single days and ranges", {
  expect_equal(
    expand_dates("2026-06-01", "2026-06-01"),
    as.Date("2026-06-01")
  )
  expect_equal(
    expand_dates("2026-06-01", "2026-06-05"),
    seq(as.Date("2026-06-01"), as.Date("2026-06-05"), by = "day")
  )
})

test_that("expand_dates rejects reversed and unparseable input", {
  expect_error(expand_dates("2026-06-05", "2026-06-01"), "before")
  expect_error(expand_dates(NA, "2026-06-01"), "dates")
})

test_that("day_start_epoch respects DST transitions in America/New_York", {
  tz <- "America/New_York"
  # DST starts 2026-03-08: that day has only 23 hours
  expect_equal(
    day_start_epoch("2026-03-09", tz) - day_start_epoch("2026-03-08", tz),
    23 * 3600
  )
  # DST ends 2026-11-01: that day has 25 hours
  expect_equal(
    day_start_epoch("2026-11-02", tz) - day_start_epoch("2026-11-01", tz),
    25 * 3600
  )
  # An ordinary day is 24 hours
  expect_equal(
    day_start_epoch("2026-06-02", tz) - day_start_epoch("2026-06-01", tz),
    24 * 3600
  )
})

test_that("day_start_epoch matches a known UTC epoch", {
  expect_equal(day_start_epoch("1970-01-02", "UTC"), 86400)
})
