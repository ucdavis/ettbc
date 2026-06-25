#' Predict Unadjusted Survival Curves
#'
#' Fits a pooled logistic regression with time modeled using restricted cubic
#' splines and arm-by-time interaction terms, then uses g-computation to
#' generate marginal survival curves for each trial arm.
#'
#' @details
#' The model is:
#'
#' ```
#' P(event at t | survived to t) = logistic(
#'   beta_0 + beta_1*STOPBASE + beta_2*STOPBASE*t + beta_3*STOPBASE*t_rcs
#'   + beta_4*t + beta_5*t_rcs
#' )
#' ```
#'
#' where `t` is the (linear) follow-up month and `t_rcs` is the nonlinear
#' restricted-cubic-spline term(s) for time, following the SAS `%RCSPLINE`
#' parameterization with knots at the positions specified by `rcs_knots`. The
#' linear term and the nonlinear spline term(s) together form a full-rank
#' basis for the restricted cubic spline. Survival curves are obtained by the
#' product-limit method applied to the predicted conditional hazard at each
#' time point.
#'
#' @param long_data A data frame in long format (one row per
#'   participant-arm-month), as produced by [expand_to_long()]. Must contain
#'   columns specified by `outcome_col`, `arm_col`, and `month_col`. Both
#'   arms (`"STOPBASE"` and `"CONTINUE"`) must be present; a non-empty subset
#'   with only one arm will raise an error.
#' @param outcome_col Name of the binary outcome column (0/1, `NA` for
#'   censored). Default: `"dead_t1"`.
#' @param arm_col Name of the trial arm column (`"STOPBASE"` / `"CONTINUE"`).
#'   Default: `"arm"`.
#' @param month_col Name of the time variable column (0-indexed month relative
#'   to trial entry). Default: `"month2"`.
#' @param id_col Name of the participant identifier column, used to
#'   deduplicate baseline rows during standardization. Default: `"id"`.
#' @param max_month Maximum month for survival prediction. Rows with month
#'   beyond this value are excluded from both model fitting and prediction.
#'   Default: `95`.
#' @param rcs_knots Numeric vector with at least 3 elements specifying the
#'   knots for the restricted cubic spline: the first element is the left
#'   boundary knot, the last element is the right boundary knot, and any
#'   middle elements are interior knots. Must have at least one interior knot.
#'   Default: `c(6, 48, 72)` (one interior knot at month 48).
#'
#' @return A data frame with one row per month (0 through `max_month`),
#'   containing:
#'
#'   - `month`: Month index (0-indexed from trial entry).
#'   - `s_continue`: Estimated survival probability in the CONTINUE arm.
#'   - `s_stopbase`: Estimated survival probability in the STOPBASE arm.
#'
#' @seealso [predict_survival_baseline_adjusted()], [predict_survival_ipw()],
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
#' surv <- predict_survival_unadjusted(long_data)
#' head(surv)
predict_survival_unadjusted <- function(
    long_data,
    outcome_col = "dead_t1",
    arm_col = "arm",
    month_col = "month2",
    id_col = "id",
    max_month = 95L,
    rcs_knots = c(6, 48, 72)) {
  if (nrow(long_data) == 0L) {
    return(data.frame(
      month = integer(0),
      s_continue = numeric(0),
      s_stopbase = numeric(0)
    ))
  }
  check_both_arms(long_data, arm_col)
  md <- build_model_data(
    long_data, outcome_col, arm_col, month_col, rcs_knots
  )
  fit_data <- md$data
  rcs_col_names <- md$rcs_col_names
  fit_data <- fit_data[
    !is.na(fit_data$dead_t1) & fit_data$month3 <= max_month,
    ,
    drop = FALSE
  ]
  check_both_arms(fit_data, arm_col)
  formula_obj <- build_model_formula(rcs_col_names)
  fit <- stats::glm(
    formula_obj,
    data = fit_data,
    family = stats::binomial(link = "logit")
  )
  standardize_survival(
    fit, fit_data, max_month, rcs_knots, id_col, rcs_col_names
  )
}

#' Predict Baseline-Adjusted Survival Curves
#'
#' Fits a pooled logistic regression that includes baseline covariates alongside
#' time-by-arm interaction terms, then uses g-computation (standardization) to
#' generate marginal survival curves for each trial arm.
#'
#' @details
#' Extends [predict_survival_unadjusted()] by adding baseline covariate
#' columns to the right-hand side of the regression formula. Standardization
#' averages predicted survival over the empirical distribution of baseline
#' covariates so that the returned curves are marginal (population-averaged)
#' rather than conditional.
#'
#' @inheritParams predict_survival_unadjusted
#' @param covariate_cols Character vector of column names to include as
#'   additional baseline adjustment terms in the model. Set to `NULL` for no
#'   adjustment (equivalent to [predict_survival_unadjusted()]). Default:
#'   `NULL`.
#'
#' @return A data frame with one row per month (0 through `max_month`),
#'   containing:
#'
#'   - `month`: Month index (0-indexed from trial entry).
#'   - `s_continue`: Estimated marginal survival probability in the CONTINUE
#'     arm.
#'   - `s_stopbase`: Estimated marginal survival probability in the STOPBASE
#'     arm.
#'
#' @seealso [predict_survival_unadjusted()], [predict_survival_ipw()],
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
#' surv <- predict_survival_baseline_adjusted(long_data)
#' head(surv)
predict_survival_baseline_adjusted <- function( # nolint: object_length_linter
    long_data,
    covariate_cols = NULL,
    outcome_col = "dead_t1",
    arm_col = "arm",
    month_col = "month2",
    id_col = "id",
    max_month = 95L,
    rcs_knots = c(6, 48, 72)) {
  if (nrow(long_data) == 0L) {
    return(data.frame(
      month = integer(0),
      s_continue = numeric(0),
      s_stopbase = numeric(0)
    ))
  }
  check_both_arms(long_data, arm_col)
  md <- build_model_data(
    long_data, outcome_col, arm_col, month_col, rcs_knots
  )
  fit_data <- md$data
  rcs_col_names <- md$rcs_col_names
  fit_data <- fit_data[
    !is.na(fit_data$dead_t1) & fit_data$month3 <= max_month,
    ,
    drop = FALSE
  ]
  check_both_arms(fit_data, arm_col)
  formula_obj <- build_model_formula(rcs_col_names, covariate_cols)
  fit <- stats::glm(
    formula_obj,
    data = fit_data,
    family = stats::binomial(link = "logit")
  )
  standardize_survival(
    fit, fit_data, max_month, rcs_knots, id_col, rcs_col_names
  )
}

#' Predict IPW-Weighted Survival Curves
#'
#' Fits an inverse-probability-weighted pooled logistic regression with
#' time modeled using restricted cubic splines and arm-by-time interaction
#' terms, then uses g-computation to generate marginal survival curves for
#' each trial arm.
#'
#' @details
#' Extends [predict_survival_unadjusted()] by passing participant-level IPW
#' weights to [stats::glm()]. This up-weights participants with low probability
#' of following their assigned arm protocol, creating a pseudo-population in
#' which protocol adherence is independent of baseline characteristics.
#'
#' @inheritParams predict_survival_unadjusted
#' @param weight_col Name of the column containing IPW weights (e.g., as
#'   produced by [compute_ipw_weights()]). Set to `NULL` for unweighted
#'   estimation. Default: `"wp99"`.
#' @param covariate_cols Character vector of column names to include as
#'   additional adjustment terms in the model. These covariates are used during
#'   g-computation standardization over baseline rows (month = 0), so they
#'   must be measured at or before baseline. Set to `NULL` for no additional
#'   adjustment. Default: `NULL`.
#'
#' @return A data frame with one row per month (0 through `max_month`),
#'   containing:
#'
#'   - `month`: Month index (0-indexed from trial entry).
#'   - `s_continue`: Estimated marginal survival probability in the CONTINUE
#'     arm.
#'   - `s_stopbase`: Estimated marginal survival probability in the STOPBASE
#'     arm.
#'
#' @seealso [predict_survival_unadjusted()],
#'   [predict_survival_baseline_adjusted()], [compute_ipw_weights()],
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
#' surv <- predict_survival_ipw(long_data, weight_col = "wp99")
#' head(surv)
predict_survival_ipw <- function(
    long_data,
    weight_col = "wp99",
    covariate_cols = NULL,
    outcome_col = "dead_t1",
    arm_col = "arm",
    month_col = "month2",
    id_col = "id",
    max_month = 95L,
    rcs_knots = c(6, 48, 72)) {
  if (nrow(long_data) == 0L) {
    return(data.frame(
      month = integer(0),
      s_continue = numeric(0),
      s_stopbase = numeric(0)
    ))
  }
  check_both_arms(long_data, arm_col)
  md <- build_model_data(
    long_data, outcome_col, arm_col, month_col, rcs_knots
  )
  fit_data <- md$data
  rcs_col_names <- md$rcs_col_names
  fit_data <- fit_data[
    !is.na(fit_data$dead_t1) & fit_data$month3 <= max_month,
    ,
    drop = FALSE
  ]
  check_both_arms(fit_data, arm_col)
  formula_obj <- build_model_formula(rcs_col_names, covariate_cols)
  fit <- fit_weighted_logistic(fit_data, formula_obj, weight_col)
  standardize_survival(
    fit, fit_data, max_month, rcs_knots, id_col, rcs_col_names
  )
}

# Internal helpers --------------------------------------------------------

#' @noRd
build_model_formula <- function(rcs_col_names, covariate_cols = NULL) {
  rcs_interaction_terms <- paste0("STOPBASE:", rcs_col_names)
  base_terms <- c(
    "STOPBASE", "STOPBASE:month3",
    rcs_interaction_terms,
    "month3", rcs_col_names
  )
  all_terms <- c(base_terms, covariate_cols)
  stats::as.formula(paste("dead_t1 ~", paste(all_terms, collapse = " + ")))
}

#' @noRd
check_both_arms <- function(long_data, arm_col) {
  arms <- unique(long_data[[arm_col]])
  # Reject NA arm values
  if (any(is.na(arms))) {
    cli::cli_abort(
      c(
        "{.arg long_data} contains {.code NA} in {.arg arm_col}.",
        "i" = "All rows must have a valid arm value."
      )
    )
  }
  # Reject unexpected arm values
  unexpected <- setdiff(arms, c("STOPBASE", "CONTINUE"))
  if (length(unexpected) > 0L) {
    cli::cli_abort(
      c(
        paste0(
          "{.arg long_data} contains unexpected arm value(s): ",
          "{.val {unexpected}}."
        ),
        "i" = "Valid arm values are {.val STOPBASE} and {.val CONTINUE}."
      )
    )
  }
  missing <- setdiff(c("STOPBASE", "CONTINUE"), arms)
  if (length(missing) > 0L) {
    cli::cli_abort(
      c(
        "Both arms must be present in {.arg long_data}.",
        "x" = "Missing arm(s): {.val {missing}}.",
        "i" = paste(
          "The pooled logistic regression requires arm-by-time",
          "interaction terms for both arms."
        )
      )
    )
  }
}

#' @noRd
build_model_data <- function(
    long_data, outcome_col, arm_col, month_col, rcs_knots) {
  d <- long_data
  d$STOPBASE <- as.integer(d[[arm_col]] == "STOPBASE")
  d$month3 <- d[[month_col]]
  d$dead_t1 <- d[[outcome_col]]
  rcs_basis <- compute_rcs_basis(d$month3, rcs_knots)
  rcs_col_names <- colnames(rcs_basis)
  for (j in seq_len(ncol(rcs_basis))) {
    d[[rcs_col_names[j]]] <- rcs_basis[, j]
  }
  list(data = d, rcs_col_names = rcs_col_names)
}

#' @noRd
standardize_survival <- function(
    fit, fit_data, max_month, rcs_knots, id_col, rcs_col_names) {
  if (!id_col %in% names(fit_data)) {
    cli::cli_abort(
      c(
        "{.arg id_col} ({.val {id_col}}) not found in {.arg fit_data}.",
        "i" = "Ensure the participant identifier column exists in the data."
      )
    )
  }
  # One row per individual at baseline (deduplicate on id_col)
  is_baseline <- fit_data$month3 == 0L
  baseline_data <- fit_data[is_baseline, , drop = FALSE]
  baseline_data <- baseline_data[
    !duplicated(baseline_data[[id_col]]),
    ,
    drop = FALSE
  ]
  n_indiv <- nrow(baseline_data)

  if (n_indiv == 0L) {
    cli::cli_abort(
      c(
        "No baseline rows (month == 0) found in {.arg fit_data}.",
        "i" = "Requires at least one row per participant at baseline."
      )
    )
  }

  months <- 0L:max_month
  n_months <- length(months)

  pred_cont <- baseline_data
  pred_cont$STOPBASE <- 0L
  pred_stop <- baseline_data
  pred_stop$STOPBASE <- 1L

  s_x1 <- rep(1.0, n_indiv)
  s_x2 <- rep(1.0, n_indiv)

  s_continue_vec <- numeric(n_months)
  s_stopbase_vec <- numeric(n_months)

  for (ti in seq_len(n_months)) {
    t <- months[ti]
    rcs_t <- compute_rcs_basis(t, rcs_knots)
    pred_cont$month3 <- t
    pred_stop$month3 <- t
    for (j in seq_along(rcs_col_names)) {
      pred_cont[[rcs_col_names[j]]] <- rcs_t[1L, j]
      pred_stop[[rcs_col_names[j]]] <- rcs_t[1L, j]
    }

    p_x1 <- stats::predict(fit, newdata = pred_cont, type = "response")
    p_x2 <- stats::predict(fit, newdata = pred_stop, type = "response")

    s_x1 <- s_x1 * (1.0 - p_x1)
    s_x2 <- s_x2 * (1.0 - p_x2)

    s_continue_vec[ti] <- mean(s_x1)
    s_stopbase_vec[ti] <- mean(s_x2)
  }

  data.frame(
    month = months,
    s_continue = s_continue_vec,
    s_stopbase = s_stopbase_vec
  )
}
