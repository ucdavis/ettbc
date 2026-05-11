#' Compute False Positive Rates for Histological Evaluations
#'
#' Computes the proportion of histological evaluations (biopsies or
#' lumpectomies) that did **not** lead to a breast cancer diagnosis, stratified
#' by trial arm and screening round (first round versus beyond first round).
#'
#' @details
#' A histological evaluation is classified as a **true positive** if a breast
#' cancer diagnosis is recorded within `window_months` months of the evaluation
#' (in month2 units, inclusive). All other evaluations are **false positives**.
#'
#' Before classification, the following pre-processing steps are applied:
#'
#' - **Censoring filter**: Only evaluations that fall within the observed
#'   follow-up period for the participant-arm are counted.  Evaluations that
#'   occur after the last observed `month2` for a given arm are excluded.
#' - **Deduplication**: Repeat evaluations within `window_months` months of a
#'   prior evaluation (per participant-arm) are dropped so that one diagnostic
#'   episode is not counted multiple times.
#'
#' Evaluations are stratified by period based on the 0-indexed follow-up month
#' (`month2`):
#'
#' - **first_round**: Evaluation `month2` is at or below `first_round_months`.
#' - **beyond_first_round**: Evaluation `month2` exceeds `first_round_months`.
#'
#' @param long_data A data frame in long format (one row per
#'   participant-arm-month), as produced by [expand_to_long()]. Must include
#'   `id_col`, `arm_col`, `month2_col`, and `bc_month_col`.
#' @param hist_data A data frame with one row per histological evaluation
#'   (biopsy or lumpectomy), containing `id_col` and `hist_month2_col`
#'   (0-indexed follow-up month of the evaluation, on the same scale as
#'   `month2_col`).
#' @param id_col Name of the participant identifier column. Default: `"id"`.
#' @param arm_col Name of the trial arm column. Default: `"arm"`.
#' @param month2_col Name of the 0-indexed month-from-entry column in
#'   `long_data`. Default: `"month2"`.
#' @param bc_month_col Name of the column containing the month2 of breast
#'   cancer diagnosis (`NA` if no diagnosis). Default: `"monthBC"`.
#' @param hist_month2_col Name of the 0-indexed evaluation month column in
#'   `hist_data`. Must be on the same scale as `month2_col`.
#'   Default: `"month2"`.
#' @param first_round_months Month2 threshold for defining the first screening
#'   round. Default: `9L`.
#' @param window_months Number of months (in month2 units) after a histological
#'   evaluation during which a breast cancer diagnosis counts as a true
#'   positive. Also used for deduplication: repeat evaluations within this
#'   many months of a prior one are dropped. Default: `6L`.
#'
#' @return A data frame with one row per arm-period combination *that is
#'   observed in the data* (arm-period pairs with no histological evaluations
#'   are omitted), containing:
#'
#'   - `arm`: Trial arm (`"STOPBASE"` or `"CONTINUE"`).
#'   - `period`: Screening period (`"first_round"` or
#'     `"beyond_first_round"`).
#'   - `n_hist`: Total number of histological evaluations (after
#'     deduplication).
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
    hist_month2_col = "month2",
    first_round_months = 9L,
    window_months = 6L) {
  empty_result <- data.frame(
    arm = character(0),
    period = character(0),
    n_hist = integer(0),
    n_positive = integer(0),
    fpr = numeric(0),
    stringsAsFactors = FALSE
  )
  if (nrow(hist_data) == 0L) return(empty_result)

  # Validate arm values up front
  arms <- unique(long_data[[arm_col]])
  bad_arms <- arms[is.na(arms) | !arms %in% c("STOPBASE", "CONTINUE")]
  if (length(bad_arms) > 0L) {
    cli::cli_abort(
      c(
        "Invalid arm value(s) in {.arg long_data}: {.val {bad_arms}}.",
        "i" = "Valid arm values are {.val STOPBASE} and {.val CONTINUE}."
      )
    )
  }

  # Maximum observed month2 per participant-arm (censoring boundary)
  grp_key <- paste(long_data[[id_col]], long_data[[arm_col]], sep = "\x1f")
  max_m2 <- tapply(long_data[[month2_col]], grp_key, max, na.rm = TRUE)
  max_df <- data.frame(
    .grp = names(max_m2),
    .max_month2 = as.numeric(max_m2),
    stringsAsFactors = FALSE
  )

  # One row per id-arm with BC diagnosis month
  bc_only <- unique(long_data[, c(id_col, arm_col, bc_month_col), drop = FALSE])

  # Attach arm info to histological evaluations (one row per id-arm-hist_event)
  arm_only <- unique(long_data[, c(id_col, arm_col), drop = FALSE])
  hist_arm <- merge(hist_data, arm_only, by = id_col)

  # Build the same group key and filter to observed arm-months
  hist_arm$.grp <- paste(hist_arm[[id_col]], hist_arm[[arm_col]], sep = "\x1f")
  hist_arm <- merge(hist_arm, max_df, by = ".grp")
  hist_arm <- hist_arm[
    hist_arm[[hist_month2_col]] <= hist_arm$.max_month2,
    ,
    drop = FALSE
  ]
  hist_arm$.grp <- NULL
  hist_arm$.max_month2 <- NULL

  if (nrow(hist_arm) == 0L) return(empty_result)

  # Deduplicate: per id-arm, drop evaluations within window_months of a prior
  hist_arm <- hist_arm[order(
    hist_arm[[id_col]], hist_arm[[arm_col]],
    hist_arm[[hist_month2_col]]
  ), , drop = FALSE]
  grp_key2 <- paste(hist_arm[[id_col]], hist_arm[[arm_col]], sep = "\x1f")
  hist_arm_list <- split(hist_arm, grp_key2)
  hist_arm_list <- lapply(hist_arm_list, function(grp) {
    keep <- logical(nrow(grp))
    last_kept_month <- -Inf
    for (j in seq_len(nrow(grp))) {
      m <- grp[[hist_month2_col]][j]
      if (m > last_kept_month + window_months || j == 1L) {
        keep[j] <- TRUE
        last_kept_month <- m
      }
    }
    grp[keep, , drop = FALSE]
  })
  hist_arm <- do.call(rbind, hist_arm_list)
  rownames(hist_arm) <- NULL

  if (nrow(hist_arm) == 0L) return(empty_result)

  # Attach BC diagnosis month
  hist_arm <- merge(hist_arm, bc_only, by = c(id_col, arm_col))

  h_m2 <- hist_arm[[hist_month2_col]]
  bc_m2 <- hist_arm[[bc_month_col]]

  # True positive: BC diagnosis within window_months of the evaluation
  hist_arm$positive <- (
    !is.na(bc_m2) & bc_m2 >= h_m2 & bc_m2 <= h_m2 + window_months
  )

  # Period based on 0-indexed follow-up month (month2 scale)
  hist_arm$period <- ifelse(
    h_m2 <= first_round_months,
    "first_round",
    "beyond_first_round"
  )

  grp_key3 <- paste(hist_arm[[arm_col]], hist_arm$period, sep = "\x1f")
  grp_list <- split(hist_arm, grp_key3)

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

  # Guard against empty list (all IDs outside cohort)
  result_list <- Filter(Negate(is.null), result_list)
  if (length(result_list) == 0L) return(empty_result)

  result <- do.call(rbind, result_list)
  rownames(result) <- NULL
  result
}
