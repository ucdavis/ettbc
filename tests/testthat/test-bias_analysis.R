test_that("deterministic_bias_analysis matches the closed-form bias", {
  res <- deterministic_bias_analysis(
    rd = -0.012,
    prev_continue = c(0.01, 0.05, 0.10),
    prev_stopbase = 0.05,
    confounder_effect = 0.01
  )

  expect_identical(nrow(res), 3L)
  expect_named(
    res,
    c("rd", "prev_continue", "prev_stopbase", "confounder_effect",
      "bias", "adjusted_rd")
  )
  expect_equal(
    res$bias,
    (res$prev_continue - res$prev_stopbase) * res$confounder_effect
  )
  expect_equal(res$adjusted_rd, res$rd - res$bias)
})

test_that("equal prevalences imply no bias", {
  res <- deterministic_bias_analysis(
    rd = 0.02, prev_continue = 0.05, prev_stopbase = 0.05,
    confounder_effect = 0.3
  )
  expect_identical(res$bias, 0)
  expect_identical(res$adjusted_rd, 0.02)
})

test_that("deterministic_bias_analysis validates prevalences", {
  expect_error(
    deterministic_bias_analysis(0, prev_continue = 1.5, 0.05, 0.01),
    "between 0 and 1"
  )
})

test_that("probabilistic_bias_analysis is reproducible and restores the RNG", {
  args <- list(
    rd = -0.012, prev_continue = c(0.01, 0.10), prev_stopbase = 0.05,
    confounder_effect = c(0.005, 0.02), rd_se = 0.004, n_sim = 2000, seed = 7
  )

  set.seed(42L)
  before <- stats::runif(1L)
  set.seed(42L)
  first <- do.call(probabilistic_bias_analysis, args)
  after <- stats::runif(1L)
  expect_identical(before, after) # RNG stream untouched

  second <- do.call(probabilistic_bias_analysis, args)
  expect_identical(first$draws, second$draws)

  expect_named(
    first,
    c("estimate", "conf_low", "conf_high", "draws", "n_sim", "conf_level")
  )
  expect_length(first$draws, 2000L)
  expect_true(first$conf_low <= first$estimate)
  expect_true(first$estimate <= first$conf_high)
})

test_that("fixed parameters reduce to the deterministic adjustment", {
  psa <- probabilistic_bias_analysis(
    rd = -0.012, prev_continue = 0.01, prev_stopbase = 0.05,
    confounder_effect = 0.01, rd_se = 0, n_sim = 10, seed = 1
  )
  det <- deterministic_bias_analysis(-0.012, 0.01, 0.05, 0.01)
  expect_equal(unique(psa$draws), det$adjusted_rd)
})

test_that("probabilistic_bias_analysis validates its inputs", {
  expect_error(
    probabilistic_bias_analysis(0, c(0.1, 0.2, 0.3), 0.05, 0.01),
    "single value or a"
  )
  expect_error(
    probabilistic_bias_analysis(0, 0.05, 0.05, 0.01, n_sim = 0),
    "positive integer"
  )
  expect_error(
    probabilistic_bias_analysis(0, 0.05, 0.05, 0.01, conf_level = 1),
    "in \\(0, 1\\)"
  )
})
