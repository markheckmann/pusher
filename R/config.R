.empty_repos <- function() {
  data.frame(
    path = character(),
    repo_root = character(),
    remote = character(),
    branch = character(),
    remote_branch = character(),
    created_at = character(),
    stringsAsFactors = FALSE
  )
}

.read_repos <- function() {
  path <- .config_file()
  if (!file.exists(path)) {
    return(.empty_repos())
  }

  repos <- jsonlite::fromJSON(path, simplifyDataFrame = TRUE)
  if (!length(repos)) {
    return(.empty_repos())
  }

  repos <- as.data.frame(repos, stringsAsFactors = FALSE)
  for (name in names(.empty_repos())) {
    if (!name %in% names(repos)) {
      repos[[name]] <- NA_character_
    }
  }
  repos[names(.empty_repos())]
}

.write_repos <- function(repos) {
  .ensure_pusher_dir()
  jsonlite::write_json(repos, .config_file(), pretty = TRUE, auto_unbox = TRUE)
  invisible(repos)
}

.normalize_user_path <- function(path) {
  normalizePath(path.expand(path), mustWork = TRUE)
}

#' Add a Git repository or worktree to pusher
#'
#' The current branch at add time is stored and used for future checks.
#'
#' @param path Path inside the Git repository or worktree.
#' @param remote Git remote name.
#' @return A data frame with all tracked repositories, invisibly.
add_repo <- function(path = ".", remote = "origin") {
  path <- .normalize_user_path(path)
  repo_root <- .git_repo_root(path)
  branch <- .git_current_branch(repo_root)
  remote_branch <- branch

  .git_assert_branch_exists(repo_root, branch)
  .git_assert_remote_ref_exists(repo_root, remote, remote_branch)

  repos <- .read_repos()
  repos <- repos[repos$repo_root != repo_root | repos$branch != branch, , drop = FALSE]
  repos <- rbind(
    repos,
    data.frame(
      path = path,
      repo_root = repo_root,
      remote = remote,
      branch = branch,
      remote_branch = remote_branch,
      created_at = .iso_now(),
      stringsAsFactors = FALSE
    )
  )
  .write_repos(repos)
  invisible(repos)
}

#' List tracked repositories
#'
#' @return A data frame of registered repositories.
list_repos <- function() {
  .read_repos()
}

#' Remove a tracked repository or worktree
#'
#' @param path Path originally added, or any path inside the same Git worktree.
#' @return A data frame with remaining repositories, invisibly.
remove_repo <- function(path) {
  path <- .normalize_user_path(path)
  repo_root <- tryCatch(.git_repo_root(path), error = function(e) path)

  repos <- .read_repos()
  keep <- repos$path != path & repos$repo_root != repo_root
  repos <- repos[keep, , drop = FALSE]
  .write_repos(repos)
  invisible(repos)
}
