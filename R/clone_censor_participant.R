# Clone a single participant into STOPBASE and CONTINUE arm rows, applying
# each arm's censoring rule. Returns a list with elements `stopbase` and
# `continue`, each a one-row data frame.
clone_censor_participant <- function(
    base_row, start, admin_end, death, bc_death, bc_month, scr, dx, end_col,
    stop_grace_months, continue_grace_months, total_months) {
  # ---- STOPBASE arm ----
  ucen_stop <- build_ucen_stop(bc_month, start, stop_grace_months, total_months)
  censor_stop <- find_stop_censor(scr, ucen_stop, start, total_months)
  mend_stop <- compute_end_month(death, admin_end, censor_stop)
  stopbase <- make_arm_row(
    base_row, "STOPBASE", end_col,
    mend_stop, start, death, bc_death, censor_stop
  )

  # ---- CONTINUE arm ----
  ucen_cont <- build_ucen_cont(
    bc_month, start, continue_grace_months, scr, dx, total_months
  )
  censor_cont <- find_cont_censor(ucen_cont, start, total_months)
  mend_cont <- compute_end_month(death, admin_end, censor_cont)
  continue <- make_arm_row(
    base_row, "CONTINUE", end_col,
    mend_cont, start, death, bc_death, censor_cont
  )

  list(stopbase = stopbase, continue = continue)
}
