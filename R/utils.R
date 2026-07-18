# Internal helpers: config-directory resolution and secure JSON storage.

api_base <- "https://api.enphaseenergy.com"

# Where credentials and tokens live. Resolution order:
# explicit argument > ENPHASER_CONFIG_DIR env var > R's per-user config dir.
enphase_config_dir <- function(config_dir = NULL) {
  if (!is.null(config_dir)) {
    return(config_dir)
  }
  env_dir <- Sys.getenv("ENPHASER_CONFIG_DIR")
  if (nzchar(env_dir)) {
    return(env_dir)
  }
  tools::R_user_dir("enphaseR", which = "config")
}

credentials_path <- function(config_dir = NULL) {
  file.path(enphase_config_dir(config_dir), "credentials.json")
}

tokens_path <- function(config_dir = NULL) {
  file.path(enphase_config_dir(config_dir), "tokens.json")
}

# Write JSON atomically and keep the file private: write to a temp file in
# the same directory, chmod 600, then rename over the target. On Windows,
# rename fails if the target exists, so fall back to copy-and-delete.
write_json_secure <- function(x, path) {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  tmp <- tempfile(tmpdir = dirname(path))
  jsonlite::write_json(x, tmp, auto_unbox = TRUE)
  Sys.chmod(tmp, mode = "600")
  if (!suppressWarnings(file.rename(tmp, path))) {
    file.copy(tmp, path, overwrite = TRUE)
    file.remove(tmp)
  }
  invisible(path)
}

read_json_file <- function(path, what) {
  if (!file.exists(path)) {
    stop(
      "No ", what, " file found at ", path,
      ". Run enphase_authorize() first; see ?enphase_authorize.",
      call. = FALSE
    )
  }
  jsonlite::read_json(path)
}
