# Simulate diagnostic mammogram events.
#
# About 20% of participants receive one diagnostic mammogram during follow-up,
# at least 6 months after trial entry. Returns one row per diagnostic event.
# Used by the example-data generation script under data-raw.
simulate_diagnostic_mammograms <- function(cohort, max_month) {
  n <- nrow(cohort)
  dx_prop <- 0.20
  dx_ids <- sample(seq_len(n), size = round(n * dx_prop))

  dx_rows <- dx_ids |>
    lapply(
      diagnostic_row_for_participant,
      cohort = cohort, max_month = max_month
    ) |>
    Filter(f = Negate(is.null))

  dx <- do.call(rbind, dx_rows)
  rownames(dx) <- NULL
  dx
}
