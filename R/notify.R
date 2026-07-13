.notification_message <- function(analysis) {
  repo_name <- basename(analysis$repo_root)
  message <- sprintf(
    "Pushed %s commit%s from %s/%s",
    analysis$due,
    if (analysis$due == 1L) "" else "s",
    repo_name,
    analysis$branch
  )

  title <- .analysis_due_title(analysis)
  if (!is.na(title) && nzchar(title)) {
    message <- paste0(message, ": ", title)
  }

  message
}

.notify_push <- function(analysis) {
  message <- .notification_message(analysis)

  # Tests set this to avoid invoking the user's real notification system.
  test_file <- Sys.getenv("PUSHER_NOTIFICATION_FILE", unset = "")
  if (nzchar(test_file)) {
    cat(message, "\n", file = test_file, append = TRUE)
    return(invisible(TRUE))
  }

  if (!identical(Sys.info()[["sysname"]], "Darwin")) {
    stop("Push notifications currently support macOS only.", call. = FALSE)
  }

  result <- .run_osascript(.notification_script(message, notification_style()))
  code <- attr(result, "status")
  if (!is.null(code) && code != 0L) {
    stop(sprintf("osascript notification failed: %s", paste(result, collapse = "\n")), call. = FALSE)
  }

  invisible(TRUE)
}

.notification_script <- function(message, style) {
  style <- match.arg(style, c("banner", "alert"))
  if (identical(style, "alert")) {
    return(sprintf(
      "display alert %s message %s as informational",
      .applescript_quote("pusher"),
      .applescript_quote(message)
    ))
  }

  sprintf("display notification %s with title %s", .applescript_quote(message), .applescript_quote("pusher"))
}

.run_osascript <- function(script) {
  system2(
    "osascript",
    c("-e", shQuote(script)),
    stdout = TRUE,
    stderr = TRUE
  )
}

.applescript_quote <- function(x) {
  x <- gsub("\\\\", "\\\\\\\\", x)
  x <- gsub('"', '\\"', x, fixed = TRUE)
  paste0('"', x, '"')
}
