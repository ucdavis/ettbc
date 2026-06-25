test_that("gagne_weights returns the 20 published condition weights", {
  w <- gagne_weights()

  expect_length(w, 20L)
  expect_type(w, "integer")
  expect_false(anyNA(names(w)))

  # Spot-check the distinctive weights, including the two negatives.
  expect_identical(w[["metastatic_cancer"]], 5L)
  expect_identical(w[["congestive_heart_failure"]], 2L)
  expect_identical(w[["hiv_aids"]], -1L)
  expect_identical(w[["hypertension"]], -1L)

  # Weight distribution: one 5, four 2s, thirteen 1s, two -1s.
  expect_identical(unname(table(w)["5"]), 1L)
  expect_identical(unname(table(w)["2"]), 4L)
  expect_identical(unname(table(w)["1"]), 13L)
  expect_identical(unname(table(w)["-1"]), 2L)
})

test_that("comorbidity_score defaults to the Gagne weights", {
  conditions <- as.list(rep(0L, 20L))
  names(conditions) <- names(gagne_weights())
  person <- as.data.frame(conditions)
  person$metastatic_cancer <- 1L
  person$hypertension <- 1L

  # 5 (metastatic) + (-1) (hypertension) = 4
  expect_equal(comorbidity_score(person), 4)
})
