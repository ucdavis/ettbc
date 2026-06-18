test_that("bootstrap_ci returns correct structure", {
  cloned <- clone_censor(cohort, screening_mammograms, diagnostic_mammograms)
  long_data <- expand_to_long(cloned)
  long_data$p_scrmammo <- 0.3
  long_data$monthBC <- NA_integer_
  long_data$scrmammo <- 0L
  long_data$tslm_lag <- 5L

  result <- bootstrap_ci(
    long_data,
    pred_prob_col = "p_scrmammo",
    n_boot = 5L,
    seed = 42L
  )

  expect_s3_class(result, "data.frame")
  expect_named(result, c(
    "month", "diff", "diff_lo", "diff_hi",
    "s_continue", "s_stopbase",
    "s_continue_lo", "s_continue_hi",
    "s_stopbase_lo", "s_stopbase_hi"
  ))
  expect_equal(nrow(result), 96L)
})

test_that("bootstrap_ci returns NA-filled result for empty data", {
  empty <- data.frame(
    id = integer(0), arm = character(0), month2 = integer(0),
    dead_t1 = integer(0), p_scrmammo = numeric(0),
    monthBC = integer(0), scrmammo = integer(0),
    anymammo = integer(0), tslm_lag = integer(0)
  )
  result <- bootstrap_ci(empty, pred_prob_col = "p_scrmammo", n_boot = 2L)
  expect_equal(nrow(result), 96L)
  expect_true(all(is.na(result$diff)))
})

test_that("bootstrap_ci seed produces reproducible results", {
  cloned <- clone_censor(cohort, screening_mammograms, diagnostic_mammograms)
  long_data <- expand_to_long(cloned)
  long_data$p_scrmammo <- 0.3
  long_data$monthBC <- NA_integer_
  long_data$scrmammo <- 0L
  long_data$tslm_lag <- 5L

  r1 <- bootstrap_ci(
    long_data, pred_prob_col = "p_scrmammo",
    n_boot = 5L, seed = 7L
  )
  r2 <- bootstrap_ci(
    long_data, pred_prob_col = "p_scrmammo",
    n_boot = 5L, seed = 7L
  )
  expect_equal(r1$diff_lo, r2$diff_lo)
  expect_equal(r1$diff_hi, r2$diff_hi)
})
