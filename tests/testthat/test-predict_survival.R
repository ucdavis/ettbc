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
