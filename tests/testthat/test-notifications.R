test_that("notifications are disabled by default and can be toggled", {
  with_pusher_home({
    expect_false(pusher::notifications_enabled())
    expect_equal(pusher::notification_style(), "banner")

    expect_invisible(pusher::set_notifications(TRUE))
    expect_true(pusher::notifications_enabled())

    expect_invisible(pusher::set_notifications(FALSE))
    expect_false(pusher::notifications_enabled())
  })
})

test_that("notification style can be toggled", {
  with_pusher_home({
    expect_equal(pusher::notification_style(), "banner")

    expect_invisible(pusher::set_notification_style("alert"))
    expect_equal(pusher::notification_style(), "alert")

    expect_invisible(pusher::set_notification_style("banner"))
    expect_equal(pusher::notification_style(), "banner")
  })
})

test_that("set_notification_style validates input", {
  with_pusher_home({
    expect_error(pusher::set_notification_style("sticky"), "should be one of")
  })
})

test_that("set_notifications validates input", {
  with_pusher_home({
    expect_error(pusher::set_notifications(1), "enabled must be TRUE or FALSE")
    expect_error(pusher::set_notifications(NA), "enabled must be TRUE or FALSE")
  })
})

test_that("successful pushes notify only when enabled", {
  with_pusher_home({
    notify_file <- tempfile("pusher-notification-")
    old <- Sys.getenv("PUSHER_NOTIFICATION_FILE", unset = NA_character_)
    Sys.setenv(PUSHER_NOTIFICATION_FILE = notify_file)
    on.exit({
      if (is.na(old)) {
        Sys.unsetenv("PUSHER_NOTIFICATION_FILE")
      } else {
        Sys.setenv(PUSHER_NOTIFICATION_FILE = old)
      }
    }, add = TRUE)

    fixture <- make_repo()
    commit_file(fixture$repo, "initial.txt", "initial", "2020-01-01T00:00:00+0000")
    git(fixture$repo, c("push", "-u", "origin", "main"))
    commit_file(fixture$repo, "due.txt", "due", "2020-01-02T00:00:00+0000")

    pusher::add_repo(fixture$repo)
    invisible(pusher::check_once(dry_run = FALSE))
    expect_false(file.exists(notify_file))

    commit_file(fixture$repo, "due-again.txt", "due again", "2020-01-03T00:00:00+0000")
    pusher::set_notifications(TRUE)
    invisible(pusher::check_once(dry_run = FALSE))

    expect_true(file.exists(notify_file))
    notifications <- readLines(notify_file, warn = FALSE)
    expect_match(notifications[[1]], "Pushed 1 commit from repo/main", fixed = TRUE)
    expect_match(notifications[[1]], "commit due-again.txt", fixed = TRUE)
  })
})

test_that("notification message includes the pushed commit title", {
  analysis <- list(
    repo_root = "/tmp/repo",
    branch = "main",
    due = 1L,
    due_sha = "abc123",
    commits = data.frame(
      sha = c("older", "abc123"),
      title = c("Older commit", "Push this title"),
      stringsAsFactors = FALSE
    )
  )

  expect_equal(
    pusher:::.notification_message(analysis),
    "Pushed 1 commit from repo/main: Push this title"
  )
})

test_that("notification scripts support banners and persistent alerts", {
  banner <- pusher:::.notification_script("Pushed commit", "banner")
  alert <- pusher:::.notification_script("Pushed commit", "alert")

  expect_match(banner, "display notification", fixed = TRUE)
  expect_match(banner, "with title \"pusher\"", fixed = TRUE)
  expect_match(alert, "display alert", fixed = TRUE)
  expect_match(alert, "message \"Pushed commit\"", fixed = TRUE)
})

test_that("osascript runner preserves script arguments with spaces", {
  skip_if_not(identical(Sys.info()[["sysname"]], "Darwin"))

  result <- pusher:::.run_osascript('return "ok"')

  expect_equal(unname(result), "ok")
})
