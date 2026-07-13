.notification_message <- function(analysis) {
  repo_name <- basename(analysis$repo_root)
  sprintf(
    "Pushed %s commit%s from %s/%s",
    analysis$due,
    if (analysis$due == 1L) "" else "s",
    repo_name,
    analysis$branch
  )
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

  result <- system2(
    "osascript",
    c("-e", sprintf('display notification %s with title "pusher"', .applescript_quote(message))),
    stdout = TRUE,
    stderr = TRUE
  )
  code <- attr(result, "status")
  if (!is.null(code) && code != 0L) {
    stop(sprintf("osascript notification failed: %s", paste(result, collapse = "\n")), call. = FALSE)
  }

  invisible(TRUE)
}

.applescript_quote <- function(x) {
  x <- gsub("\\\\", "\\\\\\\\", x)
  x <- gsub('"', '\\"', x, fixed = TRUE)
  paste0('"', x, '"')
}
