# Build CONTINUE uncensorable indicator vector
build_ucen_cont <- function(
    bc_month, start, continue_grace_months, scr, dx, total_months) {
  ucen <- logical(total_months)
  if (!is.na(bc_month) && bc_month >= 1L && bc_month <= total_months) {
    ucen[seq.int(bc_month, total_months)] <- TRUE
  }
  grace <- min(start + continue_grace_months - 1L, total_months)
  ucen[seq.int(start, grace)] <- TRUE
  for (m in dx) {
    if (m >= 1L && m <= total_months) {
      ucen[seq.int(m, min(m + continue_grace_months, total_months))] <- TRUE
    }
  }
  for (m in scr) {
    if (m >= 1L && m <= total_months) {
      ucen[seq.int(m, min(m + continue_grace_months, total_months))] <- TRUE
    }
  }
  ucen
}
