#' Fit IPW-Weighted Outcome Hazard Ratio Model
#'
#' Fits an inverse-probability-weighted pooled logistic regression to estimate
#' the odds ratio (as a hazard ratio approximation) for the STOPBASE arm
#' relative to the CONTINUE arm, with time modeled via restricted cubic
#' splines.
#'
#' @details
#' The model formula is:
#'
#' ```
#' dead_t1 ~ STOPBASE + STOPBASE:month3 + STOPBASE:ns1 + STOPBASE:ns2
#'           + month3 + ns1 + ns2 [+ covariate_cols]
#' ```
#'
#' where `month3` is the 0-indexed follow-up month, and `ns1`/`ns2` are the
#' two columns of the natural spline basis for time (from [splines::ns()]).
#'
#' Participant-level IPW weights from `weight_col` are passed to
#' [stats::glm()]. The returned odds ratio is the exponentiated `STOPBASE`
#' main-effect coefficient. Because the formula includes arm-by-time
#' interaction terms, this coefficient represents the instantaneous log-odds
#' ratio at baseline (month = 0), not an unconditional overall ratio; it is
#' retained as a hazard ratio approximation consistent with the SAS `cann20`
#' macro output.
#'
#' Because the dataset contains repeated person-month observations per
#' participant, standard [stats::glm()] confidence intervals understate
#' uncertainty. When `cluster_id_col` is provided and the `sandwich` package
#' is installed, cluster-robust (HC) variance estimates are used to form the
#' confidence interval, matching the variance estimation in the SAS
#' `PROC SURVEYLOGISTIC` implementation. A Wald confidence interval is used
#' in both branches for consistent output type.
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
#' @param id_col Name of the participant identifier column. Default: `"id"`.
#' @param cluster_id_col Name of the column to use for clustering standard
#'   errors. When non-`NULL` and the `sandwich` package is available,
#'   cluster-robust confidence intervals are returned. Defaults to `id_col`.
#' @param max_month Maximum month included in the model. Rows beyond this
#'   month are excluded. Default: `95L`.
#' @param rcs_knots Numeric vector of length 3: `c(left_boundary,
#'   interior_knot, right_boundary)` for the restricted cubic spline on time.
#'   Default: `c(6, 48, 72)`.
#'
#' @return A named list with three elements:
#'
#'   - `model`: The fitted [stats::glm] object.
#'   - `or`: Odds ratio for the STOPBASE arm (exp of the STOPBASE main-effect
#'     coefficient at baseline month = 0).
#'   - `or_ci`: Named numeric vector of length 2 giving the Wald 95% confidence
#'     interval for the odds ratio (cluster-robust if `sandwich` is available
#'     and `cluster_id_col` is set, otherwise standard).
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
    cluster_id_col = id_col,
    max_month = 95L,
    rcs_knots = c(6, 48, 72)) {
  check_both_arms(long_data, arm_col) # nolint: object_usage_linter
  fit_data <- build_model_data( # nolint: object_usage_linter
    long_data, outcome_col, arm_col, month_col, rcs_knots
  )
  fit_data <- fit_data[
    !is.na(fit_data$dead_t1) & fit_data$month3 <= max_month,
    ,
    drop = FALSE
  ]
  check_both_arms(fit_data, arm_col) # nolint: object_usage_linter

  formula_obj <- build_model_formula(covariate_cols) # nolint: object_usage_linter

  glm_args <- list(
    formula = formula_obj,
    data = fit_data,
    family = stats::binomial(link = "logit")
  )
  if (!is.null(weight_col)) {
    if (!weight_col %in% names(fit_data)) {
      cli::cli_abort(
        c(
          "{.arg weight_col} ({.val {weight_col}}) not found in data.",
          "i" = "Ensure the column exists in {.arg long_data}."
        )
      )
    }
    w <- fit_data[[weight_col]]
    if (!is.numeric(w)) {
      cli::cli_abort(
        "{.arg weight_col} ({.val {weight_col}}) must be numeric."
      )
    }
    glm_args$weights <- w
  }
  fit <- do.call(stats::glm, glm_args)

  or <- exp(stats::coef(fit)[["STOPBASE"]])

  # Use cluster-robust CI when sandwich is available and cluster_id_col is set
  or_ci <- compute_or_ci(fit, fit_data, cluster_id_col)

  list(model = fit, or = or, or_ci = or_ci)
}

#' @noRd
compute_or_ci <- function(fit, fit_data, cluster_id_col) {
  beta <- stats::coef(fit)[["STOPBASE"]]
  if (!is.null(cluster_id_col) &&
      requireNamespace("sandwich", quietly = TRUE)) { # nolint: indentation_linter
    if (!cluster_id_col %in% names(fit_data)) {
      cli::cli_abort(
        c(
          "{.arg cluster_id_col} ({.val {cluster_id_col}}) not found.",
          "i" = "Ensure the column exists in {.arg fit_data}."
        )
      )
    }
    cluster_var <- fit_data[[cluster_id_col]]
    if (anyNA(cluster_var)) {
      cli::cli_abort(
        "Column {.val {cluster_id_col}} must not contain {.code NA} values."
      )
    }
    vcov_robust <- sandwich::vcovCL(fit, cluster = cluster_var)
    se <- sqrt(vcov_robust["STOPBASE", "STOPBASE"])
  } else {
    se <- sqrt(stats::vcov(fit)["STOPBASE", "STOPBASE"])
  }
  ci_raw <- beta + c(-1, 1) * stats::qnorm(0.975) * se
  names(ci_raw) <- c("2.5 %", "97.5 %")
  exp(ci_raw)
}
