test_that("compute_rcs_basis returns k - 2 named nonlinear terms", {
  basis <- compute_rcs_basis(0:20, rcs_knots = c(0, 6, 12, 18))
  expect_true(is.matrix(basis))
  expect_identical(ncol(basis), 2L) # 4 knots -> 2 nonlinear terms
  expect_identical(colnames(basis), c("rcs1", "rcs2"))
  expect_identical(nrow(basis), 21L)
})

test_that("every term vanishes at or below the first knot", {
  knots <- c(5, 10, 15)
  basis <- compute_rcs_basis(c(0, 2, 5, 8), rcs_knots = knots)
  # rows for x <= 5 (the first knot) are all zero
  expect_true(all(basis[1:3, ] == 0))
  expect_true(any(basis[4, ] != 0)) # x = 8 > first knot is nonzero
})

test_that("compute_rcs_basis errors with fewer than three knots", {
  expect_error(
    compute_rcs_basis(1:10, rcs_knots = c(2, 8)),
    "at least 3 elements"
  )
})

test_that("the basis matches the Harrell truncated-power formula", {
  knots <- c(0, 6, 12)
  x <- c(3, 9, 15)
  cube_pos <- function(u) pmax(u, 0)^3
  t1 <- knots[1]
  t2 <- knots[2]
  t3 <- knots[3]
  numerator <- cube_pos(x - t1) -
    cube_pos(x - t2) * (t3 - t1) / (t3 - t2) +
    cube_pos(x - t3) * (t2 - t1) / (t3 - t2)
  expected <- numerator / (t3 - t1)^2

  basis <- compute_rcs_basis(x, rcs_knots = knots)
  expect_equal(as.numeric(basis[, 1]), expected)
})
