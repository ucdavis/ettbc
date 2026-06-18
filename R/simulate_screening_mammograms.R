# Simulate screening mammogram events for the whole cohort.
#
# Approximately 80% of participants are "adherers"; the remaining 20% are
# "non-adherers". Returns one row per screening mammogram event. Used by the
# example-data generation script under data-raw.
simulate_screening_mammograms <- function(cohort, max_month) {
  n <- nrow(cohort)
  is_adherer <- stats::runif(n) < 0.80

  scr_rows <- seq_len(n) |>
    lapply(
      screening_row_for_participant,
      cohort = cohort, is_adherer = is_adherer, max_month = max_month
    ) |>
    Filter(f = Negate(is.null))

  scr <- do.call(rbind, scr_rows)
  rownames(scr) <- NULL
  scr
}
