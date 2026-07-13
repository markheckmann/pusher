.overview_check_files <- function() {
  file.path(.pusher_dir(), c("launchd.out", "launchd.err"))
}

.last_check_time <- function() {
  files <- .overview_check_files()
  files <- files[file.exists(files)]
  if (!length(files)) {
    return(as.POSIXct(NA))
  }

  mtimes <- file.info(files)$mtime
  mtimes <- mtimes[!is.na(mtimes)]
  if (!length(mtimes)) {
    return(as.POSIXct(NA))
  }

  max(mtimes)
}

.next_interval_time <- function(last_check, now = Sys.time(), interval_seconds = .scheduler_interval_seconds()) {
  if (is.na(last_check)) {
    return(as.POSIXct(NA))
  }

  next_check <- last_check + interval_seconds
  if (next_check <= now) {
    elapsed <- as.numeric(difftime(now, last_check, units = "secs"))
    intervals <- floor(elapsed / interval_seconds) + 1L
    next_check <- last_check + intervals * interval_seconds
  }

  next_check
}

.next_check_cycle <- function() {
  scheduler <- scheduler_status()
  interval_seconds <- .scheduler_interval_seconds()
  last_check <- .last_check_time()
  next_check <- .next_interval_time(last_check, interval_seconds = interval_seconds)

  data.frame(
    label = scheduler$label,
    installed = scheduler$installed,
    loaded = scheduler$loaded,
    interval_seconds = interval_seconds,
    last_check = .time_to_iso(last_check),
    next_check = .time_to_iso(next_check),
    estimate_source = if (is.na(last_check)) NA_character_ else "launchd log file mtime, rolled by scheduler interval",
    stringsAsFactors = FALSE
  )
}

.overview_timezone <- function() {
  tz <- Sys.timezone()
  if (length(tz) == 0 || is.na(tz) || !nzchar(tz)) {
    return("local")
  }
  tz
}

.overview_time <- function(x) {
  tz <- Sys.timezone()
  if (length(tz) == 0 || is.na(tz) || !nzchar(tz)) {
    tz <- ""
  }

  if (is.character(x)) {
    x <- .iso_to_time(x)
  }
  if (length(x) == 0) {
    return(character())
  }

  formatted <- format(x, "%Y-%m-%dT%H:%M:%S%z", tz = tz)
  formatted[is.na(x)] <- NA_character_
  formatted
}

.overview_scheduler_table <- function(scheduler) {
  if (!nrow(scheduler)) {
    return(data.frame())
  }

  data.frame(
    label = scheduler$label,
    installed = scheduler$installed,
    loaded = scheduler$loaded,
    interval_minutes = scheduler$interval_seconds / 60,
    system_time = .overview_time(Sys.time()),
    last_check = .overview_time(scheduler$last_check),
    next_check = .overview_time(scheduler$next_check),
    time_zone = .overview_timezone(),
    stringsAsFactors = FALSE
  )
}

.short_sha <- function(x) {
  ifelse(is.na(x) | !nzchar(x), x, substr(x, 1L, 7L))
}

.repo_name <- function(x) {
  ifelse(is.na(x) | !nzchar(x), x, basename(x))
}

.overview_upcoming_table <- function(upcoming) {
  if (!nrow(upcoming)) {
    return(data.frame())
  }

  data.frame(
    due_at = .overview_time(upcoming$effective_date),
    repo = .repo_name(upcoming$repo_root),
    branch = upcoming$branch,
    sha = .short_sha(upcoming$sha),
    title = upcoming$title,
    remote = paste0(upcoming$remote, "/", upcoming$remote_branch),
    stringsAsFactors = FALSE
  )
}

.overview_next_push_line <- function(upcoming, now = Sys.time()) {
  if (!nrow(upcoming)) {
    return("Next push: no future unpublished commits.")
  }

  next_time <- .iso_to_time(upcoming$effective_date[[1]])
  minutes <- ceiling(as.numeric(difftime(next_time, now, units = "mins")))
  if (is.na(minutes)) {
    return("Next push: unavailable.")
  }
  if (minutes <= 0) {
    return(sprintf("Next push due now: %s", upcoming$title[[1]]))
  }

  minute_label <- if (minutes == 1) "minute" else "minutes"
  sprintf("Next push in %s %s: %s", minutes, minute_label, upcoming$title[[1]])
}

.overview_last_pushes_table <- function(pushes) {
  if (!nrow(pushes)) {
    return(data.frame())
  }

  data.frame(
    pushed_at = .overview_time(pushes$timestamp),
    repo = .repo_name(pushes$repo),
    branch = pushes$branch,
    sha = .short_sha(pushes$sha),
    commits = pushes$count,
    stringsAsFactors = FALSE
  )
}

.print_overview_section <- function(title, x, empty) {
  cat("\n", title, "\n", sep = "")
  if (!nrow(x)) {
    cat(empty, "\n", sep = "")
    return(invisible(NULL))
  }
  print(x, row.names = FALSE)
  invisible(NULL)
}

#' Show a pusher overview
#'
#' Prints the estimated next check cycle, a countdown to the next commit date,
#' the next unpublished commits waiting for their scheduled date, and recent
#' successful pushes. Printed timestamps use the system timezone.
#'
#' @param upcoming_n Maximum number of upcoming commits to show.
#' @param last_n Maximum number of recent successful pushes to show.
#' @return A list with `scheduler`, `upcoming`, and `last_pushes` data frames,
#'   invisibly.
#' @export
overview <- function(upcoming_n = 5, last_n = 5) {
  if (!is.numeric(upcoming_n) || length(upcoming_n) != 1L || is.na(upcoming_n) || upcoming_n < 0) {
    stop("upcoming_n must be a single non-negative number.", call. = FALSE)
  }
  if (!is.numeric(last_n) || length(last_n) != 1L || is.na(last_n) || last_n < 0) {
    stop("last_n must be a single non-negative number.", call. = FALSE)
  }

  scheduler <- .next_check_cycle()
  upcoming <- upcoming_pushes(n = upcoming_n)
  pushes <- last_pushes(n = last_n)

  cat("Pusher Overview\n")
  cat(.overview_next_push_line(upcoming), "\n", sep = "")
  .print_overview_section("Next Check Cycle", .overview_scheduler_table(scheduler), "Scheduler status is unavailable.")
  .print_overview_section("Next Commits To Push", .overview_upcoming_table(upcoming), "No future unpublished commits.")
  .print_overview_section("Last Commits Pushed", .overview_last_pushes_table(pushes), "No successful pushes logged.")

  invisible(list(
    scheduler = scheduler,
    upcoming = upcoming,
    last_pushes = pushes
  ))
}
