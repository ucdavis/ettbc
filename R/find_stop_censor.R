# Find first screening mammogram that triggers censoring in STOPBASE arm
find_stop_censor <- function(scr, ucen_stop, start, total_months) {
  scr_post <- scr[scr > start & scr <= total_months]
  if (length(scr_post) == 0L) return(NA_integer_)
  candidates <- scr_post[!ucen_stop[scr_post]]
  if (length(candidates) == 0L) return(NA_integer_)
  min(candidates)
}
