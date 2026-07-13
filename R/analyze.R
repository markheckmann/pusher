.analyze_repo <- function(repo, now = Sys.time()) {
  repo_root <- repo$repo_root[[1]]
  remote <- repo$remote[[1]]
  branch <- repo$branch[[1]]
  remote_branch <- repo$remote_branch[[1]]

  if (!dir.exists(repo_root)) {
    stop(sprintf("Repository path does not exist: %s", repo_root), call. = FALSE)
  }

  .git_assert_branch_exists(repo_root, branch)
  .git_assert_remote_ref_exists(repo_root, remote, remote_branch)
  .git_assert_remote_ancestor(repo_root, remote, remote_branch, branch)
  .git_assert_linear_range(repo_root, remote, remote_branch, branch)

  commits <- .git_unpublished_commits(repo_root, remote, remote_branch, branch)
  info <- .git_commit_infos(repo_root, commits)

  due_count <- 0L
  if (nrow(info)) {
    due <- info$effective_date <= now
    first_not_due <- match(FALSE, due)
    due_count <- if (is.na(first_not_due)) length(due) else first_not_due - 1L
  }

  due_sha <- if (due_count > 0L) info$sha[[due_count]] else NA_character_
  next_due <- if (due_count < nrow(info)) info$effective_date[[due_count + 1L]] else as.POSIXct(NA)

  list(
    repo_root = repo_root,
    remote = remote,
    branch = branch,
    remote_branch = remote_branch,
    unpushed = nrow(info),
    due = due_count,
    due_sha = due_sha,
    next_due = next_due,
    commits = info
  )
}

.analysis_row <- function(repo, analysis = NULL, error = NULL) {
  if (!is.null(error)) {
    return(data.frame(
      repo_root = repo$repo_root[[1]],
      branch = repo$branch[[1]],
      remote = repo$remote[[1]],
      remote_branch = repo$remote_branch[[1]],
      unpushed = NA_integer_,
      due = NA_integer_,
      next_due = NA_character_,
      due_sha = NA_character_,
      last_result = paste("ERROR", conditionMessage(error)),
      stringsAsFactors = FALSE
    ))
  }

  data.frame(
    repo_root = analysis$repo_root,
    branch = analysis$branch,
    remote = analysis$remote,
    remote_branch = analysis$remote_branch,
    unpushed = analysis$unpushed,
    due = analysis$due,
    next_due = .time_to_iso(analysis$next_due),
    due_sha = analysis$due_sha,
    last_result = .last_log_result(analysis$repo_root),
    stringsAsFactors = FALSE
  )
}
