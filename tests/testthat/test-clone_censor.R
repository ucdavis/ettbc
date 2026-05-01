test_that("clone_censor returns two rows per participant", {
  result <- clone_censor(cohort, screening_mammograms, diagnostic_mammograms)
  expect_equal(nrow(result), 2L * nrow(cohort))
})

test_that("clone_censor produces both arm labels", {
  result <- clone_censor(cohort, screening_mammograms, diagnostic_mammograms)
  expect_true(all(c("STOPBASE", "CONTINUE") %in% result$arm))
  expect_equal(
    sort(unique(result$arm)),
    c("CONTINUE", "STOPBASE")
  )
})

test_that("clone_censor end_month does not exceed administrative end_month", {
  result <- clone_censor(cohort, screening_mammograms, diagnostic_mammograms)
  # The cloned end_month must be <= the original administrative end_month
  merged <- merge(result, cohort[, c("id", "start_month")],
    by = "id",
    suffixes = c("", "_orig")
  )
  # All follow-up times must be positive
  expect_true(all(result$fup >= 1L))
})

test_that("clone_censor fup equals end_month - start_month + 1", {
  result <- clone_censor(cohort, screening_mammograms, diagnostic_mammograms)
  expect_equal(
    result$fup,
    result$end_month - result$start_month + 1L
  )
})

test_that("clone_censor STOPBASE censors annual screeners quickly", {
  # A participant who gets a screening mammo every month after the grace period
  # should be censored in the STOPBASE arm shortly after grace period ends.
  dat <- data.frame(
    id = 1L,
    start_month = 10L,
    end_month = 108L,
    death_month = NA_integer_,
    bc_death = 0L,
    bc_month = NA_integer_,
    stringsAsFactors = FALSE
  )
  # Screening mammo every month from month 1 to 108
  scr <- data.frame(id = 1L, month = 1L:108L, stringsAsFactors = FALSE)
  dx <- data.frame(
    id = integer(0), month = integer(0), stringsAsFactors = FALSE
  )

  result <- clone_censor(dat, scr, dx, stop_grace_months = 9L)
  stopbase <- result[result$arm == "STOPBASE", ]

  # Should be censored at month 20 (first post-grace screening mammo:
  # start_month + stop_grace_months + 1 = 10 + 9 + 1 = 20)
  expect_equal(stopbase$censor_month, 20L)
  expect_equal(stopbase$end_month, 20L)
})

test_that("clone_censor CONTINUE censors non-adherers", {
  # A participant who never gets a mammogram should be censored in CONTINUE
  # after the grace period expires.
  dat <- data.frame(
    id = 1L,
    start_month = 10L,
    end_month = 108L,
    death_month = NA_integer_,
    bc_death = 0L,
    bc_month = NA_integer_,
    stringsAsFactors = FALSE
  )
  scr <- data.frame(
    id = integer(0), month = integer(0), stringsAsFactors = FALSE
  )
  dx <- data.frame(
    id = integer(0), month = integer(0), stringsAsFactors = FALSE
  )

  # continue_grace_months = 13 means months 10-22 are uncensorable by grace
  # First censorable month = 10 + 13 = 23
  result <- clone_censor(dat, scr, dx, continue_grace_months = 13L)
  cont <- result[result$arm == "CONTINUE", ]

  expect_equal(cont$censor_month, 23L)
  expect_equal(cont$end_month, 23L)
})

test_that("clone_censor BC diagnosis prevents censoring", {
  # Participant diagnosed with BC should not be censored in either arm
  # after the BC diagnosis month.
  dat <- data.frame(
    id = 1L,
    start_month = 10L,
    end_month = 108L,
    death_month = NA_integer_,
    bc_death = 0L,
    bc_month = 15L, # BC diagnosed at month 15
    stringsAsFactors = FALSE
  )
  # Screening mammo at month 30 (after grace period AND after BC)
  scr <- data.frame(id = 1L, month = 30L, stringsAsFactors = FALSE)
  dx <- data.frame(
    id = integer(0), month = integer(0), stringsAsFactors = FALSE
  )

  result <- clone_censor(dat, scr, dx, stop_grace_months = 9L)
  stopbase <- result[result$arm == "STOPBASE", ]

  # Month 30 screening mammo should NOT censor because BC was diagnosed at 15
  expect_true(is.na(stopbase$censor_month))
  expect_equal(stopbase$end_month, 108L)
})

test_that("clone_censor died indicator is correct for STOPBASE", {
  # In STOPBASE with no mammograms (nothing to trigger censoring),
  # the participant reaches their death month uncensored.
  dat <- data.frame(
    id = 1L,
    start_month = 10L,
    end_month = 50L,
    death_month = 50L,
    bc_death = 0L,
    bc_month = NA_integer_,
    stringsAsFactors = FALSE
  )
  scr <- data.frame(
    id = integer(0), month = integer(0), stringsAsFactors = FALSE
  )
  dx <- data.frame(
    id = integer(0), month = integer(0), stringsAsFactors = FALSE
  )

  result <- clone_censor(dat, scr, dx)
  stopbase <- result[result$arm == "STOPBASE", ]

  expect_equal(stopbase$died, 1L)
  expect_equal(stopbase$end_month, 50L)
})

test_that("clone_censor CONTINUE arm censors before death when no mammograms", {
  # In CONTINUE with no mammograms, the participant is censored after the grace
  # period expires, before reaching the death month.
  dat <- data.frame(
    id = 1L,
    start_month = 10L,
    end_month = 50L,
    death_month = 50L,
    bc_death = 0L,
    bc_month = NA_integer_,
    stringsAsFactors = FALSE
  )
  scr <- data.frame(
    id = integer(0), month = integer(0), stringsAsFactors = FALSE
  )
  dx <- data.frame(
    id = integer(0), month = integer(0), stringsAsFactors = FALSE
  )

  # Grace period ends at 10 + 13 - 1 = 22; first censorable month = 23
  result <- clone_censor(dat, scr, dx, continue_grace_months = 13L)
  cont <- result[result$arm == "CONTINUE", ]

  expect_equal(cont$censor_month, 23L)
  expect_equal(cont$end_month, 23L)
  expect_equal(cont$died, 0L) # censored, not counted as dead
})
