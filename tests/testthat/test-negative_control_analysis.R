make_nc_cohort <- function(n = 800L, seed = 4L) {
  sim <- simulate_screening_cohort(n = n, seed = seed, negative_control = TRUE)
  cloned <- clone_censor(
    sim$cohort, sim$screening_mammograms, sim$diagnostic_mammograms
  )
  long <- expand_to_long(cloned, nc_died_col = "nc_death")
  long <- augment_long_covariates(
    long, sim$screening_mammograms, sim$diagnostic_mammograms
  )
  fit <- suppressWarnings(fit_screening_propensity(long))
  compute_ipw_weights(fit$data, pred_prob_col = "p_scrmammo")
}

test_that("negative_control adds nc_death and leaves the rest unchanged", {
  default_sim <- simulate_screening_cohort(100L, 108L, seed = 2020L)
  expect_false("nc_death" %in% names(default_sim$cohort))
  expect_identical(default_sim$cohort, cohort)

  nc_sim <- simulate_screening_cohort(
    100L, 108L, seed = 2020L, negative_control = TRUE
  )
  expect_true("nc_death" %in% names(nc_sim$cohort))
  expect_true(all(nc_sim$cohort$nc_death %in% c(0L, 1L)))
  # Negative-control deaths are a subset of the deaths, disjoint from BC deaths
  died <- !is.na(nc_sim$cohort$death_month)
  expect_true(all(nc_sim$cohort$nc_death[!died] == 0L))
  expect_true(all(nc_sim$cohort$nc_death + nc_sim$cohort$bc_death <= 1L))
})

test_that("expand_to_long builds nc_dead_t1 only when nc_died_col is given", {
  cloned <- clone_censor(cohort, screening_mammograms, diagnostic_mammograms)

  long_default <- expand_to_long(cloned)
  expect_false("nc_dead_t1" %in% names(long_default))

  cloned$nc_death <- cloned$bc_died # reuse an existing 0/1 cause indicator
  long_nc <- expand_to_long(cloned, nc_died_col = "nc_death")
  expect_true("nc_dead_t1" %in% names(long_nc))
  # A cause-specific outcome never exceeds the all-cause outcome
  events <- !is.na(long_nc$dead_t1)
  expect_true(all(long_nc$nc_dead_t1[events] <= long_nc$dead_t1[events]))
})

test_that("expand_to_long errors on a missing nc_died_col", {
  cloned <- clone_censor(cohort, screening_mammograms, diagnostic_mammograms)
  expect_error(
    expand_to_long(cloned, nc_died_col = "not_a_column"),
    "not found"
  )
})

test_that("negative_control_analysis returns a null verdict and an OR", {
  weighted <- make_nc_cohort()
  nc <- suppressWarnings(negative_control_analysis(weighted))

  expect_named(nc, c("or", "or_ci", "null_consistent", "model"))
  expect_true(is.finite(nc$or))
  expect_length(nc$or_ci, 2L)
  expect_type(nc$null_consistent, "logical")
  # The verdict is exactly whether the CI covers the null value
  expect_identical(
    nc$null_consistent,
    nc$or_ci[[1L]] <= 1 && 1 <= nc$or_ci[[2L]]
  )
})

test_that("negative_control_analysis errors when the outcome is absent", {
  cloned <- clone_censor(cohort, screening_mammograms, diagnostic_mammograms)
  long <- expand_to_long(cloned)
  long$wp99 <- 1
  expect_error(
    negative_control_analysis(long),
    "not found"
  )
})
