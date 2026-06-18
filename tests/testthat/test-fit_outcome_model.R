test_that("fit_outcome_hr returns expected structure", {
  cloned <- clone_censor(cohort, screening_mammograms, diagnostic_mammograms)
  long_data <- expand_to_long(cloned)
  # Use uniform weights
  long_data$wp99 <- 1.0
  result <- fit_outcome_hr(
    long_data, covariate_cols = NULL, weight_col = "wp99"
  )
  expect_named(result, c("model", "or", "or_ci"))
  expect_s3_class(result$model, "glm")
  expect_true(is.numeric(result$or))
  expect_length(result$or_ci, 2L)
})

test_that("fit_outcome_hr errors on empty data", {
  empty <- data.frame(
    dead_t1 = integer(0), arm = character(0), month2 = integer(0),
    wp99 = numeric(0),
    stringsAsFactors = FALSE
  )
  expect_error(
    fit_outcome_hr(empty, covariate_cols = NULL, weight_col = "wp99")
  )
})
