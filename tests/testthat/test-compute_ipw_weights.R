test_that("compute_ipw_weights returns w and wp99 columns", {
  cloned <- clone_censor(cohort, screening_mammograms, diagnostic_mammograms)
  long_data <- expand_to_long(cloned)
  # Add fake predicted prob column and required IPW columns
  long_data$p_scrmammo <- 0.3
  long_data$monthBC <- NA_integer_
  long_data$scrmammo <- 0L
  long_data$anymammo <- 0L
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
    anymammo = integer(0), tslm_lag = integer(0),
    p_scrmammo = numeric(0),
    stringsAsFactors = FALSE
  )
  result <- compute_ipw_weights(empty, pred_prob_col = "p_scrmammo")
  expect_true("w" %in% names(result))
  expect_true("wp99" %in% names(result))
  expect_equal(nrow(result), 0L)
})
