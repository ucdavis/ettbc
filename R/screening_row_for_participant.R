# Build the screening-mammogram rows for one participant (by row index `i`
# into `cohort`), or NULL if they have no in-window mammograms. Used by
# simulate_screening_mammograms().
screening_row_for_participant <- function(i, cohort, is_adherer, max_month) {
  mammo_months <- simulate_participant_screening(
    sm = cohort$start_month[i],
    em = cohort$end_month[i],
    adherer = is_adherer[i],
    max_month = max_month
  )

  if (length(mammo_months) == 0L) return(NULL)
  data.frame(id = cohort$id[i], month = mammo_months, stringsAsFactors = FALSE)
}
