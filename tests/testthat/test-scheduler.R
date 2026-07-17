test_that("scheduler plist uses a 30-minute interval", {
  with_pusher_home({
    plist <- pusher:::.scheduler_plist()

    expect_match(plist, "<string>com.pusher.scheduler</string>", fixed = TRUE)
    expect_match(plist, "<key>StartInterval</key>", fixed = TRUE)
    expect_match(plist, "<integer>1800</integer>", fixed = TRUE)
  })
})

test_that("scheduler label is interval neutral", {
  expect_equal(pusher:::.launchd_label(), "com.pusher.scheduler")
  expect_equal(basename(pusher:::.launchd_target()), "com.pusher.scheduler.plist")
  expect_equal(basename(pusher:::.legacy_launchd_target()), "com.pusher.hourly.plist")
})

test_that("scheduler interval can be changed", {
  with_pusher_home({
    expect_equal(pusher::scheduler_interval(), 30L)

    expect_invisible(pusher::set_scheduler_interval(15, apply = FALSE))
    expect_equal(pusher::scheduler_interval(), 15L)

    plist <- pusher:::.scheduler_plist()
    expect_match(plist, "<integer>900</integer>", fixed = TRUE)
  })
})

test_that("set_scheduler_interval validates input", {
  with_pusher_home({
    expect_error(pusher::set_scheduler_interval(0, apply = FALSE), "minutes")
    expect_error(pusher::set_scheduler_interval(1.5, apply = FALSE), "minutes")
    expect_error(pusher::set_scheduler_interval(15, apply = NA), "apply")
  })
})
