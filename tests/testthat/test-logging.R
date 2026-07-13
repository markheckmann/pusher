test_that("last_pushes returns successful pushes newest first", {
  with_pusher_home({
    log_path <- file.path(Sys.getenv("PUSHER_HOME"), "pusher.log")
    writeLines(c(
      "2026-07-13T10:00:00+0000 INFO repo=\"/tmp/repo one\" branch=main result=pushed sha=abc123 title=\"Older title\" count=2",
      "2026-07-13T11:00:00+0000 ERROR repo=/tmp/repo2 branch=main result=failed sha=bad123 reason=\"push failed\"",
      "2026-07-13T12:00:00+0000 INFO repo=/tmp/repo2 branch=main result=pushed sha=def456 title=\"Newest title\" count=1"
    ), log_path)

    pushes <- pusher::last_pushes()

    expect_equal(nrow(pushes), 2L)
    expect_equal(pushes$sha, c("def456", "abc123"))
    expect_equal(pushes$title, c("Newest title", "Older title"))
    expect_equal(pushes$repo[[2]], "/tmp/repo one")
    expect_equal(pushes$count, c(1L, 2L))
  })
})

test_that("last_pushes backfills title for older logs without title", {
  with_pusher_home({
    fixture <- make_repo()
    sha <- commit_file(fixture$repo, "pushed.txt", "pushed", "2020-01-01T00:00:00+0000")

    log_path <- file.path(Sys.getenv("PUSHER_HOME"), "pusher.log")
    writeLines(
      sprintf(
        "2026-07-13T10:00:00+0000 INFO repo=%s branch=main result=pushed sha=%s count=1",
        fixture$repo,
        sha
      ),
      log_path
    )

    pushes <- pusher::last_pushes()

    expect_true("title" %in% names(pushes))
    expect_equal(pushes$title[[1]], "commit pushed.txt")
  })
})

test_that("last_pushes respects n", {
  with_pusher_home({
    log_path <- file.path(Sys.getenv("PUSHER_HOME"), "pusher.log")
    writeLines(c(
      "2026-07-13T10:00:00+0000 INFO repo=/tmp/repo branch=main result=pushed sha=abc123 count=1",
      "2026-07-13T11:00:00+0000 INFO repo=/tmp/repo branch=main result=pushed sha=def456 count=1"
    ), log_path)

    expect_equal(pusher::last_pushes(n = 1)$sha, "def456")
    expect_equal(nrow(pusher::last_pushes(n = 0)), 0L)
  })
})
