test_that("predict_survival_unadjusted returns correct structure", {
  cloned <- clone_censor(cohort, screening_mammograms, diagnostic_mammograms)
  long_data <- expand_to_long(cloned)
  result <- predict_survival_unadjusted(long_data)
  expect_s3_class(result, "data.frame")
  expect_named(result, c("month", "s_continue", "s_stopbase"))
  expect_equal(nrow(result), 96L) # months 0-95
  expect_true(all(result$s_continue >= 0 & result$s_continue <= 1))
  expect_true(all(result$s_stopbase >= 0 & result$s_stopbase <= 1))
  # Survival should be non-increasing
  expect_true(all(diff(result$s_continue) <= 0))
  expect_true(all(diff(result$s_stopbase) <= 0))
})

test_that("predict_survival_unadjusted handles empty data", {
  empty <- data.frame(
    dead_t1 = integer(0), arm = character(0), month2 = integer(0)
  )
  result <- predict_survival_unadjusted(empty)
  expect_equal(nrow(result), 0L)
})

test_that("predict_survival_baseline_adjusted returns correct structure", {
  cloned <- clone_censor(cohort, screening_mammograms, diagnostic_mammograms)
  long_data <- expand_to_long(cloned)
  result <- predict_survival_baseline_adjusted(long_data)
  expect_s3_class(result, "data.frame")
  expect_named(result, c("month", "s_continue", "s_stopbase"))
  expect_equal(nrow(result), 96L)
  expect_true(all(result$s_continue >= 0 & result$s_continue <= 1))
  expect_true(all(result$s_stopbase >= 0 & result$s_stopbase <= 1))
})

test_that("predict_survival_baseline_adjusted handles empty data", {
  empty <- data.frame(
    dead_t1 = integer(0), arm = character(0), month2 = integer(0)
  )
  result <- predict_survival_baseline_adjusted(empty)
  expect_equal(nrow(result), 0L)
})

test_that("predict_survival_ipw uses weights and returns correct structure", {
  cloned <- clone_censor(cohort, screening_mammograms, diagnostic_mammograms)
  long_data <- expand_to_long(cloned)
  long_data$wp99 <- 1.0
  result <- predict_survival_ipw(long_data, weight_col = "wp99")
  expect_s3_class(result, "data.frame")
  expect_named(result, c("month", "s_continue", "s_stopbase"))
  expect_equal(nrow(result), 96L)
  expect_true(all(result$s_continue >= 0 & result$s_continue <= 1))
  expect_true(all(result$s_stopbase >= 0 & result$s_stopbase <= 1))
})

test_that("predict_survival_ipw handles empty data", {
  empty <- data.frame(
    dead_t1 = integer(0), arm = character(0), month2 = integer(0),
    wp99 = numeric(0)
  )
  result <- predict_survival_ipw(empty, weight_col = "wp99")
  expect_equal(nrow(result), 0L)
})

test_that("predict_survival_ipw with NULL weight_col matches unadjusted", {
  cloned <- clone_censor(cohort, screening_mammograms, diagnostic_mammograms)
  long_data <- expand_to_long(cloned)
  r_unw <- predict_survival_unadjusted(long_data)
  r_ipw <- predict_survival_ipw(long_data, weight_col = NULL)
  expect_equal(r_unw$s_continue, r_ipw$s_continue, tolerance = 1e-6)
  expect_equal(r_unw$s_stopbase, r_ipw$s_stopbase, tolerance = 1e-6)
})
