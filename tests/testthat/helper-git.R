git <- function(repo, args, env = character()) {
  output <- suppressWarnings(system2(
    "git",
    c("-C", repo, args),
    stdout = TRUE,
    stderr = TRUE,
    env = env
  ))
  code <- attr(output, "status")
  if (is.null(code)) {
    code <- 0L
  }
  if (code != 0L) {
    stop(sprintf("git %s failed: %s", paste(args, collapse = " "), paste(output, collapse = "\n")))
  }
  output
}

make_repo <- function() {
  root <- tempfile("pusher-test-")
  dir.create(root)
  bare <- file.path(root, "remote.git")
  repo <- file.path(root, "repo")

  system2("git", c("init", "--bare", bare), stdout = TRUE, stderr = TRUE)
  system2("git", c("clone", bare, repo), stdout = TRUE, stderr = TRUE)
  git(repo, c("checkout", "-b", "main"))
  git(repo, c("config", "user.email", "test@example.com"))
  git(repo, c("config", "user.name", "Pusher Test"))

  list(root = root, bare = bare, repo = repo)
}

commit_file <- function(repo, name, content, date) {
  writeLines(content, file.path(repo, name))
  git(repo, c("add", name))
  git(
    repo,
    c("commit", "-m", shQuote(paste("commit", name))),
    env = c(
      paste0("GIT_AUTHOR_DATE=", date),
      paste0("GIT_COMMITTER_DATE=", date)
    )
  )
  git(repo, c("rev-parse", "HEAD"))[[1]]
}

with_pusher_home <- function(code) {
  old <- Sys.getenv("PUSHER_HOME", unset = NA_character_)
  home <- tempfile("pusher-home-")
  dir.create(home)
  Sys.setenv(PUSHER_HOME = home)
  on.exit({
    if (is.na(old)) {
      Sys.unsetenv("PUSHER_HOME")
    } else {
      Sys.setenv(PUSHER_HOME = old)
    }
  }, add = TRUE)
  force(code)
}
