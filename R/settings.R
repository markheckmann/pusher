.default_settings <- function() {
  list(
    notifications = FALSE,
    notification_style = "banner"
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
  defaults
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
