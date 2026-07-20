# pusher

`pusher` tracks local Git repositories or worktrees and pushes unpublished commits once their scheduled date has arrived.

The scheduled date for a commit is the later of its author date and committer date. `pusher` is designed for linear unpublished histories. It never pulls, merges, rebases, or force-pushes.

## Install

From this package directory:

```sh
R CMD INSTALL .
```

## Track A Repository

From inside a Git worktree:

```r
pusher::add_repo(".")
```

The current branch is stored at add time. Future scheduler runs keep tracking that branch, even if the worktree later checks out another branch.

List tracked repositories:

```r
pusher::list_repos()
```

Remove one:

```r
pusher::remove_repo("/path/to/repo")
```

## Dry Run

Before enabling automatic pushes, inspect what would happen:

```r
pusher::status()
pusher::upcoming_pushes()
pusher::check_once(dry_run = TRUE)
```

`upcoming_pushes()` includes each commit title and a `state` column. `due`
commits can be pushed on the next check, `waiting` commits are still scheduled
for the future, and `blocked` commits are due by date but cannot be pushed before
an earlier unpublished commit.

When commits are due, `pusher` pushes the newest contiguous due commit:

```sh
git push origin <sha>:refs/heads/<branch>
```

That pushes all earlier due ancestors but avoids pushing later future-dated commits.

## Real Run

```r
pusher::check_once(dry_run = FALSE)
```

Logs are written to:

```text
~/.pusher/pusher.log
```

List recent successful pushes:

```r
pusher::last_pushes()
pusher::last_pushes(n = 5)
```

Show the next check estimate, unpublished commits in line, and recent pushes:

```r
pusher::overview()
```

The printed overview uses your system timezone.

Successful push notifications are off by default. On macOS, enable or disable
them with:

```r
pusher::notifications_enabled()
pusher::set_notifications(TRUE)
pusher::notification_style()
pusher::set_notification_style("alert")
pusher::set_notification_style("banner")
pusher::set_notifications(FALSE)
```

Use `"banner"` for standard Notification Center banners, or `"alert"` for a
persistent macOS alert that must be dismissed.

Tracked repository config is written to:

```text
~/.pusher/repos.json
```

## macOS Scheduler

Install a LaunchAgent that checks every 30 minutes:

```r
pusher::install_scheduler()
```

Change the check interval. If the LaunchAgent is already installed, it is
rewritten automatically and reloaded when currently loaded:

```r
pusher::scheduler_interval()
pusher::set_scheduler_interval(15)
```

Check scheduler status:

```r
pusher::scheduler_status()
```

Uninstall it:

```r
pusher::uninstall_scheduler()
```

The LaunchAgent is installed at:

```text
~/Library/LaunchAgents/com.pusher.scheduler.plist
```

A copy is stored at:

```text
~/.pusher/launchd/com.pusher.scheduler.plist
```
