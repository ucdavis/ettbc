make_stratified <- function() {
  mk <- function(arm, stratum, n, events) {
    data.frame(
      arm = arm, stratum = stratum,
      y = c(rep(1L, events), rep(0L, n - events))
    )
  }
  rbind(
    mk("CONTINUE", "A", 10, 5), mk("CONTINUE", "B", 10, 2),
    mk("STOPBASE", "A", 10, 3), mk("STOPBASE", "B", 10, 8)
  )
}

test_that("direct standardization matches the hand-computed rates", {
  # Pooled reference weights are 0.5/0.5 across strata A and B.
  # CONTINUE: 0.5*0.5 + 0.5*0.2 = 0.35; STOPBASE: 0.5*0.3 + 0.5*0.8 = 0.55.
  res <- standardized_rate_difference(
    make_stratified(), "y", strata_cols = "stratum", n_boot = 200, seed = 1
  )
  expect_equal(res$rate_continue, 0.35)
  expect_equal(res$rate_stopbase, 0.55)
  expect_equal(res$diff, -0.20)
  expect_true(res$conf_low <= res$diff && res$diff <= res$conf_high)
})

test_that("mult scales the rates and difference", {
  res <- standardized_rate_difference(
    make_stratified(), "y", strata_cols = "stratum",
    mult = 100, n_boot = 50, seed = 1
  )
  expect_equal(res$diff, -20)
  expect_equal(res$rate_continue, 35)
})

test_that("standardization uses only strata common to both arms", {
  dat <- rbind(
    make_stratified(),
    data.frame(arm = "CONTINUE", stratum = "C", y = rep(1L, 5))
  )
  # Stratum C (CONTINUE-only) is dropped, so the CONTINUE rate is unchanged.
  res <- standardized_rate_difference(
    dat, "y", strata_cols = "stratum", n_boot = 50, seed = 1
  )
  expect_equal(res$rate_continue, 0.35)
})

test_that("the seed argument does not perturb the caller's RNG stream", {
  set.seed(9L)
  before <- stats::runif(1L)
  set.seed(9L)
  invisible(standardized_rate_difference(
    make_stratified(), "y", "stratum", n_boot = 50, seed = 3
  ))
  after <- stats::runif(1L)
  expect_identical(before, after)
})

test_that("standardized_rate_difference validates its inputs", {
  dat <- make_stratified()
  expect_error(
    standardized_rate_difference(dat, "missing", "stratum"),
    "missing column"
  )
  expect_error(
    standardized_rate_difference(dat, "y", character(0)),
    "at least one column"
  )
  expect_error(
    standardized_rate_difference(dat, "y", "stratum", n_boot = 0),
    "positive integer"
  )
  no_overlap <- data.frame(
    arm = c("CONTINUE", "STOPBASE"), stratum = c("A", "B"), y = c(1L, 0L)
  )
  expect_error(
    standardized_rate_difference(no_overlap, "y", "stratum", n_boot = 5),
    "both arms"
  )
  bad_arm <- data.frame(arm = "OTHER", stratum = "A", y = 1L)
  expect_error(
    standardized_rate_difference(bad_arm, "y", "stratum", n_boot = 5),
    "Invalid arm"
  )
})
