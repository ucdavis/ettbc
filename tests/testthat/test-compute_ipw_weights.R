test_that("compute_ipw_weights returns w and wp99 columns", {
  cloned <- clone_censor(cohort, screening_mammograms, diagnostic_mammograms)
  long_data <- expand_to_long(cloned)
  # Add fake predicted prob column and required IPW columns
  long_data$p_scrmammo <- 0.3
  long_data$monthBC <- NA_integer_
  long_data$scrmammo <- 0L
  long_data$tslm_lag <- 5L
  result <- compute_ipw_weights(long_data, pred_prob_col = "p_scrmammo")
  expect_true("w" %in% names(result))
  expect_true("wp99" %in% names(result))
  expect_true(all(result$wp99 >= 0, na.rm = TRUE))
})

test_that("compute_ipw_weights handles empty data", {
  empty <- data.frame(
    arm = character(0), id = integer(0), month2 = integer(0),
    monthBC = integer(0), scrmammo = integer(0),
    tslm_lag = integer(0),
    p_scrmammo = numeric(0),
    stringsAsFactors = FALSE
  )
  result <- compute_ipw_weights(empty, pred_prob_col = "p_scrmammo")
  expect_true("w" %in% names(result))
  expect_true("wp99" %in% names(result))
  expect_equal(nrow(result), 0L)
})

test_that("compute_ipw_weights STOPBASE grace period: weight stays at 1", {
  df_stop <- data.frame(
    id = rep(1L, 15L),
    arm = "STOPBASE",
    month2 = 0L:14L,
    monthBC = NA_integer_,
    scrmammo = 0L,
    tslm_lag = 15L,
    p_pred = 0.3,
    stringsAsFactors = FALSE
  )
  result <- compute_ipw_weights(df_stop, pred_prob_col = "p_pred")

  # During grace period (month2 <= grace_months = 11): weight stays at 1.0
  expect_true(all(result$w[result$month2 <= 11L] == 1.0))
  # After grace period: weight grows (denominator = 1 - 0.3 = 0.7 < 1)
  expect_true(all(result$w[result$month2 > 11L] > 1.0))
})

test_that("compute_ipw_weights CONTINUE arm updates in compliance window", {
  # Three rows: tslm_lag outside window, in window (not screened), outside again
  df_cont <- data.frame(
    id = rep(1L, 3L),
    arm = "CONTINUE",
    month2 = 0L:2L,
    monthBC = NA_integer_,
    scrmammo = c(0L, 0L, 0L),
    tslm_lag = c(5L, 11L, 5L),
    p_pred = 0.3,
    stringsAsFactors = FALSE
  )
  result <- compute_ipw_weights(df_cont, pred_prob_col = "p_pred")

  # month 0: tslm_lag = 5, outside compliance window -> weight stays at 1.0
  expect_equal(result$w[1L], 1.0)

  # month 1: tslm_lag = 11, scrmammo = 0
  # prob of screening at month 11 under discrete uniform over {11,12,13}: 1/3
  # prob of not screening: 2/3; model prob of not screening: 0.7
  expect_equal(result$w[2L], (2.0 / 3.0) / 0.7, tolerance = 1e-7)

  # month 2: tslm_lag = 5, outside window -> weight unchanged
  expect_equal(result$w[3L], result$w[2L])
})

test_that("compute_ipw_weights truncates wp99 at per-arm 99th percentile", {
  cloned <- clone_censor(cohort, screening_mammograms, diagnostic_mammograms)
  long_data <- expand_to_long(cloned)
  long_data$p_scrmammo <- 0.5
  long_data$monthBC <- NA_integer_
  long_data$scrmammo <- 0L
  long_data$tslm_lag <- 15L
  result <- compute_ipw_weights(long_data, pred_prob_col = "p_scrmammo")

  # wp99 must never exceed w for any row
  expect_true(all(result$wp99 <= result$w + 1e-10))

  # Truncation threshold is computed separately per arm
  stop_rows <- result$arm == "STOPBASE"
  cont_rows <- result$arm == "CONTINUE"
  p99_stop <- stats::quantile(result$w[stop_rows], 0.99, na.rm = TRUE)
  p99_cont <- stats::quantile(result$w[cont_rows], 0.99, na.rm = TRUE)
  expect_true(all(result$wp99[stop_rows] <= p99_stop + 1e-10))
  expect_true(all(result$wp99[cont_rows] <= p99_cont + 1e-10))
})
