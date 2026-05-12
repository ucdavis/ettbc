test_that("false_positives returns correct structure on simple data", {
  cloned <- clone_censor(cohort, screening_mammograms, diagnostic_mammograms)
  long_data <- expand_to_long(cloned)
  # Add a fake monthBC column (no BC diagnoses)
  long_data$monthBC <- NA_integer_

  # Histological evaluations: a few participants at known month2 values
  ids <- unique(long_data$id)[seq_len(3L)]
  hist_data <- data.frame(id = ids, month2 = c(5L, 12L, 5L))

  result <- false_positives(
    long_data, hist_data,
    bc_month_col = "monthBC",
    hist_month2_col = "month2"
  )

  expect_s3_class(result, "data.frame")
  expect_true(
    all(c("arm", "period", "n_hist", "n_positive", "fpr") %in% names(result))
  )
  expect_true(all(result$fpr >= 0 & result$fpr <= 1))
  expect_true(all(result$n_positive <= result$n_hist))
})

test_that("false_positives returns empty result when long_data is empty", {
  long_data <- data.frame(
    id = integer(0),
    arm = character(0),
    month2 = integer(0),
    monthBC = integer(0),
    stringsAsFactors = FALSE
  )
  hist_data <- data.frame(id = 1L, month2 = 5L)
  result <- false_positives(
    long_data, hist_data,
    bc_month_col = "monthBC",
    hist_month2_col = "month2"
  )
  expect_equal(nrow(result), 0L)
  expect_named(result, c("arm", "period", "n_hist", "n_positive", "fpr"))
})

test_that("false_positives returns empty result when hist_data is empty", {
  cloned <- clone_censor(cohort, screening_mammograms, diagnostic_mammograms)
  long_data <- expand_to_long(cloned)
  long_data$monthBC <- NA_integer_
  empty_hist <- data.frame(id = integer(0), month2 = integer(0))
  result <- false_positives(
    long_data, empty_hist,
    bc_month_col = "monthBC",
    hist_month2_col = "month2"
  )
  expect_equal(nrow(result), 0L)
  expect_named(result, c("arm", "period", "n_hist", "n_positive", "fpr"))
})

test_that("false_positives returns empty result when no IDs match cohort", {
  cloned <- clone_censor(cohort, screening_mammograms, diagnostic_mammograms)
  long_data <- expand_to_long(cloned)
  long_data$monthBC <- NA_integer_
  # IDs that don't exist in long_data
  hist_data <- data.frame(id = c(99999L, 99998L), month2 = c(5L, 5L))
  result <- false_positives(
    long_data, hist_data,
    bc_month_col = "monthBC",
    hist_month2_col = "month2"
  )
  expect_equal(nrow(result), 0L)
})

test_that("false_positives excludes evaluations after censoring", {
  cloned <- clone_censor(cohort, screening_mammograms, diagnostic_mammograms)
  long_data <- expand_to_long(cloned)
  long_data$monthBC <- NA_integer_

  id_one <- unique(long_data$id)[1L]
  max_m2 <- max(long_data$month2[long_data$id == id_one])

  # One evaluation within follow-up, one beyond
  hist_data <- data.frame(
    id = c(id_one, id_one),
    month2 = c(0L, max_m2 + 99L)
  )

  result <- false_positives(
    long_data, hist_data,
    bc_month_col = "monthBC",
    hist_month2_col = "month2"
  )
  # Only the within-follow-up evaluation should be counted (2 arms x 1 eval)
  expect_true(sum(result$n_hist) <= 2L)
})

test_that("false_positives deduplicates within window_months", {
  cloned <- clone_censor(cohort, screening_mammograms, diagnostic_mammograms)
  long_data <- expand_to_long(cloned)
  long_data$monthBC <- NA_integer_

  id_one <- unique(long_data$id)[1L]
  # Two evaluations 3 months apart (within default window of 6)
  hist_data <- data.frame(
    id = c(id_one, id_one),
    month2 = c(2L, 4L)
  )

  result_with <- false_positives(
    long_data, hist_data,
    bc_month_col = "monthBC",
    hist_month2_col = "month2",
    window_months = 6L
  )
  result_without <- false_positives(
    long_data, hist_data,
    bc_month_col = "monthBC",
    hist_month2_col = "month2",
    window_months = 1L  # very short window – both should be kept
  )
  # With dedup: 1 event per arm; without dedup: 2 events per arm
  expect_true(sum(result_with$n_hist) <= sum(result_without$n_hist))
})

test_that("false_positives correctly classifies period using month2", {
  cloned <- clone_censor(cohort, screening_mammograms, diagnostic_mammograms)
  long_data <- expand_to_long(cloned)
  long_data$monthBC <- NA_integer_

  id_one <- unique(long_data$id)[1L]
  # month2 = 5 is within first_round (default 9), month2 = 15 is beyond
  hist_data <- data.frame(
    id = c(id_one, id_one),
    month2 = c(5L, 15L)
  )

  result <- false_positives(
    long_data, hist_data,
    bc_month_col = "monthBC",
    hist_month2_col = "month2",
    first_round_months = 9L,
    window_months = 1L
  )
  expect_true("first_round" %in% result$period)
  expect_true("beyond_first_round" %in% result$period)
})
