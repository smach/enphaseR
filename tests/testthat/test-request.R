test_that("enphase_build_request builds the right URL and query", {
  auth <- list(access_token = "fake-token", api_key = "fake-key")
  req <- enphase_build_request(
    auth,
    c("systems", "4832248", "telemetry", "production_meter"),
    query = list(start_at = 1750000000, granularity = "day")
  )

  expect_s3_class(req, "httr2_request")
  expect_match(
    req$url,
    "api.enphaseenergy.com/api/v4/systems/4832248/telemetry/production_meter",
    fixed = TRUE
  )
  expect_match(req$url, "start_at=1750000000", fixed = TRUE)
  expect_match(req$url, "granularity=day", fixed = TRUE)
})

test_that("the token is a redacted header and the api key is a query param", {
  auth <- list(access_token = "fake-token", api_key = "fake-key")
  req <- enphase_build_request(auth, "systems")

  expect_setequal(names(req$headers), "Authorization")
  # Enphase requires the api key in the query string, not a header
  expect_match(req$url, "key=fake-key", fixed = TRUE)

  # The access token is redacted and must not appear in the printed request
  printed <- paste(capture.output(print(req)), collapse = "\n")
  expect_false(grepl("fake-token", printed, fixed = TRUE))
})

test_that("caller query params survive alongside the api key", {
  auth <- list(access_token = "t", api_key = "k")
  req <- enphase_build_request(auth, "systems", query = list(granularity = "day"))
  expect_match(req$url, "granularity=day", fixed = TRUE)
  expect_match(req$url, "key=k", fixed = TRUE)
})

test_that("numeric system ids work in paths", {
  auth <- list(access_token = "t", api_key = "k")
  req <- enphase_build_request(auth, c("systems", 4832248, "summary"))
  expect_match(req$url, "/systems/4832248/summary", fixed = TRUE)
})
