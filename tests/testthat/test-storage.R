test_that("write_json_secure round-trips a token list", {
  dir <- withr::local_tempdir()
  path <- file.path(dir, "tokens.json")
  tokens <- list(access_token = "abc", refresh_token = "def", expires_in = 86400)

  write_json_secure(tokens, path)
  back <- jsonlite::read_json(path)

  expect_equal(back$access_token, "abc")
  expect_equal(back$refresh_token, "def")
  expect_equal(back$expires_in, 86400)
})

test_that("write_json_secure overwrites an existing file (Windows rename path)", {
  dir <- withr::local_tempdir()
  path <- file.path(dir, "tokens.json")

  write_json_secure(list(refresh_token = "old"), path)
  write_json_secure(list(refresh_token = "new"), path)

  expect_equal(jsonlite::read_json(path)$refresh_token, "new")
  # No stray temp files left behind
  expect_equal(list.files(dir), "tokens.json")
})

test_that("write_json_secure creates missing directories", {
  dir <- withr::local_tempdir()
  path <- file.path(dir, "nested", "deeper", "tokens.json")
  write_json_secure(list(a = 1), path)
  expect_true(file.exists(path))
})

test_that("read_json_file gives a helpful error for a missing file", {
  expect_error(
    read_json_file(file.path(tempdir(), "nope-not-here.json"), "credentials"),
    "enphase_authorize"
  )
})
