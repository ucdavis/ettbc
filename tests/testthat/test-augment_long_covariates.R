test_that("augment_long_covariates adds the expected columns", {
  cloned <- clone_censor(cohort, screening_mammograms, diagnostic_mammograms)
  long_data <- expand_to_long(cloned)
  out <- augment_long_covariates(
    long_data, screening_mammograms, diagnostic_mammograms
  )
  expect_true(all(
    c("scrmammo", "dxmammo", "anymammo", "tslm", "tslm_lag", "monthBC") %in%
      names(out)
  ))
  expect_equal(nrow(out), nrow(long_data))
})

test_that("entry month forces a screening mammogram and resets the clock", {
  out <- run_augment_one(
    months = 0:5,
    scr_months = integer(0),
    dx_months = integer(0)
  )
  # month2 == 0 forces scrmammo = 1 and tslm = 0, with tslm_lag undefined
  expect_equal(out$scrmammo[1], 1L)
  expect_equal(out$tslm[1], 0L)
  expect_true(is.na(out$tslm_lag[1]))
  # With no further mammograms, tslm increments and tslm_lag follows by one
  expect_equal(out$tslm, c(0L, 1L, 2L, 3L, 4L, 5L))
  expect_equal(out$tslm_lag, c(NA, 0L, 1L, 2L, 3L, 4L))
})

test_that("a screening event resets the time-since-last-mammogram clock", {
  # Entry at calendar month 10; a screening mammogram at calendar month 22
  # (tslm_lag 11 by then, so it is NOT reclassified as diagnostic).
  out <- run_augment_one(
    months = 10:24,
    scr_months = 22L,
    dx_months = integer(0),
    start = 10L
  )
  scr_row <- which(out$month == 22L)
  expect_equal(out$scrmammo[scr_row], 1L)
  expect_equal(out$tslm[scr_row], 0L)
  # Clock climbs back up afterwards
  expect_equal(out$tslm[scr_row + 1L], 1L)
})

test_that("a mammogram within dx_reclass_months is reclassified diagnostic", {
  # Screening event 5 months after entry: tslm_lag = 5 (<= 8), so it is
  # reclassified to diagnostic.
  out <- run_augment_one(
    months = 0:10,
    scr_months = 5L,
    dx_months = integer(0)
  )
  row5 <- which(out$month == 5L)
  expect_equal(out$scrmammo[row5], 0L)
  expect_equal(out$dxmammo[row5], 1L)
  # It still counts as a mammogram and resets the clock
  expect_equal(out$anymammo[row5], 1L)
  expect_equal(out$tslm[row5], 0L)
})

test_that("monthBC is the month2 of breast-cancer diagnosis", {
  long_data <- data.frame(
    id = 1L,
    arm = "CONTINUE",
    month = 10:20,
    month2 = 0:10,
    bc_long = c(rep(0L, 6L), 1L, rep(0L, 4L)),
    stringsAsFactors = FALSE
  )
  out <- augment_long_covariates(
    long_data,
    screening_mammograms = empty_events(),
    diagnostic_mammograms = empty_events()
  )
  expect_equal(unique(out$monthBC), 6L)
})

test_that("monthBC is NA when there is no breast-cancer diagnosis", {
  out <- run_augment_one(
    months = 0:5,
    scr_months = integer(0),
    dx_months = integer(0)
  )
  expect_true(all(is.na(out$monthBC)))
})

test_that("augment_long_covariates handles empty input", {
  empty <- data.frame(
    id = integer(0), arm = character(0), month = integer(0),
    month2 = integer(0), bc_long = integer(0),
    stringsAsFactors = FALSE
  )
  out <- augment_long_covariates(empty, empty_events(), empty_events())
  expect_equal(nrow(out), 0L)
  expect_true(all(
    c("scrmammo", "tslm_lag", "monthBC") %in% names(out)
  ))
})

test_that("augment_long_covariates errors on missing columns", {
  bad <- data.frame(id = 1L, arm = "CONTINUE", month = 1L)
  expect_error(
    augment_long_covariates(bad, empty_events(), empty_events()),
    "missing required column"
  )
})

# Test helpers ------------------------------------------------------------

empty_events <- function() {
  data.frame(id = integer(0), month = integer(0), stringsAsFactors = FALSE)
}

# Build a single-participant long frame and augment it.
run_augment_one <- function(months, scr_months, dx_months, start = months[1]) {
  long_data <- data.frame(
    id = 1L,
    arm = "CONTINUE",
    month = months,
    month2 = months - start,
    bc_long = 0L,
    stringsAsFactors = FALSE
  )
  scr <- data.frame(id = rep(1L, length(scr_months)), month = scr_months)
  dx <- data.frame(id = rep(1L, length(dx_months)), month = dx_months)
  augment_long_covariates(long_data, scr, dx)
}
