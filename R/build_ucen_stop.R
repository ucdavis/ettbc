# Build STOPBASE uncensorable indicator vector
build_ucen_stop <- function(bc_month, start, stop_grace_months, total_months) {
  ucen <- logical(total_months)
  if (!is.na(bc_month) && bc_month >= 1L && bc_month <= total_months) {
    ucen[seq.int(bc_month, total_months)] <- TRUE
  }
  grace <- min(start + stop_grace_months, total_months)
  ucen[seq.int(start, grace)] <- TRUE
  ucen
}
