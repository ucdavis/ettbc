#' Deterministic Bias Analysis for an Unmeasured Confounder
#'
#' Adjusts an observed arm risk difference for a single hypothetical
#' dichotomous, time-fixed unmeasured confounder, given its prevalence in each
#' arm and its effect on the outcome. This ports the deterministic
#' unmeasured-confounding sensitivity analysis of García-Albéniz et al.
#' (supplementary analysis): how far would the screening effect move if a
#' confounder of a specified strength, more common in one arm than the other,
#' were left uncontrolled?
#'
#' @details
#' For a dichotomous confounder with prevalence `prev_continue` in the CONTINUE
#' arm and `prev_stopbase` in the STOPBASE arm, and an additive effect
#' `confounder_effect` on the outcome risk (the risk when the confounder is
#' present minus the risk when it is absent), the bias it induces in the arm
#' risk difference (CONTINUE minus STOPBASE) is
#' `(prev_continue - prev_stopbase) * confounder_effect`. The bias-adjusted risk
#' difference is `rd` minus that bias.
#'
#' The arguments are recycled to a common length, so passing vectors sweeps a
#' grid of assumptions in one call (e.g., several confounder prevalences against
#' a fixed effect). Express `rd` and `confounder_effect` on the same scale (a
#' risk difference, e.g., cases per person or per 1000); the result is on that
#' scale.
#'
#' @param rd Observed arm risk difference (CONTINUE minus STOPBASE).
#' @param prev_continue Confounder prevalence in the CONTINUE arm (0-1).
#' @param prev_stopbase Confounder prevalence in the STOPBASE arm (0-1).
#' @param confounder_effect Additive effect of the confounder on outcome risk
#'   (risk when present minus risk when absent), on the same scale as `rd`.
#'
#' @return A data frame with one row per assumption set, containing
#'   `rd`, `prev_continue`, `prev_stopbase`, `confounder_effect`, `bias`
#'   (`(prev_continue - prev_stopbase) * confounder_effect`), and `adjusted_rd`
#'   (`rd - bias`).
#'
#' @seealso [probabilistic_bias_analysis()] for the Monte Carlo version.
#'
#' @references
#' García-Albéniz X, Uno H, Bhatt DL, McArdle PH, Joffe MM, Hernán MA.
#' Continuation of Annual Screening Mammography and Breast Cancer Mortality in
#' Women Older Than 70 Years: A Prospective Observational Study.
#' *Ann Intern Med.* 2020;172(6):381-389. \doi{10.7326/M18-1199}
#'
#' @export
#'
#' @examples
#' # A confounder 4 points more common in STOPBASE, raising outcome risk by 0.01
#' deterministic_bias_analysis(
#'   rd = -0.012,
#'   prev_continue = c(0.01, 0.05, 0.10),
#'   prev_stopbase = 0.05,
#'   confounder_effect = 0.01
#' )
deterministic_bias_analysis <- function(
    rd, prev_continue, prev_stopbase, confounder_effect) {
  args <- list(
    rd = rd,
    prev_continue = prev_continue,
    prev_stopbase = prev_stopbase,
    confounder_effect = confounder_effect
  )
  for (nm in names(args)) {
    if (!is.numeric(args[[nm]]) || length(args[[nm]]) == 0L) {
      cli::cli_abort("{.arg {nm}} must be a non-empty numeric vector.")
    }
  }
  check_prevalence(prev_continue, "prev_continue")
  check_prevalence(prev_stopbase, "prev_stopbase")

  grid <- data.frame(args)
  grid$bias <- rd_bias(
    grid$prev_continue, grid$prev_stopbase, grid$confounder_effect
  )
  grid$adjusted_rd <- grid$rd - grid$bias
  grid
}

#' @noRd
check_prevalence <- function(x, name) {
  if (any(x < 0 | x > 1)) {
    cli::cli_abort("{.arg {name}} must be between 0 and 1.")
  }
}
