#' Compute False Positive Rates for Histological Evaluations
#'
#' Computes the proportion of histological evaluations (biopsies or
#' lumpectomies) that did **not** lead to a breast cancer diagnosis, stratified
#' by trial arm and screening round (first round versus beyond first round).
#'
#' @details
#' A histological evaluation is classified as a **true positive** if a breast
#' cancer diagnosis is recorded within `window_months` months of the procedure
#' month (inclusive). All other histological evaluations are classified as
#' **false positives**.
#'
#' Evaluations are stratified by period:
#'
#' - **first_round**: Histological evaluation month (0-indexed) is at or before
#'   `first_round_months`.
#' - **beyond_first_round**: Histological evaluation month exceeds
#'   `first_round_months`.
#'
#' @param long_data A data frame in long format (one row per
#'   participant-arm-month), as produced by [expand_to_long()]. Must include
#'   `id_col`, `arm_col`, and `bc_month_col`.
#' @param hist_data A data frame with one row per histological evaluation
#'   (biopsy or lumpectomy), containing columns `id_col` and `hist_month_col`.
#' @param id_col Name of the participant identifier column. Default: `"id"`.
#' @param arm_col Name of the trial arm column. Default: `"arm"`.
#' @param month2_col Name of the 0-indexed month-from-entry column in
#'   `long_data`. Default: `"month2"`.
#' @param bc_month_col Name of the column containing the month2 of breast
#'   cancer diagnosis (`NA` if no diagnosis). Default: `"monthBC"`.
#' @param hist_month_col Name of the histological evaluation month column in
#'   `hist_data`. Default: `"month"`.
#' @param first_round_months Month threshold (0-indexed) for defining the
#'   first screening round. Default: `9L`.
#' @param window_months Number of months after a histological evaluation during
#'   which a breast cancer diagnosis counts as a true positive. Default: `6L`.
#'
#' @return A data frame with one row per arm-period combination, containing:
#'
#'   - `arm`: Trial arm (`"STOPBASE"` or `"CONTINUE"`).
#'   - `period`: Screening period (`"first_round"` or
#'     `"beyond_first_round"`).
#'   - `n_hist`: Total number of histological evaluations.
#'   - `n_positive`: Number that led to a breast cancer diagnosis.
#'   - `fpr`: False positive rate (`1 - n_positive / n_hist`).
#'
#' @seealso [expand_to_long()]
#'
#' @references
#' García-Albéniz X, Uno H, Bhatt DL, McArdle PH, Joffe MM, Hernán MA.
#' Continuation of Annual Screening Mammography and Breast Cancer Mortality in
#' Women Older Than 70 Years: A Prospective Observational Study.
#' *Ann Intern Med.* 2020;172(6):381–389. \doi{10.7326/M18-1199}
#'
#' @export
false_positives <- function(
    long_data,
    hist_data,
    id_col = "id",
    arm_col = "arm",
    month2_col = "month2",
    bc_month_col = "monthBC",
    hist_month_col = "month",
    first_round_months = 9L,
    window_months = 6L) {
  if (nrow(hist_data) == 0L) {
    return(data.frame(
      arm = character(0),
      period = character(0),
      n_hist = integer(0),
      n_positive = integer(0),
      fpr = numeric(0),
      stringsAsFactors = FALSE
    ))
  }

  # One row per participant-arm with BC diagnosis month
  arm_bc <- unique(long_data[
    , c(id_col, arm_col, bc_month_col),
    drop = FALSE
  ])

  # Attach arm and BC info to histological evaluations
  arm_only <- unique(long_data[, c(id_col, arm_col), drop = FALSE])
  hist_arm <- merge(hist_data, arm_only, by = id_col)
  hist_arm_bc <- merge(hist_arm, arm_bc, by = c(id_col, arm_col))

  h_month <- hist_arm_bc[[hist_month_col]]
  bc_month <- hist_arm_bc[[bc_month_col]]

  # True positive: BC diagnosis within window_months of histological evaluation
  hist_arm_bc$positive <- (
    !is.na(bc_month) &
      bc_month >= h_month &
      bc_month <= h_month + window_months
  )

  hist_arm_bc$period <- ifelse(
    h_month <= first_round_months,
    "first_round",
    "beyond_first_round"
  )

  grp_key <- paste(hist_arm_bc[[arm_col]], hist_arm_bc$period, sep = "\x1f")
  grp_list <- split(hist_arm_bc, grp_key)

  result_list <- lapply(grp_list, function(grp) {
    if (nrow(grp) == 0L) return(NULL)
    n_hist <- nrow(grp)
    n_pos <- sum(grp$positive, na.rm = TRUE)
    data.frame(
      arm = grp[[arm_col]][1L],
      period = grp$period[1L],
      n_hist = n_hist,
      n_positive = n_pos,
      fpr = 1.0 - n_pos / n_hist,
      stringsAsFactors = FALSE
    )
  })

  result <- do.call(rbind, result_list)
  rownames(result) <- NULL
  result
}
