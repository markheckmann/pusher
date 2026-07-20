.empty_upcoming_pushes <- function() {
  data.frame(
    repo_root = character(),
    branch = character(),
    remote = character(),
    remote_branch = character(),
    sha = character(),
    title = character(),
    position = integer(),
    state = character(),
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

  states <- rep("waiting", nrow(commits))
  due <- commits$effective_date <= now
  states[due] <- "blocked"
  if (analysis$due > 0L) {
    states[seq_len(analysis$due)] <- "due"
  }

  positions <- seq_len(nrow(commits))
  data.frame(
    repo_root = analysis$repo_root,
    branch = analysis$branch,
    remote = analysis$remote,
    remote_branch = analysis$remote_branch,
    sha = commits$sha,
    title = commits$title,
    position = positions,
    state = states,
    author_date = format(commits$author_date, "%Y-%m-%dT%H:%M:%S%z", tz = "UTC"),
    committer_date = format(commits$committer_date, "%Y-%m-%dT%H:%M:%S%z", tz = "UTC"),
    effective_date = format(commits$effective_date, "%Y-%m-%dT%H:%M:%S%z", tz = "UTC"),
    stringsAsFactors = FALSE
  )
}

#' List unpublished commits waiting to be pushed
#'
#' @param n Maximum number of unpublished commits to return.
#' @return A data frame of unpublished commits, including commit titles and a
#'   `state` column. `due` commits can be pushed on the next check, `waiting`
#'   commits are still scheduled for the future, and `blocked` commits are due
#'   by date but cannot be pushed before an earlier unpublished commit.
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

  state_rank <- match(upcoming$state, c("due", "waiting", "blocked"))
  upcoming <- upcoming[order(state_rank, .iso_to_time(upcoming$effective_date), upcoming$repo_root, upcoming$position), , drop = FALSE]
  upcoming[seq_len(min(nrow(upcoming), n)), , drop = FALSE]
}
