.git <- function(repo, args, check = TRUE) {
  output <- suppressWarnings(system2(
    "git",
    c("-C", repo, args),
    stdout = TRUE,
    stderr = TRUE
  ))
  code <- attr(output, "status")
  if (is.null(code)) {
    code <- 0L
  }

  if (check && code != 0L) {
    stop(
      sprintf("git %s failed: %s", paste(args, collapse = " "), paste(output, collapse = "\n")),
      call. = FALSE
    )
  }

  list(code = code, output = output)
}

.git_output <- function(repo, args) {
  .git(repo, args, check = TRUE)$output
}

.git_repo_root <- function(path) {
  normalizePath(.git_output(path, c("rev-parse", "--show-toplevel"))[[1]], mustWork = TRUE)
}

.git_current_branch <- function(repo) {
  branch <- .git_output(repo, c("branch", "--show-current"))
  branch <- if (length(branch)) branch[[1]] else ""
  if (!nzchar(branch)) {
    stop("Repository is in detached HEAD state; checkout a branch before adding it.", call. = FALSE)
  }
  branch
}

.git_ref <- function(kind, remote = NULL, branch) {
  if (identical(kind, "local")) {
    return(file.path("refs", "heads", branch))
  }
  file.path("refs", "remotes", remote, branch)
}

.git_remote_short <- function(remote, branch) {
  paste0(remote, "/", branch)
}

.git_assert_branch_exists <- function(repo, branch) {
  .git_output(repo, c("rev-parse", "--verify", .git_ref("local", branch = branch)))
  invisible(TRUE)
}

.git_assert_remote_ref_exists <- function(repo, remote, branch) {
  .git_output(repo, c("rev-parse", "--verify", .git_ref("remote", remote, branch)))
  invisible(TRUE)
}

.git_assert_remote_ancestor <- function(repo, remote, remote_branch, branch) {
  remote_ref <- .git_ref("remote", remote, remote_branch)
  local_ref <- .git_ref("local", branch = branch)
  result <- .git(repo, c("merge-base", "--is-ancestor", remote_ref, local_ref), check = FALSE)
  if (result$code != 0L) {
    stop(sprintf("Remote ref %s is not an ancestor of local branch %s.", remote_ref, branch), call. = FALSE)
  }
  invisible(TRUE)
}

.git_assert_linear_range <- function(repo, remote, remote_branch, branch) {
  range <- paste0(.git_remote_short(remote, remote_branch), "..", branch)
  merges <- .git_output(repo, c("rev-list", "--merges", range))
  if (length(merges)) {
    stop("Unpublished history contains merge commits; pusher v1 expects linear history.", call. = FALSE)
  }
  invisible(TRUE)
}

.git_unpublished_commits <- function(repo, remote, remote_branch, branch) {
  range <- paste0(.git_remote_short(remote, remote_branch), "..", branch)
  .git_output(repo, c("rev-list", "--reverse", "--first-parent", range))
}

.git_commit_info <- function(repo, sha) {
  line <- .git_output(repo, c("show", "-s", "--format=%H%x09%aI%x09%cI", sha))[[1]]
  parts <- strsplit(line, "\t", fixed = TRUE)[[1]]
  if (length(parts) != 3) {
    stop(sprintf("Unexpected git show output for commit %s.", sha), call. = FALSE)
  }

  author_date <- .iso_to_time(parts[[2]])
  committer_date <- .iso_to_time(parts[[3]])
  effective_date <- max(author_date, committer_date)

  data.frame(
    sha = parts[[1]],
    author_date = author_date,
    committer_date = committer_date,
    effective_date = effective_date,
    stringsAsFactors = FALSE
  )
}

.git_commit_infos <- function(repo, shas) {
  if (!length(shas)) {
    return(data.frame(
      sha = character(),
      author_date = as.POSIXct(character()),
      committer_date = as.POSIXct(character()),
      effective_date = as.POSIXct(character()),
      stringsAsFactors = FALSE
    ))
  }

  do.call(rbind, lapply(shas, function(sha) .git_commit_info(repo, sha)))
}

.git_push_commit <- function(repo, remote, remote_branch, sha) {
  refspec <- paste0(sha, ":refs/heads/", remote_branch)
  .git_output(repo, c("push", remote, refspec))
  .git_output(repo, c("update-ref", .git_ref("remote", remote, remote_branch), sha))
  invisible(TRUE)
}
