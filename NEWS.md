# pusher 0.0.5

* Changed `overview_summary()` to include a count and compact bullet list of
  tracked repo/branch pairs.

* Changed `upcoming_pushes()` and `overview()` to include overdue unpublished
  commits, not just commits scheduled for the future. The listing now includes a
  `state` column: `due` commits can be pushed on the next check, `waiting`
  commits are scheduled for the future, and `blocked` commits are already due by
  date but cannot be pushed before an earlier unpublished commit.

# pusher 0.0.4

* Added `overview_summary()` to print only the `overview()` management summary
  lines.

* Added `scheduler_interval()` and `set_scheduler_interval()` to configure how
  often the macOS scheduler checks for due commits. Updating the interval also
  updates an installed LaunchAgent automatically.

* Renamed the macOS LaunchAgent label from `com.pusher.hourly` to
  `com.pusher.scheduler`; installing or uninstalling the scheduler removes the
  old LaunchAgent if present.

* Added a `Last push` summary line to `overview()`.

* Added a `Pushes in line` count to `overview()`.

* Changed the `overview()` next push summary to use rounded hours instead of
  large minute counts after 120 minutes.

* Added `notification_style()` and `set_notification_style()` to choose between
  standard macOS notification banners and persistent macOS alerts.

# pusher 0.0.3

* Added commit titles to `last_pushes()` and the `overview()` last pushed
  commits section, including best-effort title lookup for older logs.

* Added the tracked remote to the `overview()` last pushed commits section.

* Changed `overview()` printed dates to human-readable local labels such as
  `in 20 minutes`, `tomorrow at 12:00`, and `2 hours ago`.

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
