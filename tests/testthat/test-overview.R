test_that("overview returns and prints scheduler, upcoming, and push sections", {
  with_pusher_home({
    fixture <- make_repo()
    commit_file(fixture$repo, "initial.txt", "initial", "2020-01-01T00:00:00+0000")
    git(fixture$repo, c("push", "-u", "origin", "main"))

    next_date <- format(Sys.time() + 86400, "%Y-%m-%dT%H:%M:%S%z")
    next_sha <- commit_file(fixture$repo, "next.txt", "next", next_date)
    pusher::add_repo(fixture$repo)

    writeLines("last scheduler run", file.path(Sys.getenv("PUSHER_HOME"), "launchd.out"))
    log_path <- file.path(Sys.getenv("PUSHER_HOME"), "pusher.log")
    writeLines(sprintf(
      "2026-07-13T12:00:00+0000 INFO repo=%s branch=main result=pushed sha=def456789 title=\"Fix pushed thing\" count=1",
      fixture$repo
    ), log_path)

    output <- utils::capture.output(result <- pusher::overview(upcoming_n = 1, last_n = 1))

    expect_named(result, c("scheduler", "upcoming", "last_pushes"))
    expect_equal(result$upcoming$sha, next_sha)
    expect_equal(result$upcoming$title, "commit next.txt")
    expect_equal(result$last_pushes$sha, "def456789")
    expect_equal(result$last_pushes$title, "Fix pushed thing")
    expect_match(paste(output, collapse = "\n"), "Next push in [0-9]+ minutes: commit next.txt")
    expect_match(paste(output, collapse = "\n"), "Next Check Cycle")
    expect_match(paste(output, collapse = "\n"), "system_time")
    expect_match(paste(output, collapse = "\n"), "time_zone")
    expect_match(paste(output, collapse = "\n"), "Next Commits To Push")
    expect_match(paste(output, collapse = "\n"), "commit next.txt")
    expect_match(paste(output, collapse = "\n"), "Last Commits Pushed")
    expect_match(paste(output, collapse = "\n"), "Fix pushed thing")
    expect_match(paste(output, collapse = "\n"), "origin/main", fixed = TRUE)
  })
})

test_that("overview validates counts", {
  expect_error(pusher::overview(upcoming_n = -1), "upcoming_n")
  expect_error(pusher::overview(last_n = -1), "last_n")
})

test_that("overview reports when no next push is available", {
  with_pusher_home({
    output <- utils::capture.output(pusher::overview(upcoming_n = 0, last_n = 0))

    expect_match(paste(output, collapse = "\n"), "Next push: no future unpublished commits", fixed = TRUE)
  })
})

test_that("overview human time labels relative dates", {
  tz <- pusher:::.overview_timezone()
  now <- as.POSIXct("2026-07-13 10:00:00", tz = tz)

  expect_equal(pusher:::.overview_human_time_one(now + 20 * 60, now), "in 20 minutes")
  expect_equal(pusher:::.overview_human_time_one(now - 2 * 3600, now), "2 hours ago")
  expect_equal(pusher:::.overview_human_time_one(now + 26 * 3600, now), "tomorrow at 12:00")
})

test_that("overview rolls stale scheduler times forward", {
  with_pusher_home({
    check_log <- file.path(Sys.getenv("PUSHER_HOME"), "launchd.out")
    writeLines("stale scheduler run", check_log)
    Sys.setFileTime(check_log, Sys.time() - 3 * 1800)

    result <- utils::capture.output(overview <- pusher::overview(upcoming_n = 0, last_n = 0))
    next_check <- as.POSIXct(overview$scheduler$next_check, format = "%Y-%m-%dT%H:%M:%S%z", tz = "UTC")

    expect_gt(next_check, Sys.time())
    expect_equal(overview$scheduler$interval_seconds, 1800L)
    expect_match(overview$scheduler$estimate_source, "scheduler interval")
    expect_match(paste(result, collapse = "\n"), "Next Check Cycle")
  })
})
