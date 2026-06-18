# Greedy keep mask: retain an evaluation only if it falls more than
# window_months after the previously kept one. `months` must be sorted
# ascending.
thin_within_window <- function(months, window_months) {
  keep <- logical(length(months))
  last_kept_month <- -Inf
  for (j in seq_along(months)) {
    if (months[j] > last_kept_month + window_months) {
      keep[j] <- TRUE
      last_kept_month <- months[j]
    }
  }
  keep
}
