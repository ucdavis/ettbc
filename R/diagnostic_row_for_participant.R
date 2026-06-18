# Build the diagnostic-mammogram row for one participant (by row index `i`
# into `cohort`), or NULL if their follow-up is too short. Used by
# simulate_diagnostic_mammograms().
diagnostic_row_for_participant <- function(i, cohort, max_month) {
  sm <- cohort$start_month[i]
  em <- cohort$end_month[i]
  if (em <= sm + 6L) return(NULL)

  dx_month <- sample(seq.int(sm + 6L, pmin(em, max_month)), 1L)
  data.frame(id = cohort$id[i], month = dx_month, stringsAsFactors = FALSE)
}
