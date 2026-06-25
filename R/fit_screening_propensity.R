#' Fit the Screening-Propensity Model
#'
#' Fits a pooled logistic regression for the probability of receiving a
#' screening mammogram at each eligible participant-month, and returns the
#' fitted model together with the predicted probabilities merged onto the
#' input data. These predictions are the `pred_prob_col` consumed by
#' [compute_ipw_weights()].
#'
#' @details
#' This ports the SAS `cann17b` denominator (`%cann17b_all_model`) propensity
#' model. The outcome is the screening-mammogram indicator `scrmammo`. The
#' linear predictor combines:
#'
#' - the time since the last mammogram, `tslm_lag`, as both a linear term and a
#'   restricted-cubic-spline basis (knots at `rcs_knots`, using the same
#'   Harrell parameterization as [predict_survival_ipw()]);
#' - month from entry as `month2` and `month2^2`;
#' - any additional baseline or time-varying covariates named in `covariates`.
#'
#' The model is fit only on the decision window, the rows with
#' `tslm_lag >= min_tslm_lag`, matching the SAS `where tslm_lag >= 11`. Because
#' the propensity model is arm-independent (the SAS model is fit on the
#' uncloned person-time), the fitting sample is deduplicated to one row per
#' participant-month before fitting, so a participant is not counted twice for
#' appearing in both arms.
#'
#' Predicted probabilities are returned for every row in the decision window;
#' rows outside it (including trial entry, where `tslm_lag` is `NA`) receive
#' `NA`. [compute_ipw_weights()] treats those rows as having no predicted
#' screening, consistent with the SAS weights program.
#'
#' @param long_data A data frame in long format augmented by
#'   [augment_long_covariates()]. Must contain the `scrmammo`, `tslm_lag`, and
#'   `month2` columns (or as specified via the `*_col` arguments), plus every
#'   column named in `covariates`.
#' @param covariates Character vector of additional covariate column names to
#'   include in the model. Default: none. Supply the baseline and time-varying
#'   adjustment covariates here when analyzing real cohort data.
#' @param scrmammo_col Name of the binary screening-mammogram outcome column.
#'   Default: `"scrmammo"`.
#' @param tslm_lag_col Name of the lagged time-since-last-mammogram column.
#'   Default: `"tslm_lag"`.
#' @param month2_col Name of the 0-indexed month-from-entry column.
#'   Default: `"month2"`.
#' @param id_col Name of the participant ID column. Default: `"id"`.
#' @param rcs_knots Numeric vector of restricted-cubic-spline knots for
#'   `tslm_lag`. Default: `c(13, 16, 25, 27)` (the SAS `tslm_lagII` knots).
#' @param min_tslm_lag Minimum `tslm_lag` for a row to enter the model fit and
#'   receive a prediction. Default: `11L`.
#' @param pred_col Name of the predicted-probability column to add to the
#'   returned data. Default: `"p_scrmammo"`.
#'
#' @return A list with two elements:
#'
#'   - `model`: The fitted `glm` object (binomial family, logit link).
#'   - `data`: `long_data` with the `pred_col` column added (`NA` outside the
#'     `tslm_lag >= min_tslm_lag` decision window).
#'
#' @seealso [augment_long_covariates()] for the preceding step and
#'   [compute_ipw_weights()] for the step that consumes `pred_col`.
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
#' cloned <- clone_censor(cohort, screening_mammograms, diagnostic_mammograms)
#' long_data <- expand_to_long(cloned)
#' long_data <- augment_long_covariates(
#'   long_data,
#'   screening_mammograms,
#'   diagnostic_mammograms
#' )
#' fit <- fit_screening_propensity(long_data)
#' weighted <- compute_ipw_weights(fit$data, pred_prob_col = "p_scrmammo")
#' head(weighted[, c("id", "arm", "month2", "w", "wp99")])
fit_screening_propensity <- function(
    long_data,
    covariates = character(0),
    scrmammo_col = "scrmammo",
    tslm_lag_col = "tslm_lag",
    month2_col = "month2",
    id_col = "id",
    rcs_knots = c(13, 16, 25, 27),
    min_tslm_lag = 11L,
    pred_col = "p_scrmammo") {
  required <- c(scrmammo_col, tslm_lag_col, month2_col, id_col, covariates)
  missing_cols <- setdiff(required, names(long_data))
  if (length(missing_cols) > 0L) {
    cli::cli_abort(c(
      "{.arg long_data} is missing required column{?s}: {.val {missing_cols}}.",
      "i" = "Did you call {.fn augment_long_covariates} first?"
    ))
  }

  model_data <- build_propensity_data(
    long_data, scrmammo_col, tslm_lag_col, month2_col, rcs_knots
  )
  rcs_col_names <- attr(model_data, "rcs_col_names")

  in_window <- !is.na(model_data$.tslm_lag) &
    model_data$.tslm_lag >= min_tslm_lag &
    !is.na(model_data$.scrmammo)

  fit_rows <- in_window &
    !duplicated(paste(long_data[[id_col]], model_data$.month2, sep = "\x1f"))
  fit_data <- model_data[fit_rows, , drop = FALSE]

  check_propensity_fit_data(fit_data, min_tslm_lag)

  formula <- build_propensity_formula(rcs_col_names, covariates)
  fit <- stats::glm(formula, data = fit_data, family = stats::binomial())

  preds <- rep(NA_real_, nrow(long_data))
  preds[in_window] <- stats::predict(
    fit, newdata = model_data[in_window, , drop = FALSE], type = "response"
  )
  long_data[[pred_col]] <- preds

  list(model = fit, data = long_data)
}

# Internal helpers --------------------------------------------------------

# Assemble the model matrix columns (outcome, spline basis, time terms).
#' @noRd
build_propensity_data <- function(
    long_data, scrmammo_col, tslm_lag_col, month2_col, rcs_knots) {
  d <- long_data
  d$.scrmammo <- d[[scrmammo_col]]
  d$.tslm_lag <- d[[tslm_lag_col]]
  d$.month2 <- d[[month2_col]]
  # Spline basis is undefined for NA tslm_lag (entry month); use 0 as a
  # placeholder. Those rows are excluded from the fit and the prediction.
  tslm_for_basis <- ifelse(is.na(d$.tslm_lag), 0, d$.tslm_lag)
  rcs_basis <- compute_rcs_basis(tslm_for_basis, rcs_knots)
  rcs_col_names <- colnames(rcs_basis)
  for (j in seq_len(ncol(rcs_basis))) {
    d[[rcs_col_names[j]]] <- rcs_basis[, j]
  }
  attr(d, "rcs_col_names") <- rcs_col_names
  d
}

#' @noRd
build_propensity_formula <- function(rcs_col_names, covariates) {
  terms <- c(
    ".tslm_lag", rcs_col_names,
    ".month2", "I(.month2^2)",
    covariates
  )
  stats::as.formula(paste(".scrmammo ~", paste(terms, collapse = " + ")))
}

#' @noRd
check_propensity_fit_data <- function(fit_data, min_tslm_lag) {
  if (nrow(fit_data) == 0L) {
    cli::cli_abort(c(
      "No rows available to fit the screening-propensity model.",
      "i" = "No participant-months have {.code tslm_lag >= {min_tslm_lag}}."
    ))
  }
  outcome <- fit_data$.scrmammo
  if (length(unique(outcome[!is.na(outcome)])) < 2L) {
    cli::cli_abort(c(
      "The screening-mammogram outcome does not vary in the fitting sample.",
      "i" = "{.fn glm} needs both screened and unscreened months to fit."
    ))
  }
}
