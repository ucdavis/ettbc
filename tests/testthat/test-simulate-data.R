# The data-generation helpers live in R/ but are only run by
# data-raw/generate_example_data.R. These tests exercise them so they reproduce
# the committed example datasets exactly (which also covers their lines).
#
# The three generators share a single RNG stream, matching the order in
# data-raw/generate_example_data.R, so they must run together after one
# set.seed() to reproduce the shipped data. The committed `cohort`,
# `screening_mammograms`, and `diagnostic_mammograms` datasets are the golden
# reference, so we compare against them directly rather than snapshotting.

test_that("generators reproduce the committed example datasets", {
  set.seed(2020)
  gen_cohort <- simulate_cohort(100L, 108L)
  gen_scr <- simulate_screening_mammograms(gen_cohort, 108L)
  gen_dx <- simulate_diagnostic_mammograms(gen_cohort, 108L)

  expect_identical(gen_cohort, cohort)
  expect_identical(gen_scr, screening_mammograms)
  expect_identical(gen_dx, diagnostic_mammograms)
})

test_that("simulate_participant_screening does not error when max_month caps the range below n_mammo", {
  # pmin(em, max_month) = sm + 3 gives a length-1 range; before the fix,
  # sample(..., size = 2) on a length-1 vector caused an error.
  sm <- 15L
  em <- 30L
  max_month <- sm + 3L
  set.seed(1L)
  expect_no_error(
    replicate(
      100L,
      simulate_participant_screening(sm, em, adherer = FALSE, max_month = max_month)
    )
  )
})

test_that("simulate_cohort returns the documented structure", {
  set.seed(1)
  ch <- simulate_cohort(40L, 108L)

  expect_s3_class(ch, "data.frame")
  expect_identical(nrow(ch), 40L)
  expect_named(
    ch,
    c(
      "id", "age", "start_month", "end_month", "death_month",
      "bc_death", "bc_month"
    )
  )
  expect_true(all(ch$start_month >= 1L & ch$start_month <= 60L))
  expect_true(all(ch$end_month <= 108L))
})
