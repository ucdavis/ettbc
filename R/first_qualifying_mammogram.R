# Box 1 (part 2) of c01_eligibility.sas: the earliest screening mammogram
# within the age-threshold window becomes the study entry month; participants
# without one are excluded.
#' @noRd
first_qualifying_mammogram <- function(
    alive, mammograms, id_col, agein_month_col, mammo_month_col,
    mammo_window_months) {
  merged <- merge(alive, mammograms[c(id_col, mammo_month_col)], by = id_col)
  window_end <- merged[[agein_month_col]] + mammo_window_months - 1L
  in_window <- merged[[mammo_month_col]] >= merged[[agein_month_col]] &
    merged[[mammo_month_col]] <= window_end
  # which() drops NA indices, so a missing mammogram or age-threshold month
  # is excluded rather than propagating an NA row into the result.
  merged <- merged[which(in_window), , drop = FALSE]

  if (nrow(merged) == 0L) {
    out <- alive[0L, c(id_col, agein_month_col), drop = FALSE]
    out$start_month <- integer(0)
    return(out)
  }

  entry_month <- stats::aggregate(
    merged[mammo_month_col],
    by = merged[id_col],
    FUN = min
  )
  names(entry_month)[names(entry_month) == mammo_month_col] <- "start_month"

  merge(alive, entry_month, by = id_col)[
    , c(id_col, agein_month_col, "start_month")
  ]
}
