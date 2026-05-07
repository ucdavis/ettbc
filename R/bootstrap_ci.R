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
#' @param max_month Maximum month for survival prediction. Default: `95L`.
#' @param rcs_knots Numeric vector of length 3 specifying the restricted cubic
#'   spline knots. Default: `c(6, 48, 72)`.
#' @param n_boot Number of bootstrap iterations. Default: `500L`.
#' @param seed Integer seed for reproducibility. `NULL` means no seed is set.
#'   Default: `NULL`.
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
    max_month = 95L,
    rcs_knots = c(6, 48, 72),
    n_boot = 500L,
    seed = NULL) {
  n_months <- max_month + 1L

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

  if (!is.null(seed)) set.seed(seed)

  ids <- unique(long_data[[id_col]])
  n_ids <- length(ids)

  # Point estimate
  long_data_w <- compute_ipw_weights( # nolint: object_usage_linter
    long_data, pred_prob_col,
    arm_col = arm_col, id_col = id_col, month2_col = month_col
  )
  point_est <- predict_survival_ipw( # nolint: object_usage_linter
    long_data_w,
    weight_col = "wp99",
    covariate_cols = covariate_cols,
    outcome_col = outcome_col,
    arm_col = arm_col,
    month_col = month_col,
    max_month = max_month,
    rcs_knots = rcs_knots
  )

  boot_diffs <- matrix(NA_real_, nrow = n_boot, ncol = n_months)
  boot_s_cont <- matrix(NA_real_, nrow = n_boot, ncol = n_months)
  boot_s_stop <- matrix(NA_real_, nrow = n_boot, ncol = n_months)

  for (b in seq_len(n_boot)) {
    boot_ids <- sample(ids, size = n_ids, replace = TRUE)

    # Build bootstrap dataset, assigning new IDs to handle duplicates
    boot_id_df <- data.frame(
      .new_id = seq_along(boot_ids),
      stringsAsFactors = FALSE
    )
    boot_id_df[[id_col]] <- boot_ids
    boot_data <- merge(boot_id_df, long_data, by = id_col, all.x = TRUE)
    boot_data[[id_col]] <- boot_data$.new_id
    boot_data$.new_id <- NULL
    rownames(boot_data) <- NULL

    tryCatch(
      {
        boot_data_w <- compute_ipw_weights( # nolint: object_usage_linter
          boot_data, pred_prob_col,
          arm_col = arm_col, id_col = id_col, month2_col = month_col
        )
        boot_surv <- predict_survival_ipw( # nolint: object_usage_linter
          boot_data_w,
          weight_col = "wp99",
          covariate_cols = covariate_cols,
          outcome_col = outcome_col,
          arm_col = arm_col,
          month_col = month_col,
          max_month = max_month,
          rcs_knots = rcs_knots
        )
        boot_diffs[b, ] <- boot_surv$s_continue - boot_surv$s_stopbase
        boot_s_cont[b, ] <- boot_surv$s_continue
        boot_s_stop[b, ] <- boot_surv$s_stopbase
      },
      error = function(e) NULL
    )
  }

  col_quantile <- function(mat, prob) {
    apply(mat, 2L, stats::quantile, prob, na.rm = TRUE)
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
