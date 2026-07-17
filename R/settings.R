.default_settings <- function() {
  list(
    notifications = FALSE,
    notification_style = "banner",
    scheduler_interval_minutes = 30L
  )
}

.read_settings <- function() {
  path <- .settings_file()
  if (!file.exists(path)) {
    return(.default_settings())
  }

  settings <- jsonlite::fromJSON(path, simplifyVector = TRUE)
  defaults <- .default_settings()
  defaults[names(settings)] <- settings
  defaults$notifications <- isTRUE(defaults$notifications)
  if (!is.character(defaults$notification_style) ||
    length(defaults$notification_style) != 1L ||
    !defaults$notification_style %in% c("banner", "alert")) {
    defaults$notification_style <- "banner"
  }
  if (!.valid_scheduler_interval(defaults$scheduler_interval_minutes)) {
    defaults$scheduler_interval_minutes <- 30L
  }
  defaults$scheduler_interval_minutes <- as.integer(defaults$scheduler_interval_minutes)
  defaults
}

.valid_scheduler_interval <- function(minutes) {
  is.numeric(minutes) &&
    length(minutes) == 1L &&
    !is.na(minutes) &&
    is.finite(minutes) &&
    minutes > 0 &&
    minutes == as.integer(minutes)
}

.write_settings <- function(settings) {
  .ensure_pusher_dir()
  jsonlite::write_json(settings, .settings_file(), pretty = TRUE, auto_unbox = TRUE)
  invisible(settings)
}

#' Check whether push notifications are enabled
#'
#' Notifications are off by default.
#'
#' @return `TRUE` if notifications are enabled, otherwise `FALSE`.
#' @export
notifications_enabled <- function() {
  isTRUE(.read_settings()$notifications)
}

#' Enable or disable successful push notifications
#'
#' @param enabled `TRUE` to enable notifications, `FALSE` to disable them.
#' @return The updated notifications setting, invisibly.
#' @export
set_notifications <- function(enabled = TRUE) {
  if (!is.logical(enabled) || length(enabled) != 1L || is.na(enabled)) {
    stop("enabled must be TRUE or FALSE.", call. = FALSE)
  }

  settings <- .read_settings()
  settings$notifications <- enabled
  .write_settings(settings)
  invisible(enabled)
}

#' Show the successful push notification style
#'
#' @return Either `"banner"` for Notification Center banners or `"alert"` for
#'   persistent macOS alerts.
#' @export
notification_style <- function() {
  .read_settings()$notification_style
}

#' Set the successful push notification style
#'
#' @param style `"banner"` for a standard Notification Center banner, or
#'   `"alert"` for a persistent macOS alert that must be dismissed.
#' @return The updated notification style, invisibly.
#' @export
set_notification_style <- function(style = c("banner", "alert")) {
  style <- match.arg(style)

  settings <- .read_settings()
  settings$notification_style <- style
  .write_settings(settings)
  invisible(style)
}

#' Show the scheduler interval
#'
#' @return The scheduler interval in minutes.
#' @export
scheduler_interval <- function() {
  .read_settings()$scheduler_interval_minutes
}

#' Set the scheduler interval
#'
#' @param minutes Number of minutes between scheduler checks. Must be a positive
#'   whole number.
#' @param apply If `TRUE`, update the installed macOS LaunchAgent immediately
#'   when it is already installed. If the LaunchAgent is currently loaded, it is
#'   reloaded with the new interval.
#' @return The updated scheduler interval in minutes, invisibly.
#' @export
set_scheduler_interval <- function(minutes, apply = TRUE) {
  if (!.valid_scheduler_interval(minutes)) {
    stop("minutes must be a single positive whole number.", call. = FALSE)
  }
  if (!is.logical(apply) || length(apply) != 1L || is.na(apply)) {
    stop("apply must be TRUE or FALSE.", call. = FALSE)
  }

  minutes <- as.integer(minutes)
  settings <- .read_settings()
  settings$scheduler_interval_minutes <- minutes
  .write_settings(settings)

  if (apply) {
    .apply_scheduler_interval()
  }

  invisible(minutes)
}
