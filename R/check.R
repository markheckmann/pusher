#' Check tracked repositories once
#'
#' @param dry_run If `TRUE`, report what would be pushed without pushing.
#' @return A data frame summarising the run, invisibly.
check_once <- function(dry_run = TRUE) {
  repos <- .read_repos()
  if (!nrow(repos)) {
    message("No repositories are tracked.")
    return(invisible(data.frame()))
  }

  rows <- vector("list", nrow(repos))
  for (i in seq_len(nrow(repos))) {
    repo <- repos[i, , drop = FALSE]
    analysis <- tryCatch(.analyze_repo(repo), error = function(e) e)

    if (inherits(analysis, "error")) {
      .log_message(
        "ERROR",
        repo = repo$repo_root[[1]],
        branch = repo$branch[[1]],
        result = "failed",
        reason = conditionMessage(analysis)
      )
      rows[[i]] <- .analysis_row(repo, error = analysis)
      next
    }

    rows[[i]] <- .analysis_row(repo, analysis)

    if (analysis$due == 0L) {
      msg <- sprintf(
        "repo: %s\nbranch: %s\nunpushed: %s\ndue: 0\naction: noop",
        analysis$repo_root,
        analysis$branch,
        analysis$unpushed
      )
      message(msg)
      if (!dry_run) {
        .log_message("INFO", repo = analysis$repo_root, branch = analysis$branch, result = "noop", reason = "no_due_commits")
      }
      next
    }

    action <- if (dry_run) "would push" else "pushing"
    message(sprintf(
      "repo: %s\nbranch: %s\nunpushed: %s\ndue: %s\naction: %s %s to %s/%s",
      analysis$repo_root,
      analysis$branch,
      analysis$unpushed,
      analysis$due,
      action,
      analysis$due_sha,
      analysis$remote,
      analysis$remote_branch
    ))

    if (!dry_run) {
      pushed <- tryCatch({
        .git_push_commit(analysis$repo_root, analysis$remote, analysis$remote_branch, analysis$due_sha)
        TRUE
      }, error = function(e) e)

      if (inherits(pushed, "error")) {
        .log_message(
          "ERROR",
          repo = analysis$repo_root,
          branch = analysis$branch,
          result = "failed",
          sha = analysis$due_sha,
          reason = conditionMessage(pushed)
        )
      } else {
        .log_message(
          "INFO",
          repo = analysis$repo_root,
          branch = analysis$branch,
          result = "pushed",
          sha = analysis$due_sha,
          count = analysis$due
        )
      }
    }
  }

  invisible(do.call(rbind, rows))
}
