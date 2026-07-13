.empty_upcoming_pushes <- function() {
  data.frame(
    repo_root = character(),
    branch = character(),
    remote = character(),
    remote_branch = character(),
    sha = character(),
    title = character(),
    position = integer(),
    author_date = character(),
    committer_date = character(),
    effective_date = character(),
    stringsAsFactors = FALSE
  )
}

.upcoming_rows <- function(analysis, now) {
  commits <- analysis$commits
  if (!nrow(commits)) {
    return(.empty_upcoming_pushes())
  }

  upcoming <- commits[commits$effective_date > now, , drop = FALSE]
  if (!nrow(upcoming)) {
    return(.empty_upcoming_pushes())
  }

  positions <- match(upcoming$sha, commits$sha)
  data.frame(
    repo_root = analysis$repo_root,
    branch = analysis$branch,
    remote = analysis$remote,
    remote_branch = analysis$remote_branch,
    sha = upcoming$sha,
    title = upcoming$title,
    position = positions,
    author_date = format(upcoming$author_date, "%Y-%m-%dT%H:%M:%S%z", tz = "UTC"),
    committer_date = format(upcoming$committer_date, "%Y-%m-%dT%H:%M:%S%z", tz = "UTC"),
    effective_date = format(upcoming$effective_date, "%Y-%m-%dT%H:%M:%S%z", tz = "UTC"),
    stringsAsFactors = FALSE
  )
}

#' List upcoming unpublished commits
#'
#' @param n Maximum number of upcoming commits to return.
#' @return A data frame of future unpublished commits, including commit titles,
#'   ordered by effective date.
#' @export
upcoming_pushes <- function(n = 20) {
  if (!is.numeric(n) || length(n) != 1L || is.na(n) || n < 0) {
    stop("n must be a single non-negative number.", call. = FALSE)
  }

  repos <- .read_repos()
  if (!nrow(repos) || n == 0) {
    return(.empty_upcoming_pushes())
  }

  now <- Sys.time()
  rows <- lapply(seq_len(nrow(repos)), function(i) {
    repo <- repos[i, , drop = FALSE]
    analysis <- tryCatch(.analyze_repo(repo, now), error = function(e) e)
    if (inherits(analysis, "error")) {
      warning(conditionMessage(analysis), call. = FALSE)
      return(.empty_upcoming_pushes())
    }
    .upcoming_rows(analysis, now)
  })

  upcoming <- do.call(rbind, rows)
  if (!nrow(upcoming)) {
    return(upcoming)
  }

  upcoming <- upcoming[order(.iso_to_time(upcoming$effective_date), upcoming$repo_root, upcoming$position), , drop = FALSE]
  upcoming[seq_len(min(nrow(upcoming), n)), , drop = FALSE]
}
