# Additive risk-difference bias from a single dichotomous, time-fixed
# unmeasured confounder. For a confounder with prevalence `prev_continue` in the
# CONTINUE arm and `prev_stopbase` in the STOPBASE arm, and an additive effect
# `confounder_effect` on the outcome risk (risk when the confounder is present
# minus risk when absent), the bias it induces in the arm risk difference
# (CONTINUE minus STOPBASE) is the prevalence difference times the effect. The
# bias-adjusted risk difference is the observed one minus this quantity.
#' @noRd
rd_bias <- function(prev_continue, prev_stopbase, confounder_effect) {
  (prev_continue - prev_stopbase) * confounder_effect
}
