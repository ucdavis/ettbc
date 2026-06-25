#' Augment Long-Format Data with Mammogram and Time-Since-Last-Mammogram Columns
#'
#' Adds the time-varying screening covariates required by
#' [compute_ipw_weights()] and [fit_screening_propensity()] to long-format
#' data produced by [expand_to_long()]. It merges the observed mammogram
#' events onto each participant-arm-month and derives the screening indicator,
#' the time since the last mammogram, and the breast-cancer diagnosis month.
#'
#' @details
#' The construction follows the SAS `cann17b` long-covariate augmentation. For
#' each participant-arm, with rows ordered by `month2`:
#'
#' 1. `scrmammo` and `dxmammo` are set to 1 in months with a screening or
#'    diagnostic mammogram event, respectively, and 0 otherwise.
#' 2. A screening mammogram is forced at trial entry (`month2 == 0`).
#' 3. `anymammo` is 1 when either a screening or diagnostic mammogram occurred
#'    that month. The time-since-last-mammogram clock is reset by any mammogram.
#' 4. A screening mammogram in the month immediately after a breast-cancer
#'    diagnosis is not counted as screening (`scrmammo` set to 0).
#' 5. `tslm` is the running count of months since the last mammogram (0 in any
#'    month with a mammogram, otherwise the previous value plus 1). `tslm_lag`
#'    is `tslm` from the previous month (`NA` at entry), and is the value used
#'    downstream.
#' 6. A screening mammogram within `dx_reclass_months` months of the previous
#'    mammogram (`tslm_lag <= dx_reclass_months`) is reclassified as diagnostic:
#'    `dxmammo` set to 1 and `scrmammo` set to 0.
#'
#' `monthBC` is the `month2` value at which breast cancer was diagnosed
#' (constant within each participant-arm, `NA` if no diagnosis), derived from
#' the `bc_long` indicator. It is the column [compute_ipw_weights()] expects via
#' its `bc_month_col` argument.
#'
#' @param long_data A data frame in long format (one row per
#'   participant-arm-month), as produced by [expand_to_long()]. Must contain the
#'   `id`, `arm`, `month`, `month2`, and `bc_long` columns (or as specified via
#'   the `*_col` arguments).
#' @param screening_mammograms A data frame of screening mammogram events with
#'   participant ID and calendar month columns.
#' @param diagnostic_mammograms A data frame of diagnostic mammogram events with
#'   participant ID and calendar month columns.
#' @param id_col Name of the participant ID column. Default: `"id"`.
#' @param arm_col Name of the trial arm column. Default: `"arm"`.
#' @param month_col Name of the calendar-month column (same scale as the
#'   mammogram event months). Default: `"month"`.
#' @param month2_col Name of the 0-indexed month-from-entry column.
#'   Default: `"month2"`.
#' @param bc_long_col Name of the per-month breast-cancer-diagnosis indicator
#'   column. Default: `"bc_long"`.
#' @param event_month_col Name of the calendar-month column in the mammogram
#'   event data frames. Default: `"month"`.
#' @param dx_reclass_months A screening mammogram occurring this many months or
#'   fewer after the previous mammogram is reclassified as diagnostic.
#'   Default: `8L`.
#'
#' @return `long_data` with six additional columns:
#'
#'   - `scrmammo`: Screening-mammogram indicator for the month (0/1).
#'   - `dxmammo`: Diagnostic-mammogram indicator for the month (0/1).
#'   - `anymammo`: Any-mammogram indicator for the month (0/1).
#'   - `tslm`: Months since the last mammogram at this month.
#'   - `tslm_lag`: `tslm` from the previous month (`NA` at entry).
#'   - `monthBC`: `month2` of breast-cancer diagnosis (`NA` if none).
#'
#' @seealso [expand_to_long()] for the preceding step,
#'   [fit_screening_propensity()] and [compute_ipw_weights()] for the steps that
#'   consume these columns.
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
#' head(long_data[, c("id", "arm", "month2", "tslm_lag", "monthBC")])
augment_long_covariates <- function(
    long_data,
    screening_mammograms,
    diagnostic_mammograms,
    id_col = "id",
    arm_col = "arm",
    month_col = "month",
    month2_col = "month2",
    bc_long_col = "bc_long",
    event_month_col = "month",
    dx_reclass_months = 8L) {
  required <- c(id_col, arm_col, month_col, month2_col, bc_long_col)
  missing_cols <- setdiff(required, names(long_data))
  if (length(missing_cols) > 0L) {
    cli::cli_abort(c(
      "{.arg long_data} is missing required column{?s}: {.val {missing_cols}}.",
      "i" = "Did you call {.fn expand_to_long} first?"
    ))
  }

  if (nrow(long_data) == 0L) {
    long_data$scrmammo <- integer(0)
    long_data$dxmammo <- integer(0)
    long_data$anymammo <- integer(0)
    long_data$tslm <- integer(0)
    long_data$tslm_lag <- integer(0)
    long_data$monthBC <- integer(0)
    return(long_data)
  }

  scr_keys <- event_keys(screening_mammograms, id_col, event_month_col)
  dx_keys <- event_keys(diagnostic_mammograms, id_col, event_month_col)

  long_data[["..ettbc_row_idx.."]] <- seq_len(nrow(long_data))
  grp_key <- paste(long_data[[id_col]], long_data[[arm_col]], sep = "\x1f")
  d_list <- split(long_data, grp_key)

  d_list <- lapply(d_list, function(grp) {
    augment_long_group(
      grp, scr_keys, dx_keys, id_col, month_col, month2_col,
      bc_long_col, dx_reclass_months
    )
  })

  out <- do.call(rbind, d_list)
  out <- out[order(out[["..ettbc_row_idx.."]]), , drop = FALSE]
  out[["..ettbc_row_idx.."]] <- NULL
  rownames(out) <- NULL
  out
}

# Internal helpers --------------------------------------------------------

# Build a set of "id\x1fmonth" keys for fast membership tests.
#' @noRd
event_keys <- function(events, id_col, event_month_col) {
  if (is.null(events) || nrow(events) == 0L) {
    return(character(0))
  }
  missing_cols <- setdiff(c(id_col, event_month_col), names(events))
  if (length(missing_cols) > 0L) {
    cli::cli_abort(
      "Mammogram event data is missing column{?s}: {.val {missing_cols}}."
    )
  }
  paste(events[[id_col]], events[[event_month_col]], sep = "\x1f")
}

# Augment one participant-arm group, processed in month2 order.
#' @noRd
augment_long_group <- function(
    grp, scr_keys, dx_keys, id_col, month_col, month2_col,
    bc_long_col, dx_reclass_months) {
  grp <- grp[order(grp[[month2_col]]), , drop = FALSE]
  n <- nrow(grp)

  keys <- paste(grp[[id_col]], grp[[month_col]], sep = "\x1f")
  scr0 <- as.integer(keys %in% scr_keys)
  dx0 <- as.integer(keys %in% dx_keys)
  month2 <- grp[[month2_col]]
  bc_long <- grp[[bc_long_col]]

  scrmammo <- integer(n)
  dxmammo <- integer(n)
  anymammo <- integer(n)
  tslm <- integer(n)
  tslm_lag <- integer(n)

  prev_tslm <- NA_integer_
  prev_bc <- 0L

  for (j in seq_len(n)) {
    scr <- scr0[j]
    dx <- dx0[j]
    if (month2[j] == 0L) {
      scr <- 1L
    }
    any_m <- as.integer((scr + dx) > 0L)

    lag_bc <- if (month2[j] == 0L) 0L else prev_bc
    if (lag_bc == 1L && scr == 1L) {
      scr <- 0L
    }

    tslm_j <- if (any_m == 1L) 0L else prev_tslm + 1L
    tslm_lag_j <- if (month2[j] == 0L) NA_integer_ else prev_tslm

    reclass <- (
      !is.na(tslm_lag_j) &&
        tslm_lag_j >= 0L &&
        tslm_lag_j <= dx_reclass_months &&
        scr == 1L
    )
    if (reclass) {
      dx <- 1L
      scr <- 0L
    }

    scrmammo[j] <- scr
    dxmammo[j] <- dx
    anymammo[j] <- any_m
    tslm[j] <- tslm_j
    tslm_lag[j] <- tslm_lag_j

    prev_tslm <- tslm_j
    prev_bc <- if (is.na(bc_long[j])) 0L else as.integer(bc_long[j])
  }

  bc_rows <- which(!is.na(bc_long) & bc_long == 1L)
  month_bc <- if (length(bc_rows) > 0L) month2[bc_rows[1L]] else NA_integer_

  grp$scrmammo <- scrmammo
  grp$dxmammo <- dxmammo
  grp$anymammo <- anymammo
  grp$tslm <- tslm
  grp$tslm_lag <- tslm_lag
  grp$monthBC <- rep(as.integer(month_bc), n)
  grp
}
