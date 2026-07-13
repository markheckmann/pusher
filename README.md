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

`upcoming_pushes()` includes each commit title.

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

Show the next check estimate, next commits to push, and recent pushes:

```r
pusher::overview()
```

The printed overview uses your system timezone.

Successful push notifications are off by default. On macOS, enable or disable
them with:

```r
pusher::notifications_enabled()
pusher::set_notifications(TRUE)
pusher::set_notifications(FALSE)
```

Tracked repository config is written to:

```text
~/.pusher/repos.json
```

## macOS Scheduler

Install a LaunchAgent that checks every 30 minutes:

```r
pusher::install_scheduler()
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
~/Library/LaunchAgents/com.pusher.hourly.plist
```

A copy is stored at:

```text
~/.pusher/launchd/com.pusher.hourly.plist
```
