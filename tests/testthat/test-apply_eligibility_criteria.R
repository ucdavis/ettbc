test_that("eligible participants are selected with the correct entry month", {
  demographics <- data.frame(
    id = 1:2,
    agein_month = c(12, 12),
    death_month = c(NA, NA),
    orec = c(0, 0)
  )
  enrollment <- data.frame(
    id = rep(1:2, each = 12),
    month = rep(1:12, 2),
    buyin = "3",
    hmo = "0"
  )
  mammograms <- data.frame(id = c(1, 2), month = c(12, 15))

  out <- apply_eligibility_criteria(demographics, enrollment, mammograms)

  expect_equal(out$id, 1)
  expect_equal(out$agein_month, 12)
  expect_equal(out$start_month, 12)
})

test_that("death before the age threshold excludes the participant", {
  demographics <- data.frame(
    id = 1, agein_month = 10, death_month = 9, orec = 0
  )
  enrollment <- data.frame(
    id = rep(1, 12), month = 1:12, buyin = "3", hmo = "0"
  )
  mammograms <- data.frame(id = 1, month = 11)

  out <- apply_eligibility_criteria(demographics, enrollment, mammograms)
  expect_equal(nrow(out), 0L)
})

test_that("death at or after the age threshold does not exclude", {
  demographics <- data.frame(
    id = 1, agein_month = 15, death_month = 15, orec = 0
  )
  enrollment <- data.frame(
    id = rep(1, 20), month = 1:20, buyin = "3", hmo = "0"
  )
  mammograms <- data.frame(id = 1, month = 16)

  out <- apply_eligibility_criteria(demographics, enrollment, mammograms)
  expect_equal(nrow(out), 1L)
})

test_that("no qualifying mammogram excludes the participant", {
  demographics <- data.frame(
    id = 1, agein_month = 12, death_month = NA, orec = 0
  )
  enrollment <- data.frame(
    id = rep(1, 24), month = 1:24, buyin = "3", hmo = "0"
  )
  # mammogram is outside the 12-month window starting at agein_month = 12
  mammograms <- data.frame(id = 1, month = 25)

  out <- apply_eligibility_criteria(demographics, enrollment, mammograms)
  expect_equal(nrow(out), 0L)
})

test_that("the earliest qualifying mammogram is used, at the window edges", {
  demographics <- data.frame(
    id = 1, agein_month = 15, death_month = NA, orec = 0
  )
  enrollment <- data.frame(
    id = rep(1, 23), month = 4:26, buyin = "3", hmo = "0"
  )
  # month 15 is the window start, month 26 the window end (15:26, 12 months);
  # the earliest (15) should be picked as start_month.
  mammograms <- data.frame(id = 1, month = c(26, 15, 20))

  out <- apply_eligibility_criteria(demographics, enrollment, mammograms)
  expect_equal(out$start_month, 15)
})

test_that("a gap in the 12-month enrollment window excludes the participant", {
  demographics <- data.frame(
    id = 1, agein_month = 10, death_month = NA, orec = 0
  )
  enrollment <- data.frame(
    id = rep(1, 11), month = 1:11, buyin = "3", hmo = "0"
  ) # month 12 (part of the required 1:12 window) is missing entirely
  mammograms <- data.frame(id = 1, month = 12)

  out <- apply_eligibility_criteria(demographics, enrollment, mammograms)
  expect_equal(nrow(out), 0L)
})

test_that("HMO enrollment in the window excludes the participant", {
  demographics <- data.frame(
    id = 1, agein_month = 10, death_month = NA, orec = 0
  )
  enrollment <- data.frame(
    id = rep(1, 12), month = 1:12,
    buyin = "3", hmo = c(rep("0", 11), "1")
  )
  mammograms <- data.frame(id = 1, month = 12)

  out <- apply_eligibility_criteria(demographics, enrollment, mammograms)
  expect_equal(nrow(out), 0L)
})

test_that("a non-fee-for-service buy-in code excludes the participant", {
  demographics <- data.frame(
    id = 1, agein_month = 10, death_month = NA, orec = 0
  )
  enrollment <- data.frame(
    id = rep(1, 12), month = 1:12,
    buyin = c(rep("3", 11), "1"), hmo = "0"
  )
  mammograms <- data.frame(id = 1, month = 12)

  out <- apply_eligibility_criteria(demographics, enrollment, mammograms)
  expect_equal(nrow(out), 0L)
})

test_that("the 'C' buy-in code is also accepted", {
  demographics <- data.frame(
    id = 1, agein_month = 10, death_month = NA, orec = 0
  )
  enrollment <- data.frame(
    id = rep(1, 12), month = 1:12, buyin = "C", hmo = "0"
  )
  mammograms <- data.frame(id = 1, month = 12)

  out <- apply_eligibility_criteria(demographics, enrollment, mammograms)
  expect_equal(nrow(out), 1L)
})

test_that("orec != 0 excludes the participant", {
  demographics <- data.frame(
    id = 1, agein_month = 10, death_month = NA, orec = 1
  )
  enrollment <- data.frame(
    id = rep(1, 12), month = 1:12, buyin = "3", hmo = "0"
  )
  mammograms <- data.frame(id = 1, month = 12)

  out <- apply_eligibility_criteria(demographics, enrollment, mammograms)
  expect_equal(nrow(out), 0L)
})

test_that("a missing orec excludes the participant", {
  demographics <- data.frame(
    id = 1, agein_month = 10, death_month = NA, orec = NA
  )
  enrollment <- data.frame(
    id = rep(1, 12), month = 1:12, buyin = "3", hmo = "0"
  )
  mammograms <- data.frame(id = 1, month = 12)

  out <- apply_eligibility_criteria(demographics, enrollment, mammograms)
  expect_equal(nrow(out), 0L)
})

test_that("custom column names are respected", {
  demographics <- data.frame(
    pid = 1, agein_mo = 10, dth_mo = NA, entitlement_reason = 0
  )
  enrollment <- data.frame(
    pid = rep(1, 12), mo = 1:12, buy = "3", hmoind = "0"
  )
  mammograms <- data.frame(pid = 1, mo = 12)

  out <- apply_eligibility_criteria(
    demographics, enrollment, mammograms,
    id_col = "pid", agein_month_col = "agein_mo", death_month_col = "dth_mo",
    orec_col = "entitlement_reason", enrollment_month_col = "mo",
    buyin_col = "buy", hmo_col = "hmoind", mammo_month_col = "mo"
  )

  expect_equal(out$pid, 1)
  expect_equal(out$start_month, 12)
})

test_that("enrollment_window_months controls the required enrollment span", {
  demographics <- data.frame(
    id = 1, agein_month = 12, death_month = NA, orec = 0
  )
  mammograms <- data.frame(id = 1, month = 12)
  enrollment <- data.frame(
    id = rep(1, 6), month = 7:12, buyin = "3", hmo = "0"
  )

  out_default <- apply_eligibility_criteria(
    demographics, enrollment, mammograms
  )
  expect_equal(nrow(out_default), 0L)

  out_narrow <- apply_eligibility_criteria(
    demographics, enrollment, mammograms, enrollment_window_months = 6L
  )
  expect_equal(out_narrow$start_month, 12)
})

test_that("mammo_window_months controls the entry-mammogram search window", {
  demographics <- data.frame(
    id = 1, agein_month = 12, death_month = NA, orec = 0
  )
  mammograms <- data.frame(id = 1, month = 30) # outside the default window
  enrollment <- data.frame(
    id = rep(1, 12), month = 19:30, buyin = "3", hmo = "0"
  )

  out_default <- apply_eligibility_criteria(
    demographics, enrollment, mammograms
  )
  expect_equal(nrow(out_default), 0L)

  out_wide <- apply_eligibility_criteria(
    demographics, enrollment, mammograms, mammo_window_months = 24L
  )
  expect_equal(out_wide$start_month, 30)
})

test_that("empty inputs return a zero-row result with the expected columns", {
  demographics <- data.frame(
    id = integer(0), agein_month = integer(0),
    death_month = integer(0), orec = integer(0)
  )
  enrollment <- data.frame(
    id = integer(0), month = integer(0),
    buyin = character(0), hmo = character(0)
  )
  mammograms <- data.frame(id = integer(0), month = integer(0))

  out <- apply_eligibility_criteria(demographics, enrollment, mammograms)
  expect_equal(nrow(out), 0L)
  expect_named(out, c("id", "agein_month", "start_month"))
})

test_that("missing required columns are reported", {
  demographics <- data.frame(id = 1, agein_month = 10, death_month = NA)
  enrollment <- data.frame(id = 1, month = 1, buyin = "3", hmo = "0")
  mammograms <- data.frame(id = 1, month = 1)

  expect_error(
    apply_eligibility_criteria(demographics, enrollment, mammograms),
    "demographics"
  )

  demographics2 <- data.frame(
    id = 1, agein_month = 10, death_month = NA, orec = 0
  )
  enrollment2 <- data.frame(id = 1, month = 1, buyin = "3")
  expect_error(
    apply_eligibility_criteria(demographics2, enrollment2, mammograms),
    "enrollment"
  )

  mammograms2 <- data.frame(id = 1)
  expect_error(
    apply_eligibility_criteria(demographics2, enrollment, mammograms2),
    "mammograms"
  )
})
