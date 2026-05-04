test_that("expand_to_long correct row count for censored participant", {
  dat <- data.frame(
    id = 1L, arm = "STOPBASE", start_month = 10L, end_month = 20L,
    died = 0L, bc_died = 0L, bc_month = NA_integer_,
    stringsAsFactors = FALSE
  )
  result <- expand_to_long(dat)
  # 11 rows: months 10 through 20 inclusive
  expect_equal(nrow(result), 11L)
})

test_that("expand_to_long correct row count for deceased participant", {
  dat <- data.frame(
    id = 1L, arm = "STOPBASE", start_month = 10L, end_month = 20L,
    died = 1L, bc_died = 0L, bc_month = NA_integer_,
    stringsAsFactors = FALSE
  )
  result <- expand_to_long(dat)
  # 10 rows: months 10 through 19 (month 20 dropped for dead)
  expect_equal(nrow(result), 10L)
})

test_that("expand_to_long snapshot - deceased participant", {
  dat <- data.frame(
    id = 1L, arm = "STOPBASE", start_month = 10L, end_month = 20L,
    died = 1L, bc_died = 0L, bc_month = NA_integer_,
    stringsAsFactors = FALSE
  )
  result <- expand_to_long(dat)
  snapr::expect_snapshot_data(result, "expand_deceased")
})

test_that("expand_to_long snapshot - censored participant", {
  dat <- data.frame(
    id = 1L, arm = "STOPBASE", start_month = 10L, end_month = 20L,
    died = 0L, bc_died = 0L, bc_month = NA_integer_,
    stringsAsFactors = FALSE
  )
  result <- expand_to_long(dat)
  snapr::expect_snapshot_data(result, "expand_censored")
})

test_that("expand_to_long snapshot - breast cancer diagnosis", {
  dat <- data.frame(
    id = 1L, arm = "STOPBASE", start_month = 10L, end_month = 20L,
    died = 0L, bc_died = 0L, bc_month = 15L,
    stringsAsFactors = FALSE
  )
  result <- expand_to_long(dat)
  snapr::expect_snapshot_data(result, "expand_bc_diagnosis")
})

test_that("expand_to_long snapshot - bc death", {
  dat <- data.frame(
    id = 1L, arm = "STOPBASE", start_month = 10L, end_month = 20L,
    died = 1L, bc_died = 1L, bc_month = NA_integer_,
    stringsAsFactors = FALSE
  )
  result <- expand_to_long(dat)
  snapr::expect_snapshot_data(result, "expand_bc_death")
})

test_that("expand_to_long snapshot - single-month follow-up", {
  dat <- data.frame(
    id = 1L, arm = "STOPBASE", start_month = 10L, end_month = 10L,
    died = 1L, bc_died = 0L, bc_month = NA_integer_,
    stringsAsFactors = FALSE
  )
  result <- expand_to_long(dat)
  snapr::expect_snapshot_data(result, "expand_single_month")
})

test_that("expand_to_long month2 is 0-indexed from start_month", {
  dat <- data.frame(
    id = 1L, arm = "CONTINUE", start_month = 15L, end_month = 20L,
    died = 0L, bc_died = 0L, bc_month = NA_integer_,
    stringsAsFactors = FALSE
  )
  result <- expand_to_long(dat)
  expect_equal(min(result$month2), 0L)
  expect_equal(max(result$month2), 20L - 15L)
})
