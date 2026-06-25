test_that("simulate_screening_cohort reproduces the committed example data", {
  sim <- simulate_screening_cohort(100L, 108L, seed = 2020L)

  expect_identical(sim$cohort, cohort)
  expect_identical(sim$screening_mammograms, screening_mammograms)
  expect_identical(sim$diagnostic_mammograms, diagnostic_mammograms)
})

test_that("simulate_screening_cohort returns three linked tables", {
  sim <- simulate_screening_cohort(n = 50L, seed = 1L)

  expect_named(
    sim, c("cohort", "screening_mammograms", "diagnostic_mammograms")
  )
  expect_identical(nrow(sim$cohort), 50L)
  expect_true(all(sim$screening_mammograms$id %in% sim$cohort$id))
  expect_true(all(sim$diagnostic_mammograms$id %in% sim$cohort$id))
})

test_that("a supplied seed makes the result reproducible", {
  expect_identical(
    simulate_screening_cohort(30L, seed = 7L),
    simulate_screening_cohort(30L, seed = 7L)
  )
})

test_that("the seed argument does not perturb the caller's RNG stream", {
  set.seed(42L)
  before <- stats::runif(1L)

  set.seed(42L)
  invisible(simulate_screening_cohort(40L, seed = 99L))
  after <- stats::runif(1L)

  expect_identical(before, after)
})

test_that("simulate_screening_cohort validates its arguments", {
  expect_error(simulate_screening_cohort(0L), "positive integer")
  expect_error(
    simulate_screening_cohort(10L, max_month = 0L), "positive integer"
  )
})

test_that("the simulated cohort drives the full pipeline end to end", {
  sim <- simulate_screening_cohort(n = 300L, seed = 3L)

  cloned <- clone_censor(
    sim$cohort, sim$screening_mammograms, sim$diagnostic_mammograms
  )
  long <- expand_to_long(cloned)
  long <- augment_long_covariates(
    long, sim$screening_mammograms, sim$diagnostic_mammograms
  )
  fit <- suppressWarnings(fit_screening_propensity(long))
  weighted <- compute_ipw_weights(fit$data, pred_prob_col = "p_scrmammo")

  expect_true(all(c("w", "wp99") %in% names(weighted)))
  hr <- suppressWarnings(
    fit_outcome_hr(weighted, weight_col = "wp99", outcome_col = "dead_t1")
  )
  expect_true(is.finite(hr$or))
})
