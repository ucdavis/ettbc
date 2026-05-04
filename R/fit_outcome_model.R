#' Fit IPW-Weighted Outcome Hazard Ratio Model
#'
#' Fits an inverse-probability-weighted pooled logistic regression to estimate
#' the odds ratio (as a hazard ratio approximation) for the STOPBASE arm
#' relative to the CONTINUE arm, with time modelled via restricted cubic
#' splines.
#'
#' @details
#' The model formula is:
#'
#' ```
#' dead_t1 ~ STOPBASE + STOPBASE:month + STOPBASE:rcs1 + STOPBASE:rcs2
#'           + month + rcs1 + rcs2 [+ covariate_cols]
#' ```
#'
#' Participant-level IPW weights from `weight_col` are passed to
#' [stats::glm()]. The returned odds ratio corresponds to the `STOPBASE`
#' coefficient, which approximates the hazard ratio when the event is rare.
#'
#' @param long_data A data frame in long format (one row per
#'   participant-arm-month), as produced by [expand_to_long()].
#' @param covariate_cols Character vector of column names to include as
#'   additional baseline adjustment terms. Set to `NULL` for no adjustment.
#'   Default: `NULL`.
#' @param weight_col Name of the column containing IPW weights. Set to `NULL`
#'   for unweighted estimation. Default: `"wp99"`.
#' @param outcome_col Name of the binary outcome column. Default: `"dead_t1"`.
#' @param arm_col Name of the trial arm column. Default: `"arm"`.
#' @param month_col Name of the 0-indexed month-from-entry column.
#'   Default: `"month2"`.
#' @param id_col Name of the participant identifier column (reserved for
#'   future use with robust standard errors). Default: `"id"`.
#' @param max_month Maximum month included in the model. Rows beyond this
#'   month are excluded. Default: `95L`.
#' @param rcs_knots Numeric vector of length 3: `c(left_boundary,
#'   interior_knot, right_boundary)` for the restricted cubic spline on time.
#'   Default: `c(6, 48, 72)`.
#'
#' @return A named list with three elements:
#'
#'   - `model`: The fitted [stats::glm] object.
#'   - `or`: Odds ratio for the STOPBASE arm (exp of the STOPBASE coefficient).
#'   - `or_ci`: Named numeric vector of length 2 giving the 95% confidence
#'     interval for the odds ratio.
#'
#' @seealso [compute_ipw_weights()], [predict_survival_ipw()],
#'   [expand_to_long()]
#'
#' @references
#' García-Albéniz X, Uno H, Bhatt DL, McArdle PH, Joffe MM, Hernán MA.
#' Continuation of Annual Screening Mammography and Breast Cancer Mortality in
#' Women Older Than 70 Years: A Prospective Observational Study.
#' *Ann Intern Med.* 2020;172(6):381–389. \doi{10.7326/M18-1199}
#'
#' @export
#'
#' @examples
#' cloned <- clone_censor(cohort, screening_mammograms, diagnostic_mammograms)
#' long_data <- expand_to_long(cloned)
#' long_data$wp99 <- 1.0
#' result <- fit_outcome_hr( # nolint: line_length_linter
#'   long_data, covariate_cols = NULL, weight_col = "wp99"
#' )
#' result$or
fit_outcome_hr <- function(
    long_data,
    covariate_cols = NULL,
    weight_col = "wp99",
    outcome_col = "dead_t1",
    arm_col = "arm",
    month_col = "month2",
    id_col = "id",
    max_month = 95L,
    rcs_knots = c(6, 48, 72)) {
  fit_data <- build_model_data( # nolint: object_usage_linter
    long_data, outcome_col, arm_col, month_col, rcs_knots
  )
  fit_data <- fit_data[
    !is.na(fit_data$dead_t1) & fit_data$month3 <= max_month,
    ,
    drop = FALSE
  ]

  formula_obj <- build_model_formula(covariate_cols) # nolint: object_usage_linter

  glm_args <- list(
    formula = formula_obj,
    data = fit_data,
    family = stats::binomial(link = "logit")
  )
  if (!is.null(weight_col)) {
    glm_args$weights <- fit_data[[weight_col]]
  }
  fit <- do.call(stats::glm, glm_args)

  or <- exp(stats::coef(fit)[["STOPBASE"]])
  ci_raw <- suppressMessages(stats::confint(fit, parm = "STOPBASE"))
  or_ci <- exp(ci_raw)

  list(model = fit, or = or, or_ci = or_ci)
}
