#' Bootstrap Confidence Intervals for Survival Difference
#'
#' Uses the nonparametric bootstrap to compute 95% percentile confidence
#' intervals for the difference in marginal survival between the CONTINUE and
#' STOPBASE arms, as estimated by [predict_survival_ipw()].
#'
#' @details
#' At each bootstrap iteration, participant IDs are sampled with replacement.
#' All long-format rows belonging to a sampled ID are included in the bootstrap
#' dataset, with duplicate draws receiving distinct synthetic identifiers. IPW
#' weights are recomputed on each bootstrap sample before estimating survival
#' curves.
#'
#' The point estimate uses the original (unbootstrapped) data. Confidence
#' intervals are taken as the 2.5th and 97.5th percentiles of the bootstrap
#' distribution.
#'
#' @param long_data A data frame in long format (one row per
#'   participant-arm-month), as produced by [expand_to_long()] and augmented
#'   with the columns required by [compute_ipw_weights()].
#' @param pred_prob_col Name of the column containing the model-predicted
#'   probability of a screening mammogram, passed to [compute_ipw_weights()].
#' @param covariate_cols Character vector of covariate column names for
#'   [predict_survival_ipw()]. Set to `NULL` for unadjusted estimation.
#'   Default: `NULL`.
#' @param id_col Name of the participant identifier column. Default: `"id"`.
#' @param outcome_col Name of the binary outcome column. Default: `"dead_t1"`.
#' @param arm_col Name of the trial arm column. Default: `"arm"`.
#' @param month_col Name of the 0-indexed month-from-entry column.
#'   Default: `"month2"`.
#' @param bc_month_col Name of the breast-cancer diagnosis month column,
#'   forwarded to [compute_ipw_weights()]. Default: `"monthBC"`.
#' @param scrmammo_col Name of the screening-mammogram indicator column,
#'   forwarded to [compute_ipw_weights()]. Default: `"scrmammo"`.
#' @param tslm_lag_col Name of the lagged time-since-last-mammogram column,
#'   forwarded to [compute_ipw_weights()]. Default: `"tslm_lag"`.
#' @param grace_months Length of the compliance grace period in months,
#'   forwarded to [compute_ipw_weights()]. Default: `11L`.
#' @param max_month Maximum month for survival prediction. Default: `95L`.
#' @param rcs_knots Numeric vector with at least 3 elements specifying the
#'   knots for the restricted cubic spline: the first element is the left
#'   boundary knot, the last element is the right boundary knot, and any
#'   middle elements are interior knots. Must have at least one interior knot.
#'   Default: `c(6, 48, 72)` (one interior knot at month 48).
#' @param n_boot Number of bootstrap iterations. Default: `500L`.
#' @param seed Integer seed for reproducibility. `NULL` means no seed is set.
#'   Default: `NULL`.
#' @param fail_threshold Maximum proportion of bootstrap iterations that may
#'   fail before a warning is issued. Default: `0.1` (warn if more than 10%
#'   of iterations fail).
#'
#' @return A data frame with one row per month (0 through `max_month`),
#'   containing:
#'
#'   - `month`: Month index (0-indexed from trial entry).
#'   - `diff`: Point estimate of `s_continue - s_stopbase`.
#'   - `diff_lo`: 2.5th percentile bootstrap estimate of the survival
#'     difference.
#'   - `diff_hi`: 97.5th percentile bootstrap estimate of the survival
#'     difference.
#'   - `s_continue`: Point estimate of survival in the CONTINUE arm.
#'   - `s_stopbase`: Point estimate of survival in the STOPBASE arm.
#'   - `s_continue_lo`: 2.5th percentile bootstrap estimate for CONTINUE
#'     survival.
#'   - `s_continue_hi`: 97.5th percentile bootstrap estimate for CONTINUE
#'     survival.
#'   - `s_stopbase_lo`: 2.5th percentile bootstrap estimate for STOPBASE
#'     survival.
#'   - `s_stopbase_hi`: 97.5th percentile bootstrap estimate for STOPBASE
#'     survival.
#'
#' @seealso [predict_survival_ipw()], [compute_ipw_weights()]
#'
#' @references
#' García-Albéniz X, Uno H, Bhatt DL, McArdle PH, Joffe MM, Hernán MA.
#' Continuation of Annual Screening Mammography and Breast Cancer Mortality in
#' Women Older Than 70 Years: A Prospective Observational Study.
#' *Ann Intern Med.* 2020;172(6):381–389. \doi{10.7326/M18-1199}
#'
#' @export
bootstrap_ci <- function(
    long_data,
    pred_prob_col,
    covariate_cols = NULL,
    id_col = "id",
    outcome_col = "dead_t1",
    arm_col = "arm",
    month_col = "month2",
    bc_month_col = "monthBC",
    scrmammo_col = "scrmammo",
    tslm_lag_col = "tslm_lag",
    grace_months = 11L,
    max_month = 95L,
    rcs_knots = c(6, 48, 72),
    n_boot = 500L,
    seed = NULL,
    fail_threshold = 0.1) {
  n_months <- max_month + 1L

  n_boot <- as.integer(n_boot)
  if (is.na(n_boot) || n_boot < 1L) {
    cli::cli_abort(
      "{.arg n_boot} must be a single positive integer."
    )
  }

  empty_result <- data.frame(
    month = 0L:max_month,
    diff = rep(NA_real_, n_months),
    diff_lo = rep(NA_real_, n_months),
    diff_hi = rep(NA_real_, n_months),
    s_continue = rep(NA_real_, n_months),
    s_stopbase = rep(NA_real_, n_months),
    s_continue_lo = rep(NA_real_, n_months),
    s_continue_hi = rep(NA_real_, n_months),
    s_stopbase_lo = rep(NA_real_, n_months),
    s_stopbase_hi = rep(NA_real_, n_months)
  )

  if (nrow(long_data) == 0L) return(empty_result)

  ids <- unique(long_data[[id_col]])
  if (anyNA(ids)) {
    cli::cli_abort(
      "Column {.val {id_col}} must not contain {.code NA} values."
    )
  }

  est_args <- list(
    pred_prob_col = pred_prob_col, covariate_cols = covariate_cols,
    outcome_col = outcome_col, arm_col = arm_col, id_col = id_col,
    month_col = month_col, bc_month_col = bc_month_col,
    scrmammo_col = scrmammo_col, tslm_lag_col = tslm_lag_col,
    grace_months = grace_months, max_month = max_month, rcs_knots = rcs_knots
  )

  # Point estimate (uses the original, unbootstrapped data)
  point_est <- do.call(estimate_survival_curves, c(list(long_data), est_args))

  # Pre-split long_data by id_col once to avoid repeated merge() in the loop
  long_data_split <- split(long_data, long_data[[id_col]])

  # withr::with_seed() seeds the bootstrap locally and restores the caller's
  # RNG stream on exit.
  boot <- if (is.null(seed)) {
    run_bootstrap_iterations(
      ids, long_data_split, id_col, n_boot, n_months, est_args
    )
  } else {
    withr::with_seed(seed, run_bootstrap_iterations(
      ids, long_data_split, id_col, n_boot, n_months, est_args
    ))
  }
  boot_diffs <- boot$diffs
  boot_s_cont <- boot$s_cont
  boot_s_stop <- boot$s_stop
  n_failed <- boot$n_failed

  if (n_failed > 0L) {
    fail_rate <- n_failed / n_boot
    if (fail_rate > fail_threshold) {
      pct <- round(fail_rate * 100) # nolint: object_usage_linter
      cli::cli_warn(
        "{n_failed} of {n_boot} bootstrap iterations failed ({pct}%)."
      )
    }
  }

  data.frame(
    month = 0L:max_month,
    diff = point_est$s_continue - point_est$s_stopbase,
    diff_lo = col_quantile(boot_diffs, 0.025),
    diff_hi = col_quantile(boot_diffs, 0.975),
    s_continue = point_est$s_continue,
    s_stopbase = point_est$s_stopbase,
    s_continue_lo = col_quantile(boot_s_cont, 0.025),
    s_continue_hi = col_quantile(boot_s_cont, 0.975),
    s_stopbase_lo = col_quantile(boot_s_stop, 0.025),
    s_stopbase_hi = col_quantile(boot_s_stop, 0.975)
  )
}

# Run the bootstrap resampling loop: for each of `n_boot` iterations, resample
# participant ids, rebuild the long dataset, and re-estimate the survival
# curves. Returns the per-iteration difference and arm-survival matrices plus a
# failed-iteration count. Wrapped in withr::with_seed() by the caller so the
# RNG stream is seeded locally.
#' @noRd
run_bootstrap_iterations <- function(
    ids, long_data_split, id_col, n_boot, n_months, est_args) {
  diffs <- matrix(NA_real_, nrow = n_boot, ncol = n_months)
  s_cont <- matrix(NA_real_, nrow = n_boot, ncol = n_months)
  s_stop <- matrix(NA_real_, nrow = n_boot, ncol = n_months)
  n_failed <- 0L
  n_ids <- length(ids)

  for (b in seq_len(n_boot)) {
    boot_ids <- sample(ids, size = n_ids, replace = TRUE)
    boot_data <- build_bootstrap_sample(boot_ids, long_data_split, id_col)

    tryCatch(
      {
        boot_surv <- do.call(
          estimate_survival_curves, c(list(boot_data), est_args)
        )
        diffs[b, ] <- boot_surv$s_continue - boot_surv$s_stopbase
        s_cont[b, ] <- boot_surv$s_continue
        s_stop[b, ] <- boot_surv$s_stopbase
      },
      error = function(e) {
        n_failed <<- n_failed + 1L
      }
    )
  }

  list(diffs = diffs, s_cont = s_cont, s_stop = s_stop, n_failed = n_failed)
}
