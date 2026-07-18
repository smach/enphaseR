test_that("explicit config_dir argument wins", {
  withr::local_envvar(ENPHASER_CONFIG_DIR = "C:/env/dir")
  expect_equal(enphase_config_dir("C:/explicit"), "C:/explicit")
})

test_that("ENPHASER_CONFIG_DIR is used when no argument is given", {
  withr::local_envvar(ENPHASER_CONFIG_DIR = "C:/env/dir")
  expect_equal(enphase_config_dir(), "C:/env/dir")
})

test_that("default falls back to R_user_dir", {
  withr::local_envvar(ENPHASER_CONFIG_DIR = NA)
  expect_equal(
    enphase_config_dir(),
    tools::R_user_dir("enphaseR", which = "config")
  )
})

test_that("credential and token paths land in the config dir", {
  expect_equal(
    credentials_path("C:/cfg"),
    file.path("C:/cfg", "credentials.json")
  )
  expect_equal(tokens_path("C:/cfg"), file.path("C:/cfg", "tokens.json"))
})
