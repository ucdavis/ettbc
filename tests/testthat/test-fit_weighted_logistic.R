test_that("fit_weighted_logistic matches a direct weighted glm call", {
  df <- data.frame(
    y = c(0L, 1L, 0L, 1L, 1L, 0L),
    x = c(1, 2, 3, 4, 5, 6),
    w = c(1, 1, 2, 2, 1, 3)
  )

  got <- fit_weighted_logistic(df, y ~ x, weight_col = "w")
  want <- suppressWarnings(stats::glm(
    y ~ x, data = df, family = stats::binomial(link = "logit"), weights = df$w
  ))
  expect_equal(unname(coef(got)), unname(coef(want)))
  expect_s3_class(got, "glm")
})

test_that("an unweighted fit differs from the weighted one", {
  df <- data.frame(
    y = c(0L, 1L, 0L, 1L, 1L, 0L),
    x = c(1, 2, 3, 4, 5, 6),
    w = c(1, 1, 5, 5, 1, 5)
  )
  weighted <- fit_weighted_logistic(df, y ~ x, weight_col = "w")
  unweighted <- fit_weighted_logistic(df, y ~ x)
  expect_false(isTRUE(all.equal(coef(weighted), coef(unweighted))))
})

test_that("non-integer weights do not warn about non-integer #successes", {
  df <- data.frame(
    y = c(0L, 1L, 0L, 1L, 1L, 0L),
    x = c(1, 2, 3, 4, 5, 6),
    w = c(0.5, 1.5, 2.2, 0.8, 1.1, 3.3)
  )
  expect_no_warning(fit_weighted_logistic(df, y ~ x, weight_col = "w"))
})

test_that("other glm warnings still surface", {
  # Perfect separation makes glm warn that fitted probabilities hit 0 or 1;
  # the targeted muffle must not swallow it.
  df <- data.frame(
    y = c(0L, 0L, 0L, 1L, 1L, 1L),
    x = c(1, 2, 3, 4, 5, 6)
  )
  expect_warning(
    fit_weighted_logistic(df, y ~ x),
    "fitted probabilities numerically 0 or 1"
  )
})

test_that("fit_weighted_logistic validates the weight column", {
  df <- data.frame(y = c(0L, 1L), x = c(1, 2), w = c("a", "b"))
  expect_error(
    fit_weighted_logistic(df, y ~ x, weight_col = "missing"),
    "not found"
  )
  expect_error(
    fit_weighted_logistic(df, y ~ x, weight_col = "w"),
    "must be numeric"
  )
})
