#' Compute Inverse Probability Weighting (IPW) Weights
#'
#' Computes stabilized inverse probability weights for each
#' participant-arm-month row in long-format data, based on the predicted
#' probability of receiving a screening mammogram. Weights are truncated at
#' the 99th percentile computed separately within each arm.
#'
#' @details
#' Separate weight models are used for the two trial arms:
#'
#' - **STOPBASE**: The weight tracks the probability of *not* receiving a
#'   screening mammogram. After a grace period of `grace_months` months, the
#'   denominator is `1 - p_scrmammo` at each month (or 1 if a breast cancer
#'   diagnosis has occurred). If the time since last mammogram is 10 or fewer
#'   months (`tslm_lag <= 10`), the effective screening probability is set to
#'   0 (no screening expected that soon).
#'
#' - **CONTINUE**: The compliance window is reset by any mammogram (screening
#'   or diagnostic), as measured by `tslm_lag`. A weight update occurs at
#'   every month within the compliance window (`tslm_lag` = 11, 12, or 13).
#'   The numerator uses the conditional probability of the observed action
#'   under a discrete uniform distribution over months 11–13: 1/3 at month 11,
#'   1/2 at month 12 (given no earlier screening), and 1 at month 13. The
#'   denominator is the model-predicted probability. Weights stop updating
#'   after a breast-cancer diagnosis.
#'
#' Weights within each arm are cumulative products initialized at 1.
#' The final column `wp99` is the weight truncated at the 99th percentile of
#' `w` computed **separately within each arm**.
#'
#' @param long_data A data frame in long format (one row per
#'   participant-arm-month), as produced by [expand_to_long()] and augmented
#'   with mammogram and time-since-last-mammogram columns.
#' @param pred_prob_col Name of the column containing the model-predicted
#'   probability of a screening mammogram at each row.
#' @param arm_col Name of the trial arm column. Default: `"arm"`.
#' @param id_col Name of the participant identifier column. Default: `"id"`.
#' @param month2_col Name of the 0-indexed month-from-entry column.
#'   Default: `"month2"`.
#' @param bc_month_col Name of the column containing the month2 at which breast
#'   cancer was diagnosed (`NA` if no diagnosis). Default: `"monthBC"`.
#' @param scrmammo_col Name of the binary screening-mammogram indicator column.
#'   Default: `"scrmammo"`.
#' @param tslm_lag_col Name of the lagged time-since-last-mammogram column
#'   (months since the last any mammogram, screening or diagnostic).
#'   Default: `"tslm_lag"`.
#' @param grace_months Number of months from trial entry during which weights
#'   are held at 1 for the STOPBASE arm. Default: `11L`.
#'
#' @return `long_data` with two additional columns:
#'
#'   - `w`: Cumulative IPW weight at each participant-arm-month.
#'   - `wp99`: IPW weight truncated at the 99th percentile of `w` within each
#'     arm separately.
#'
#' @seealso [predict_survival_ipw()], [expand_to_long()]
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
#' long_data$p_scrmammo <- 0.3
#' long_data$monthBC <- NA_integer_
#' long_data$scrmammo <- 0L
#' long_data$tslm_lag <- 5L
#' result <- compute_ipw_weights(long_data, pred_prob_col = "p_scrmammo")
#' head(result[, c("id", "arm", "month2", "w", "wp99")])
compute_ipw_weights <- function(
    long_data,
    pred_prob_col,
    arm_col = "arm",
    id_col = "id",
    month2_col = "month2",
    bc_month_col = "monthBC",
    scrmammo_col = "scrmammo",
    tslm_lag_col = "tslm_lag",
    grace_months = 11L) {
  if (nrow(long_data) == 0L) {
    long_data$w <- numeric(0)
    long_data$wp99 <- numeric(0)
    return(long_data)
  }

  # Validate pred_prob_col
  if (!pred_prob_col %in% names(long_data)) {
    cli::cli_abort(c(
      "Column {.arg pred_prob_col} ({.val {pred_prob_col}}) not found.",
      "i" = "Check column names in {.arg long_data}."
    ))
  }
  preds <- long_data[[pred_prob_col]]
  if (!is.numeric(preds)) {
    cli::cli_abort(
      "{.arg pred_prob_col} ({.val {pred_prob_col}}) must be numeric."
    )
  }
  if (any(!is.na(preds) & (preds < 0 | preds > 1))) {
    cli::cli_abort(
      "{.arg pred_prob_col} ({.val {pred_prob_col}}) must be in [0, 1]."
    )
  }

  # Preserve original row order
  long_data$.row_idx <- seq_len(nrow(long_data))

  grp_key <- paste(long_data[[id_col]], long_data[[arm_col]], sep = "\x1f")
  d_list <- split(long_data, grp_key)

  d_list <- lapply(d_list, function(grp) {
    if (nrow(grp) == 0L) return(grp)
    grp <- grp[order(grp[[month2_col]]), , drop = FALSE]
    arm <- grp[[arm_col]][1L]
    if (is.na(arm) || !arm %in% c("STOPBASE", "CONTINUE")) {
      cli::cli_abort(
        c(
          "Unexpected arm value {.val {arm}} in {.arg long_data}.",
          "i" = "Valid arm values are {.val STOPBASE} and {.val CONTINUE}."
        )
      )
    }
    grp$w <- if (arm == "STOPBASE") {
      compute_w_stopbase_grp(
        grp, pred_prob_col, month2_col, bc_month_col,
        tslm_lag_col, grace_months
      )
    } else {
      compute_w_continue_grp(
        grp, pred_prob_col, scrmammo_col,
        tslm_lag_col, bc_month_col, month2_col
      )
    }
    grp
  })

  out <- do.call(rbind, d_list)
  out <- out[order(out$.row_idx), , drop = FALSE]
  out$.row_idx <- NULL
  rownames(out) <- NULL

  # Truncate at the 99th percentile computed separately within each arm.
  # Guard against one arm being absent (e.g., single-arm subsets).
  stop_rows <- out[[arm_col]] == "STOPBASE"
  cont_rows <- !stop_rows
  out$wp99 <- out$w
  if (any(stop_rows)) {
    p99_stop <- stats::quantile(out$w[stop_rows], 0.99, na.rm = TRUE)
    out$wp99[stop_rows] <- pmin(out$w[stop_rows], p99_stop)
  }
  if (any(cont_rows)) {
    p99_cont <- stats::quantile(out$w[cont_rows], 0.99, na.rm = TRUE)
    out$wp99[cont_rows] <- pmin(out$w[cont_rows], p99_cont)
  }
  out
}

# Internal helpers --------------------------------------------------------

#' @noRd
compute_w_stopbase_grp <- function(
    grp, pred_prob_col, month2_col, bc_month_col,
    tslm_lag_col, grace_months) {
  n <- nrow(grp)
  w_vec <- numeric(n)
  running_w <- 1.0
  month_bc <- grp[[bc_month_col]][1L]

  for (j in seq_len(n)) {
    month2 <- grp[[month2_col]][j]
    tslm_lag <- grp[[tslm_lag_col]][j]
    p_pred <- grp[[pred_prob_col]][j]

    # When tslm_lag <= 10, no screening is expected yet
    p_eff <- if (!is.na(tslm_lag) && tslm_lag <= 10L) {
      0.0
    } else {
      if (is.na(p_pred)) 0.0 else p_pred
    }

    if (month2 <= grace_months) {
      running_w <- 1.0
    } else {
      has_bc <- !is.na(month_bc) && month2 >= month_bc
      den <- if (has_bc) 1.0 else max(1.0 - p_eff, 1e-6)
      running_w <- running_w / den
    }
    w_vec[j] <- running_w
  }
  w_vec
}

#' @noRd
compute_w_continue_grp <- function(
    grp, pred_prob_col, scrmammo_col,
    tslm_lag_col, bc_month_col, month2_col) {
  n <- nrow(grp)
  w_vec <- numeric(n)
  running_w <- 1.0
  month_bc <- grp[[bc_month_col]][1L]

  for (j in seq_len(n)) {
    month2 <- grp[[month2_col]][j]
    tslm_lag <- grp[[tslm_lag_col]][j]
    scrmammo <- grp[[scrmammo_col]][j]
    p_pred <- grp[[pred_prob_col]][j]

    # After BC diagnosis, stop updating the weight
    has_bc <- !is.na(month_bc) && month2 >= month_bc

    # Update during the compliance window (tslm_lag 11-13).
    # tslm_lag measures months since the last any-mammogram (screening or
    # diagnostic), so any mammogram resets the compliance window implicitly.
    in_window <- (
      !has_bc &&
        !is.na(tslm_lag) &&
        tslm_lag >= 11L &&
        tslm_lag <= 13L
    )

    if (in_window) {
      tslm_val <- tslm_lag
      # Conditional probability of screening at exactly tslm_val under a
      # discrete uniform distribution over {11, 12, 13}:
      # P(screen at 11 | eligible) = 1/3
      # P(screen at 12 | not at 11) = 1/2
      # P(screen at 13 | not at 11, 12) = 1
      num_screen <- 1.0 / (14L - tslm_val)
      # Treat NA predicted probability as 0 (no predicted screening),
      # consistent with the STOPBASE arm helper.
      p_pred_safe <- if (is.na(p_pred)) 0.0 else p_pred

      if (!is.na(scrmammo) && scrmammo == 1L) {
        # Screened: multiply by P(screen at this month | uniform) / P_model
        den <- max(p_pred_safe, 1e-6)
        running_w <- running_w * num_screen / den
      } else {
        # Not yet screened in this month: multiply by
        # P(no screen at this month | uniform) / P_model(no screen)
        num <- 1.0 - num_screen
        den <- max(1.0 - p_pred_safe, 1e-6)
        running_w <- running_w * num / den
      }
    }
    w_vec[j] <- running_w
  }
  w_vec
}
