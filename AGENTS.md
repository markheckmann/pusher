# Agent Instructions

This repository is an R package named `pusher`. It tracks local Git repositories or worktrees and pushes unpublished commits only after their scheduled date has arrived.

## Project Rules

- Keep the package small and dependency-light.
- Preserve the core safety behavior: never pull, merge, rebase, force-push, or blindly push a branch tip.
- A commit is due when the later of its author date and committer date is less than or equal to the current time.
- Assume unpublished history is linear; reject merge commits instead of trying to handle them.
- Track the branch captured when `add_repo()` is called, not whatever branch the worktree has checked out later.
- Store user state under `~/.pusher` unless explicitly changed.
- macOS `launchd` is the scheduler target for now.

## Important Commands

Run tests and checks from the package root:

```sh
R CMD build .
R CMD check pusher_0.0.1.tar.gz --no-manual
```

For local installation:

```sh
R CMD INSTALL .
```

## Implementation Notes

- User-facing functions are exported in `NAMESPACE` and documented in `man/`.
- Git interaction is intentionally shell-based via `system2("git", ...)`.
- Tests use temporary Git repositories and should not touch real user repositories.
- Use `PUSHER_HOME` in tests to isolate state from `~/.pusher`.
- If generated check artifacts appear, remove them before finishing: `pusher.Rcheck`, `..Rcheck`, and `pusher_*.tar.gz`.

## Verification Expectations

- Run `R CMD check` on a built tarball after behavior changes.
- Add or update `testthat` tests for Git behavior, date selection, config handling, and scheduler changes when relevant.
- Do not install or load the real user LaunchAgent during tests.
