# pusher 0.0.3

* Styled `overview()` output with `cli` headers and colored text.

* Added commit titles to successful push notification messages.

* Added a `Next push in X minutes` summary line to `overview()`.

* Added commit titles to `upcoming_pushes()` and the `overview()` upcoming
  commits section.

* Changed the macOS scheduler from hourly to every 30 minutes.

* Changed `overview()` output to print timestamps in the system timezone.

* Added `overview()` to print the next check cycle estimate, upcoming
  commits, and recent successful pushes in one place.

* Added opt-in macOS notifications for successful pushes. Notifications are off
  by default and can be toggled with `set_notifications()` and inspected with
  `notifications_enabled()`.

# pusher 0.0.2

* Added `upcoming_pushes()` to list future unpublished commits across tracked
  repositories, ordered by the later of their author and committer dates.

* Added `last_pushes()` to show recent successful pushes from the pusher log.

* Regenerated roxygen documentation and exports so all user-facing functions are
  exported from the package namespace.

# pusher 0.0.1

* Initial release of `pusher`, an R package for tracking local Git repositories
  and pushing unpublished commits only after their scheduled date has arrived.

* Added repository registration helpers: `add_repo()`, `list_repos()`, and
  `remove_repo()`.

* Added `status()` and `check_once()` for inspecting unpublished commits and
  pushing the latest contiguous due commit without pulling, merging, rebasing,
  force-pushing, or blindly pushing a branch tip.

* Added macOS `launchd` scheduler helpers: `install_scheduler()`,
  `uninstall_scheduler()`, and `scheduler_status()`.

* Added package tests using temporary Git repositories and isolated pusher state
  via `PUSHER_HOME`.
