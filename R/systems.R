#' List the Enphase systems your account can access
#'
#' Most homeowners have exactly one system; this is where to find its
#' `system_id` for use with [enphase_summary()] and [enphase_production()].
#'
#' @inheritParams enphase_authorize
#'
#' @return A tibble with one row per system, including `system_id`, `name`,
#'   `status`, and other fields returned by the API.
#' @export
#'
#' @examples
#' \dontrun{
#' enphase_systems()
#' }
enphase_systems <- function(config_dir = NULL) {
  body <- enphase_api_get("systems", config_dir = config_dir)
  systems <- body$systems
  if (is.null(systems) || NROW(systems) == 0) {
    return(tibble::tibble(system_id = integer(), name = character()))
  }
  tibble::as_tibble(systems)
}

#' Get a summary of one system's current status and lifetime production
#'
#' @param system_id The system's numeric ID, from [enphase_systems()].
#' @inheritParams enphase_authorize
#'
#' @return A one-row tibble of the system's summary fields, such as
#'   `current_power`, `energy_today`, `energy_lifetime`, and `status`.
#' @export
#'
#' @examples
#' \dontrun{
#' enphase_summary(system_id = 1234567)
#' }
enphase_summary <- function(system_id, config_dir = NULL) {
  body <- enphase_api_get(
    c("systems", system_id, "summary"),
    config_dir = config_dir
  )
  # Keep scalar fields only so the result is a clean one-row tibble;
  # NULLs become NA
  body <- lapply(body, function(x) if (is.null(x)) NA else x)
  scalars <- body[vapply(
    body,
    function(x) is.atomic(x) && length(x) == 1,
    logical(1)
  )]
  tibble::as_tibble(scalars)
}
