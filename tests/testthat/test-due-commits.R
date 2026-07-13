test_that("status reports only contiguous due commits", {
  with_pusher_home({
    fixture <- make_repo()
    commit_file(fixture$repo, "initial.txt", "initial", "2020-01-01T00:00:00+0000")
    git(fixture$repo, c("push", "-u", "origin", "main"))

    due_sha <- commit_file(fixture$repo, "due.txt", "due", "2020-01-02T00:00:00+0000")
    future <- format(Sys.time() + 86400, "%Y-%m-%dT%H:%M:%S%z")
    commit_file(fixture$repo, "future.txt", "future", future)

    pusher::add_repo(fixture$repo)
    stat <- pusher::status()

    expect_equal(stat$unpushed, 2L)
    expect_equal(stat$due, 1L)
    expect_equal(stat$due_sha, due_sha)
    expect_false(is.na(stat$next_due))
  })
})

test_that("check_once dry run does not push", {
  with_pusher_home({
    fixture <- make_repo()
    commit_file(fixture$repo, "initial.txt", "initial", "2020-01-01T00:00:00+0000")
    git(fixture$repo, c("push", "-u", "origin", "main"))

    commit_file(fixture$repo, "due.txt", "due", "2020-01-02T00:00:00+0000")

    pusher::add_repo(fixture$repo)
    invisible(pusher::check_once(dry_run = TRUE))

    remote_head <- git(fixture$repo, c("rev-parse", "origin/main"))[[1]]
    local_head <- git(fixture$repo, c("rev-parse", "main"))[[1]]
    expect_false(identical(remote_head, local_head))
  })
})
