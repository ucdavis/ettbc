test_that("clone_censor returns two rows per participant", {
  result <- clone_censor(cohort, screening_mammograms, diagnostic_mammograms)
  expect_equal(nrow(result), 2L * nrow(cohort))
})

test_that("clone_censor produces both arm labels", {
  result <- clone_censor(cohort, screening_mammograms, diagnostic_mammograms)
  expect_setequal(result$arm, c("STOPBASE", "CONTINUE"))
})

test_that("clone_censor end_month does not exceed administrative end_month", {
  result <- clone_censor(cohort, screening_mammograms, diagnostic_mammograms)
  merged <- merge(result, cohort[, c("id", "end_month")],
    by = "id",
    suffixes = c("", "_orig")
  )
  expect_true(all(merged$end_month <= merged$end_month_orig))
})

test_that("clone_censor fup equals end_month - start_month + 1", {
  result <- clone_censor(cohort, screening_mammograms, diagnostic_mammograms)
  expect_equal(result$fup, result$end_month - result$start_month + 1L)
})

test_that("clone_censor output snapshot", {
  result <- clone_censor(cohort, screening_mammograms, diagnostic_mammograms)
  snapr::expect_snapshot_data(result, "clone_censor_output")
})

test_that("clone_censor STOPBASE censors annual screeners quickly", {
  dat <- data.frame(
    id = 1L,
    start_month = 10L,
    end_month = 108L,
    death_month = NA_integer_,
    bc_death = 0L,
    bc_month = NA_integer_,
    stringsAsFactors = FALSE
  )
  scr <- data.frame(id = 1L, month = 1L:108L, stringsAsFactors = FALSE)
  dx <- data.frame(
    id = integer(0), month = integer(0), stringsAsFactors = FALSE
  )
  result <- clone_censor(dat, scr, dx, stop_grace_months = 9L)
  snapr::expect_snapshot_data(result, "stopbase_annual_screeners")
})

test_that("clone_censor CONTINUE censors non-adherers", {
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
  result <- clone_censor(dat, scr, dx, continue_grace_months = 13L)
  snapr::expect_snapshot_data(result, "continue_non_adherers")
})

test_that("clone_censor BC diagnosis prevents censoring", {
  dat <- data.frame(
    id = 1L,
    start_month = 10L,
    end_month = 108L,
    death_month = NA_integer_,
    bc_death = 0L,
    bc_month = 15L,
    stringsAsFactors = FALSE
  )
  scr <- data.frame(id = 1L, month = 30L, stringsAsFactors = FALSE)
  dx <- data.frame(
    id = integer(0), month = integer(0), stringsAsFactors = FALSE
  )
  result <- clone_censor(dat, scr, dx, stop_grace_months = 9L)
  snapr::expect_snapshot_data(result, "bc_diagnosis_prevents_censoring")
})

test_that("clone_censor died indicator correct when no censoring", {
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
  snapr::expect_snapshot_data(result, "died_no_censoring")
})

test_that("clone_censor CONTINUE censors before death when no mammograms", {
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
  result <- clone_censor(dat, scr, dx, continue_grace_months = 13L)
  snapr::expect_snapshot_data(result, "continue_censors_before_death")
})
