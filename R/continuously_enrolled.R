# Box 2 of c01_eligibility.sas: twelve consecutive fee-for-service, non-HMO
# enrollment months ending at the entry month.
#' @noRd
continuously_enrolled <- function(
    entry, enrollment, id_col, enrollment_month_col, buyin_col, hmo_col,
    eligible_buyin, eligible_hmo, enrollment_window_months) {
  if (nrow(entry) == 0L) {
    return(entry[[id_col]][0])
  }

  eligible_months <- enrollment[
    enrollment[[buyin_col]] %in% eligible_buyin &
      enrollment[[hmo_col]] %in% eligible_hmo,
    ,
    drop = FALSE
  ]
  eligible_keys <- paste(
    eligible_months[[id_col]], eligible_months[[enrollment_month_col]],
    sep = "\x1f"
  )

  window_len <- enrollment_window_months
  covered <- vapply(seq_len(nrow(entry)), function(i) {
    months <- seq(
      entry$start_month[i] - window_len + 1L, entry$start_month[i]
    )
    keys <- paste(entry[[id_col]][i], months, sep = "\x1f")
    all(keys %in% eligible_keys)
  }, logical(1))

  entry[[id_col]][covered]
}
