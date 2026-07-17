.launchd_label <- function() {
  "com.pusher.scheduler"
}

.legacy_launchd_label <- function() {
  "com.pusher.hourly"
}

.scheduler_interval_seconds <- function() {
  scheduler_interval() * 60L
}

.apply_scheduler_interval <- function() {
  if (!identical(Sys.info()[["sysname"]], "Darwin") ||
    (!file.exists(.launchd_target()) && !file.exists(.legacy_launchd_target()))) {
    return(invisible(FALSE))
  }

  status <- scheduler_status()
  install_scheduler(load = isTRUE(status$loaded[[1]]))
  invisible(TRUE)
}

.launchd_target <- function(label = .launchd_label()) {
  file.path(path.expand("~"), "Library", "LaunchAgents", paste0(label, ".plist"))
}

.legacy_launchd_target <- function() {
  .launchd_target(.legacy_launchd_label())
}

.plist_escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x
}

.scheduler_plist <- function() {
  rscript <- file.path(R.home("bin"), "Rscript")
  expr <- "pusher::check_once(dry_run = FALSE)"
  out <- file.path(.pusher_dir(), "launchd.out")
  err <- file.path(.pusher_dir(), "launchd.err")

  paste0(
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n",
    "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" ",
    "\"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n",
    "<plist version=\"1.0\">\n",
    "<dict>\n",
    "  <key>Label</key>\n",
    "  <string>", .launchd_label(), "</string>\n",
    "  <key>ProgramArguments</key>\n",
    "  <array>\n",
    "    <string>", .plist_escape(rscript), "</string>\n",
    "    <string>-e</string>\n",
    "    <string>", .plist_escape(expr), "</string>\n",
    "  </array>\n",
    "  <key>StartInterval</key>\n",
    "  <integer>", .scheduler_interval_seconds(), "</integer>\n",
    "  <key>RunAtLoad</key>\n",
    "  <true/>\n",
    "  <key>StandardOutPath</key>\n",
    "  <string>", .plist_escape(out), "</string>\n",
    "  <key>StandardErrorPath</key>\n",
    "  <string>", .plist_escape(err), "</string>\n",
    "</dict>\n",
    "</plist>\n"
  )
}

.require_macos <- function() {
  if (!identical(Sys.info()[["sysname"]], "Darwin")) {
    stop("Scheduler helpers currently support macOS only.", call. = FALSE)
  }
}

.user_uid <- function() {
  uid <- system2("id", "-u", stdout = TRUE, stderr = TRUE)
  code <- attr(uid, "status")
  if (!is.null(code) && code != 0L) {
    stop(sprintf("Could not determine user id: %s", paste(uid, collapse = "\n")), call. = FALSE)
  }
  uid[[1]]
}

.remove_launchd_agent <- function(label, target, uid = .user_uid()) {
  system2("launchctl", c("bootout", paste0("gui/", uid), target), stdout = FALSE, stderr = FALSE)
  system2("launchctl", c("bootout", paste0("gui/", uid, "/", label)), stdout = FALSE, stderr = FALSE)
  if (file.exists(target)) {
    unlink(target)
  }
  invisible(target)
}

#' Install the macOS launchd scheduler
#'
#' @param load If `TRUE`, load the LaunchAgent after writing it.
#' @return The installed plist path, invisibly.
#' @export
install_scheduler <- function(load = TRUE) {
  .require_macos()
  .ensure_pusher_dir()
  dir.create(.launchd_dir(), recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(.launchd_target()), recursive = TRUE, showWarnings = FALSE)
  uid <- .user_uid()

  .remove_launchd_agent(.legacy_launchd_label(), .legacy_launchd_target(), uid)

  plist <- .scheduler_plist()
  staged <- file.path(.launchd_dir(), paste0(.launchd_label(), ".plist"))
  writeLines(plist, staged, useBytes = TRUE)
  writeLines(plist, .launchd_target(), useBytes = TRUE)

  if (load) {
    system2("launchctl", c("bootout", paste0("gui/", uid), .launchd_target()), stdout = FALSE, stderr = FALSE)
    result <- system2("launchctl", c("bootstrap", paste0("gui/", uid), .launchd_target()), stdout = TRUE, stderr = TRUE)
    code <- attr(result, "status")
    if (!is.null(code) && code != 0L) {
      stop(sprintf("launchctl bootstrap failed: %s", paste(result, collapse = "\n")), call. = FALSE)
    }
  }

  invisible(.launchd_target())
}

#' Uninstall the macOS launchd scheduler
#'
#' @return The removed plist path, invisibly.
#' @export
uninstall_scheduler <- function() {
  .require_macos()
  uid <- .user_uid()
  .remove_launchd_agent(.launchd_label(), .launchd_target(), uid)
  .remove_launchd_agent(.legacy_launchd_label(), .legacy_launchd_target(), uid)
  invisible(.launchd_target())
}

#' Show macOS launchd scheduler status
#'
#' @return A data frame with scheduler status.
#' @export
scheduler_status <- function() {
  installed <- file.exists(.launchd_target())
  loaded <- NA

  if (identical(Sys.info()[["sysname"]], "Darwin")) {
    code <- system2("launchctl", c("print", paste0("gui/", .user_uid(), "/", .launchd_label())), stdout = FALSE, stderr = FALSE)
    loaded <- identical(code, 0L)
  }

  data.frame(
    label = .launchd_label(),
    plist = .launchd_target(),
    installed = installed,
    loaded = loaded,
    stringsAsFactors = FALSE
  )
}
