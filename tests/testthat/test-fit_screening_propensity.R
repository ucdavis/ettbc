# A small augmented long frame with enough variation for a glm fit, built
# at file scope (matching the dataset usage in the other test files).
cloned <- clone_censor(cohort, screening_mammograms, diagnostic_mammograms)
prop_data <- augment_long_covariates(
  expand_to_long(cloned), screening_mammograms, diagnostic_mammograms
)

test_that("fit_screening_propensity returns a model and predictions", {
  fit <- fit_screening_propensity(prop_data)
  expect_s3_class(fit$model, "glm")
  expect_true("p_scrmammo" %in% names(fit$data))
  expect_equal(nrow(fit$data), nrow(prop_data))
})

test_that("predictions are probabilities within the decision window only", {
  fit <- fit_screening_propensity(prop_data)
  p <- fit$data$p_scrmammo
  in_window <- !is.na(prop_data$tslm_lag) & prop_data$tslm_lag >= 11L
  # Every in-window row has a probability in [0, 1]
  expect_true(all(!is.na(p[in_window])))
  expect_true(all(p[in_window] >= 0 & p[in_window] <= 1))
  # Rows outside the window get NA
  expect_true(all(is.na(p[!in_window])))
})

test_that("predictions feed compute_ipw_weights end to end", {
  fit <- fit_screening_propensity(prop_data)
  weighted <- compute_ipw_weights(fit$data, pred_prob_col = "p_scrmammo")
  expect_true(all(c("w", "wp99") %in% names(weighted)))
  expect_true(all(is.finite(weighted$w)))
  expect_true(all(weighted$wp99 >= 0))
})

test_that("min_tslm_lag controls the fitting and prediction window", {
  fit <- fit_screening_propensity(prop_data, min_tslm_lag = 6L)
  p <- fit$data$p_scrmammo
  in_window <- !is.na(prop_data$tslm_lag) & prop_data$tslm_lag >= 6L
  expect_true(all(!is.na(p[in_window])))
  expect_true(all(is.na(p[!in_window])))
})

test_that("fit_screening_propensity errors on missing columns", {
  bad <- data.frame(id = 1L, scrmammo = 0L)
  expect_error(
    fit_screening_propensity(bad),
    "missing required column"
  )
})

test_that("fit_screening_propensity errors when the outcome does not vary", {
  flat <- prop_data
  flat$scrmammo <- 0L
  expect_error(
    fit_screening_propensity(flat),
    "does not vary"
  )
})
