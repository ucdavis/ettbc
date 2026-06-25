test_that("comorbidity_score computes the weighted sum per person", {
  people <- data.frame(
    chf = c(0L, 1L, 0L, 1L),
    dementia = c(0L, 0L, 1L, 1L),
    metastatic_cancer = c(0L, 0L, 1L, 0L)
  )
  w <- c(chf = 2, dementia = 2, metastatic_cancer = 5)

  expect_equal(comorbidity_score(people, w), c(0, 2, 7, 4))
})

test_that("only the columns named in weights contribute", {
  people <- data.frame(
    chf = c(1L, 0L),
    other = c(1L, 1L) # not in weights, must be ignored
  )
  expect_equal(comorbidity_score(people, c(chf = 3)), c(3, 0))
})

test_that("logical indicators are accepted", {
  people <- data.frame(a = c(TRUE, FALSE), b = c(FALSE, TRUE))
  expect_equal(comorbidity_score(people, c(a = 1, b = 2)), c(1, 2))
})

test_that("comorbidity_score validates weights and columns", {
  people <- data.frame(a = 1L, b = 0L)
  expect_error(comorbidity_score(people, c(1, 2)), "fully named")
  expect_error(comorbidity_score(people, c(a = 1, missing = 2)), "missing")
  expect_error(comorbidity_score(people, list(a = 1)), "named numeric")
})

test_that("non-binary indicators are rejected", {
  people <- data.frame(a = c(2L, 0L))
  expect_error(comorbidity_score(people, c(a = 1)), "0/1")
})

test_that("na_rm controls handling of missing indicators", {
  people <- data.frame(a = c(1L, NA_integer_), b = c(1L, 1L))
  w <- c(a = 2, b = 3)
  expect_error(comorbidity_score(people, w), "NA")
  expect_equal(comorbidity_score(people, w, na_rm = TRUE), c(5, 3))
})
