test_that(
  "expand_to_long produces correct number of rows for censored participant",
  {
    # Participant enters at month 10, last follow-up at month 20 (censored)
    dat <- data.frame(
      id = 1L,
      arm = "STOPBASE",
      start_month = 10L,
      end_month = 20L,
      died = 0L,
      bc_died = 0L,
      bc_month = NA_integer_,
      stringsAsFactors = FALSE
    )
    result <- expand_to_long(dat)
    # Should have 11 rows (months 10 through 20 inclusive)
    expect_equal(nrow(result), 11L)
  }
)

test_that(
  "expand_to_long produces correct number of rows for deceased participant",
  {
    # Participant enters at month 10, dies at month 20
    dat <- data.frame(
      id = 1L,
      arm = "STOPBASE",
      start_month = 10L,
      end_month = 20L,
      died = 1L,
      bc_died = 0L,
      bc_month = NA_integer_,
      stringsAsFactors = FALSE
    )
    result <- expand_to_long(dat)
    # 10 rows (months 10 through 19; month 20 is dropped for dead)
    expect_equal(nrow(result), 10L)
  }
)

test_that("expand_to_long sets dead_t1 correctly for deceased participant", {
  dat <- data.frame(
    id = 1L,
    arm = "STOPBASE",
    start_month = 10L,
    end_month = 20L,
    died = 1L,
    bc_died = 0L,
    bc_month = NA_integer_,
    stringsAsFactors = FALSE
  )
  result <- expand_to_long(dat)
  # Last row should have dead_t1 = 1; all others should be 0
  expect_equal(result$dead_t1[nrow(result)], 1L)
  expect_true(all(result$dead_t1[-nrow(result)] == 0L))
})

test_that(
  "expand_to_long sets dead_t1 = NA at last row for censored participant",
  {
    dat <- data.frame(
      id = 1L,
      arm = "STOPBASE",
      start_month = 10L,
      end_month = 20L,
      died = 0L,
      bc_died = 0L,
      bc_month = NA_integer_,
      stringsAsFactors = FALSE
    )
    result <- expand_to_long(dat)
    expect_true(is.na(result$dead_t1[nrow(result)]))
    expect_true(all(result$dead_t1[-nrow(result)] == 0L))
  }
)

test_that("expand_to_long month2 is 0-indexed from start_month", {
  dat <- data.frame(
    id = 1L,
    arm = "CONTINUE",
    start_month = 15L,
    end_month = 20L,
    died = 0L,
    bc_died = 0L,
    bc_month = NA_integer_,
    stringsAsFactors = FALSE
  )
  result <- expand_to_long(dat)
  expect_equal(min(result$month2), 0L)
  expect_equal(max(result$month2), 20L - 15L)
})

test_that(
  "expand_to_long bc_long flag is set at breast cancer diagnosis month",
  {
    dat <- data.frame(
      id = 1L,
      arm = "STOPBASE",
      start_month = 10L,
      end_month = 20L,
      died = 0L,
      bc_died = 0L,
      bc_month = 15L,
      stringsAsFactors = FALSE
    )
    result <- expand_to_long(dat)
    expect_equal(result$bc_long[result$month == 15L], 1L)
    expect_true(all(result$bc_long[result$month != 15L] == 0L))
  }
)

test_that("expand_to_long bc_dead_t1 = 0 when death is not from BC", {
  dat <- data.frame(
    id = 1L,
    arm = "STOPBASE",
    start_month = 10L,
    end_month = 20L,
    died = 1L,
    bc_died = 0L, # died of other cause
    bc_month = NA_integer_,
    stringsAsFactors = FALSE
  )
  result <- expand_to_long(dat)
  # dead_t1 = 1 at last row, but bc_dead_t1 = 0
  expect_equal(result$dead_t1[nrow(result)], 1L)
  expect_equal(result$bc_dead_t1[nrow(result)], 0L)
})

test_that(
  "expand_to_long handles single-month follow-up (died in entry month)",
  {
    dat <- data.frame(
      id = 1L,
      arm = "STOPBASE",
      start_month = 10L,
      end_month = 10L,
      died = 1L,
      bc_died = 0L,
      bc_month = NA_integer_,
      stringsAsFactors = FALSE
    )
    result <- expand_to_long(dat)
    # Single row, dead_t1 = NA (indeterminate within a single month)
    expect_equal(nrow(result), 1L)
    expect_true(is.na(result$dead_t1))
  }
)

test_that("expand_to_long works on clone_censor output", {
  cloned <- clone_censor(cohort, screening_mammograms, diagnostic_mammograms)
  long_data <- expand_to_long(cloned)

  expect_true(nrow(long_data) > 0L)
  expected_cols <- c(
    "id", "arm", "month", "month2", "dead_t1", "bc_dead_t1", "bc_long"
  )
  expect_true(all(expected_cols %in% names(long_data)))
  # month2 should be non-negative
  expect_true(all(long_data$month2 >= 0L))
})
