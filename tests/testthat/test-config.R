test_that("add_repo stores the current branch", {
  with_pusher_home({
    fixture <- make_repo()
    commit_file(fixture$repo, "initial.txt", "initial", "2020-01-01T00:00:00+0000")
    git(fixture$repo, c("push", "-u", "origin", "main"))

    pusher::add_repo(fixture$repo)
    repos <- pusher::list_repos()

    expect_equal(nrow(repos), 1L)
    expect_equal(repos$repo_root, normalizePath(fixture$repo))
    expect_equal(repos$branch, "main")
    expect_equal(repos$remote, "origin")
    expect_equal(repos$remote_branch, "main")
  })
})

test_that("remove_repo removes by worktree path", {
  with_pusher_home({
    fixture <- make_repo()
    commit_file(fixture$repo, "initial.txt", "initial", "2020-01-01T00:00:00+0000")
    git(fixture$repo, c("push", "-u", "origin", "main"))

    pusher::add_repo(fixture$repo)
    pusher::remove_repo(fixture$repo)

    expect_equal(nrow(pusher::list_repos()), 0L)
  })
})
