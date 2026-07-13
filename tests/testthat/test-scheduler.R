test_that("scheduler plist uses a 30-minute interval", {
  with_pusher_home({
    plist <- pusher:::.scheduler_plist()

    expect_match(plist, "<key>StartInterval</key>", fixed = TRUE)
    expect_match(plist, "<integer>1800</integer>", fixed = TRUE)
  })
})
