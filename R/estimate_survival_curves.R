# Compute stabilized IPW weights and the IPW-adjusted marginal survival
# curves for one dataset. Shared by the point estimate and each bootstrap
# iteration so the two stay in lockstep.
estimate_survival_curves <- function(
    data, pred_prob_col, covariate_cols, outcome_col, arm_col, id_col,
    month_col, bc_month_col, scrmammo_col, tslm_lag_col, grace_months,
    max_month, rcs_knots) {
  data_w <- compute_ipw_weights( # nolint: object_usage_linter
    data, pred_prob_col,
    arm_col = arm_col, id_col = id_col, month2_col = month_col,
    bc_month_col = bc_month_col, scrmammo_col = scrmammo_col,
    tslm_lag_col = tslm_lag_col, grace_months = grace_months
  )
  predict_survival_ipw( # nolint: object_usage_linter
    data_w,
    weight_col = "wp99",
    covariate_cols = covariate_cols,
    outcome_col = outcome_col,
    arm_col = arm_col,
    id_col = id_col,
    month_col = month_col,
    max_month = max_month,
    rcs_knots = rcs_knots
  )
}
