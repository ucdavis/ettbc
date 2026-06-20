# Earliest month follow-up ends: the minimum of death, administrative
# censoring, and protocol censoring (NA values are treated as +Inf).
compute_end_month <- function(death, admin_end, censor) {
  min(
    if (!is.na(death)) death else Inf,
    admin_end,
    if (!is.na(censor)) censor else Inf
  )
}
