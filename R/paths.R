.pusher_dir <- function() {
  override <- Sys.getenv("PUSHER_HOME", unset = "")
  if (nzchar(override)) {
    return(normalizePath(path.expand(override), mustWork = FALSE))
  }

  normalizePath(file.path(path.expand("~"), ".pusher"), mustWork = FALSE)
}

.config_file <- function() {
  file.path(.pusher_dir(), "repos.json")
}

.log_file <- function() {
  file.path(.pusher_dir(), "pusher.log")
}

.launchd_dir <- function() {
  file.path(.pusher_dir(), "launchd")
}

.ensure_pusher_dir <- function() {
  dir.create(.pusher_dir(), recursive = TRUE, showWarnings = FALSE)
  invisible(.pusher_dir())
}

.iso_now <- function() {
  format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
}

.iso_to_time <- function(x) {
  x <- sub("Z$", "+0000", x)
  x <- sub("([+-][0-9]{2}):([0-9]{2})$", "\\1\\2", x)
  as.POSIXct(x, format = "%Y-%m-%dT%H:%M:%OS%z", tz = "UTC")
}

.time_to_iso <- function(x) {
  if (length(x) == 0 || is.na(x)) {
    return(NA_character_)
  }
  format(x, "%Y-%m-%dT%H:%M:%S%z", tz = "UTC")
}
