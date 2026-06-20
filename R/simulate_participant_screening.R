# Simulate one participant's screening mammogram months.
#
# Adherers receive roughly annual mammograms (+/-2 month jitter); non-adherers
# receive zero, one, or two post-entry mammograms. Every participant has a
# pre-entry mammogram (10-14 months before entry) to seed the CONTINUE arm
# compliance window.
simulate_participant_screening <- function(sm, em, adherer, max_month) {
  # Pre-study screening mammogram to initialise the compliance window
  pre <- sm - sample(10L:14L, 1L)
  mammo_months <- pre[pre >= 1L]

  if (adherer) {
    # Annual screeners: approximately every 12 months (±2 month jitter)
    t <- sm + sample(10L:14L, 1L) # first post-entry mammo
    while (t <= em && t <= max_month) {
      mammo_months <- c(mammo_months, t)
      t <- t + 12L + sample(-2L:2L, 1L)
    }
  } else {
    # Non-adherers: zero, one, or two post-entry mammograms
    n_mammo <- sample(0L:2L, 1L)
    if (n_mammo > 0L && em > sm + 3L) {
      month_pool <- seq.int(sm + 3L, pmin(em, max_month))
      extra <- sort(sample(month_pool, size = min(n_mammo, length(month_pool))))
      mammo_months <- c(mammo_months, extra)
    }
  }

  mammo_months[mammo_months >= 1L & mammo_months <= max_month] |>
    unique()
}
