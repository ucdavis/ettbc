test_that("extract_screening_mammograms filters by HCPCS code", {
  claims <- data.frame(
    bene_id = c(1L, 2L, 3L, 4L),
    thru_dt = as.Date(c(
      "2001-03-15", "2001-06-20", "2001-03-01", "2002-01-10"
    )),
    hcpcs_cd = c("77057", "99999", "G0202", "77057"),
    stringsAsFactors = FALSE
  )
  ref <- as.Date("2000-01-01")
  result <- extract_screening_mammograms(claims, ref_date = ref)
  expect_s3_class(result, "data.frame")
  expect_named(result, c("id", "month"))
  # Only HCPCS 77057 and G0202 rows should be returned (3 matching rows)
  expect_equal(nrow(result), 3L)
  expect_equal(result$id, c(1L, 3L, 4L))
})

test_that("extract_screening_mammograms computes month correctly", {
  claims <- data.frame(
    bene_id = 1L,
    thru_dt = as.Date("2000-03-15"),  # month 3 relative to Jan 2000
    hcpcs_cd = "77057",
    stringsAsFactors = FALSE
  )
  ref <- as.Date("2000-01-01")
  result <- extract_screening_mammograms(
    claims, ref_date = ref, study_start_month = 1L
  )
  expect_equal(result$month, 3L)
})

test_that("extract_screening_mammograms returns empty for no matches", {
  claims <- data.frame(
    bene_id = 1L,
    thru_dt = as.Date("2001-01-01"),
    hcpcs_cd = "99999",
    stringsAsFactors = FALSE
  )
  result <- extract_screening_mammograms(
    claims, ref_date = as.Date("2000-01-01")
  )
  expect_equal(nrow(result), 0L)
  expect_named(result, c("id", "month"))
})

test_that("extract_diagnostic_mammograms filters diagnostic codes only", {
  claims <- data.frame(
    bene_id = c(1L, 2L, 3L),
    thru_dt = as.Date(c("2001-01-10", "2001-02-10", "2001-03-10")),
    hcpcs_cd = c("77057", "76090", "G0204"),
    stringsAsFactors = FALSE
  )
  ref <- as.Date("2000-01-01")
  result <- extract_diagnostic_mammograms(claims, ref_date = ref)
  expect_equal(nrow(result), 2L)
  expect_equal(result$id, c(2L, 3L))
})

test_that("extract_any_mammograms returns all mammogram types", {
  claims <- data.frame(
    bene_id = c(1L, 2L, 3L, 4L),
    thru_dt = as.Date(c(
      "2001-01-10", "2001-02-10", "2001-03-10", "2001-04-10"
    )),
    hcpcs_cd = c("77057", "76090", "G0204", "XXXXX"),
    stringsAsFactors = FALSE
  )
  ref <- as.Date("2000-01-01")
  result <- extract_any_mammograms(claims, ref_date = ref)
  expect_equal(nrow(result), 3L)
})
