# Validate that demographics, enrollment, and mammograms carry every column
# apply_eligibility_criteria() needs, before any filtering logic runs.
#' @noRd
check_eligibility_inputs <- function(
    demographics, enrollment, mammograms,
    id_col, agein_month_col, death_month_col, orec_col,
    enrollment_month_col, buyin_col, hmo_col, mammo_month_col) {
  require_columns(
    demographics, c(id_col, agein_month_col, death_month_col, orec_col),
    "demographics"
  )
  require_columns(
    enrollment, c(id_col, enrollment_month_col, buyin_col, hmo_col),
    "enrollment"
  )
  require_columns(mammograms, c(id_col, mammo_month_col), "mammograms")
}
