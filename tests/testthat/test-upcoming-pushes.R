test_that("upcoming_pushes returns unpublished commits ordered by push priority", {
  with_pusher_home({
    fixture <- make_repo()
    commit_file(fixture$repo, "initial.txt", "initial", "2020-01-01T00:00:00+0000")
    git(fixture$repo, c("push", "-u", "origin", "main"))

    due_sha <- commit_file(fixture$repo, "due.txt", "due", "2020-01-02T00:00:00+0000")
    later <- format(Sys.time() + 86400 * 2, "%Y-%m-%dT%H:%M:%S%z")
    sooner <- format(Sys.time() + 86400, "%Y-%m-%dT%H:%M:%S%z")
    later_sha <- commit_file(fixture$repo, "later.txt", "later", later)
    sooner_sha <- commit_file(fixture$repo, "sooner.txt", "sooner", sooner)

    pusher::add_repo(fixture$repo)
    upcoming <- pusher::upcoming_pushes()

    expect_equal(upcoming$sha, c(due_sha, sooner_sha, later_sha))
    expect_equal(upcoming$title, c("commit due.txt", "commit sooner.txt", "commit later.txt"))
    expect_equal(upcoming$state, c("due", "waiting", "waiting"))
    expect_equal(upcoming$position, c(1L, 3L, 2L))
    expect_true(all(upcoming$effective_date == sort(upcoming$effective_date)))
  })
})

test_that("upcoming_pushes marks overdue commits blocked by earlier future commits", {
  with_pusher_home({
    fixture <- make_repo()
    commit_file(fixture$repo, "initial.txt", "initial", "2020-01-01T00:00:00+0000")
    git(fixture$repo, c("push", "-u", "origin", "main"))

    future <- format(Sys.time() + 86400, "%Y-%m-%dT%H:%M:%S%z")
    future_sha <- commit_file(fixture$repo, "future.txt", "future", future)
    blocked_sha <- commit_file(fixture$repo, "blocked.txt", "blocked", "2020-01-02T00:00:00+0000")

    pusher::add_repo(fixture$repo)
    upcoming <- pusher::upcoming_pushes()

    expect_equal(upcoming$sha, c(future_sha, blocked_sha))
    expect_equal(upcoming$state, c("waiting", "blocked"))
    expect_equal(upcoming$position, c(1L, 2L))
  })
})

test_that("upcoming_pushes respects n", {
  with_pusher_home({
    fixture <- make_repo()
    commit_file(fixture$repo, "initial.txt", "initial", "2020-01-01T00:00:00+0000")
    git(fixture$repo, c("push", "-u", "origin", "main"))

    first <- format(Sys.time() + 86400, "%Y-%m-%dT%H:%M:%S%z")
    second <- format(Sys.time() + 86400 * 2, "%Y-%m-%dT%H:%M:%S%z")
    first_sha <- commit_file(fixture$repo, "first.txt", "first", first)
    commit_file(fixture$repo, "second.txt", "second", second)

    pusher::add_repo(fixture$repo)

    expect_equal(pusher::upcoming_pushes(n = 1)$sha, first_sha)
    expect_equal(pusher::upcoming_pushes(n = 1)$title, "commit first.txt")
    expect_equal(nrow(pusher::upcoming_pushes(n = 0)), 0L)
  })
})
