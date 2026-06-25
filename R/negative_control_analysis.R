#' Negative-Control Outcome (Falsification) Analysis
#'
#' Runs the IP-weighted outcome model on a negative-control outcome -- a cause
#' of death that continued screening mammography cannot plausibly affect -- and
#' reports whether the estimated arm effect is consistent with the null. A
#' clearly non-null association on the negative-control outcome would point to
#' residual confounding or selection bias rather than a true screening effect.
#'
#' @details
#' This ports the negative-control falsification check of García-Albéniz et al.,
#' which used death from cancer of the corpus uteri as the negative-control
#' outcome (supplementary analysis). The function reuses [fit_outcome_hr()] on
#' the negative-control outcome column produced by [expand_to_long()] when
#' called with its `nc_died_col` argument (`nc_dead_t1` by default). The
#' returned odds ratio approximates the hazard ratio for the STOPBASE arm
#' relative to CONTINUE on the negative-control outcome; absent bias it should
#' sit near `null_value`, and `null_consistent` records whether the confidence
#' interval covers it.
#'
#' @inheritParams fit_outcome_hr
#' @param outcome_col Name of the negative-control outcome column, as produced
#'   by [expand_to_long()]. Default: `"nc_dead_t1"`.
#' @param null_value Odds ratio implying no arm effect. Default: `1`.
#'
#' @return A named list:
#'
#'   - `or`: Odds ratio for the STOPBASE arm on the negative-control outcome.
#'   - `or_ci`: 95% confidence interval for `or`.
#'   - `null_consistent`: `TRUE` when `or_ci` covers `null_value`, i.e., the
#'     falsification test passes (no detectable effect on the negative control).
#'   - `model`: The fitted [stats::glm] object.
#'
#' @seealso [fit_outcome_hr()] for the underlying model and [expand_to_long()]
#'   (argument `nc_died_col`) for building the negative-control outcome.
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
#' sim <- simulate_screening_cohort(n = 800, seed = 4, negative_control = TRUE)
#' cloned <- clone_censor(
#'   sim$cohort, sim$screening_mammograms, sim$diagnostic_mammograms
#' )
#' long <- expand_to_long(cloned, nc_died_col = "nc_death")
#' long <- augment_long_covariates(
#'   long, sim$screening_mammograms, sim$diagnostic_mammograms
#' )
#' fit <- fit_screening_propensity(long)
#' weighted <- compute_ipw_weights(fit$data, pred_prob_col = "p_scrmammo")
#' nc <- negative_control_analysis(weighted)
#' nc$or
#' nc$null_consistent
negative_control_analysis <- function(
    long_data,
    covariate_cols = NULL,
    weight_col = "wp99",
    outcome_col = "nc_dead_t1",
    arm_col = "arm",
    month_col = "month2",
    id_col = "id",
    cluster_id_col = id_col,
    max_month = 95L,
    rcs_knots = c(6, 48, 72),
    null_value = 1) {
  if (!outcome_col %in% names(long_data)) {
    cli::cli_abort(c(
      "Column {.val {outcome_col}} not found in {.arg long_data}.",
      "i" = paste(
        "Call {.fn expand_to_long} with {.arg nc_died_col} to build the",
        "negative-control outcome."
      )
    ))
  }

  fit <- fit_outcome_hr(
    long_data,
    covariate_cols = covariate_cols,
    weight_col = weight_col,
    outcome_col = outcome_col,
    arm_col = arm_col,
    month_col = month_col,
    id_col = id_col,
    cluster_id_col = cluster_id_col,
    max_month = max_month,
    rcs_knots = rcs_knots
  )

  null_consistent <- fit$or_ci[[1L]] <= null_value &&
    null_value <= fit$or_ci[[2L]]

  list(
    or = fit$or,
    or_ci = fit$or_ci,
    null_consistent = null_consistent,
    model = fit$model
  )
}
