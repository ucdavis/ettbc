#' Expand Cloned Data to Long Format
#'
#' Converts the output of [clone_censor()] from one row per participant-arm to
#' one row per participant-arm-month. The resulting dataset is in a format
#' suitable for discrete-time survival analysis with inverse probability
#' weighting (IPW).
#'
#' @details
#' The binary outcome variable `dead_t1` encodes whether the participant died
#' in the interval from month `t` to month `t+1`:
#' - `0`: alive at `t+1` (confirmed)
#' - `1`: died by `t+1`
#' - `NA`: censored at month `t` (follow-up ends, outcome unknown)
#'
#' For participants who died:
#' - Rows span from `start_month` to `end_month - 1`.
#' - The last row (at `end_month - 1`) has `dead_t1 = 1`.
#' - No row is created for `end_month`.
#'
#' For censored or surviving participants:
#' - Rows span from `start_month` to `end_month`.
#' - The last row (at `end_month`) has `dead_t1 = NA`.
#' - All prior rows have `dead_t1 = 0`.
#'
#' If a participant died in the same month they entered the study
#' (`end_month == start_month` and `died == 1`), `dead_t1` is set to `NA`
#' (outcome indeterminate within a single month).
#'
#' The breast-cancer-specific outcome `bc_dead_t1` mirrors `dead_t1` but is
#' set to `0` at the event row when the death was not attributed to breast
#' cancer (`bc_died == 0`).
#'
#' @param data Output from [clone_censor()], or any data frame with the same
#'   structure. Must contain columns `id`, `arm`, `start_month`, `end_month`,
#'   `died`, `bc_died`, and `bc_month` (or as specified via `*_col` arguments).
#' @param id_col Name of the participant ID column. Default: `"id"`.
#' @param arm_col Name of the trial arm column. Default: `"arm"`.
#' @param start_col Name of the start month column. Default: `"start_month"`.
#' @param end_col Name of the end month column. Default: `"end_month"`.
#' @param died_col Name of the overall death indicator column.
#'   Default: `"died"`.
#' @param bc_died_col Name of the breast cancer death indicator column.
#'   Default: `"bc_died"`.
#' @param bc_month_col Name of the breast cancer diagnosis month column.
#'   Default: `"bc_month"`.
#'
#' @return A data frame with one row per participant-arm-month, containing:
#'   \describe{
#'     \item{`id`}{Participant identifier}
#'     \item{`arm`}{Trial arm (`"STOPBASE"` or `"CONTINUE"`)}
#'     \item{`month`}{Calendar month (integer, same scale as input)}
#'     \item{`month2`}{Month relative to trial entry, 0-indexed}
#'     \item{`dead_t1`}{Death in the next interval: 1 / 0 / `NA`}
#'     \item{`bc_dead_t1`}{Breast cancer death in the next interval}
#'     \item{`bc_long`}{Breast cancer diagnosis at this month (0/1)}
#'   }
#'
#' @seealso [clone_censor()] for the preceding step.
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
#' cloned <- clone_censor(
#'   cohort,
#'   screening_mammograms,
#'   diagnostic_mammograms
#' )
#' long_data <- expand_to_long(cloned)
#' head(long_data)
expand_to_long <- function(
    data,
    id_col = "id",
    arm_col = "arm",
    start_col = "start_month",
    end_col = "end_month",
    died_col = "died",
    bc_died_col = "bc_died",
    bc_month_col = "bc_month") {
  n <- nrow(data)
  row_list <- vector("list", n)

  for (i in seq_len(n)) {
    start <- data[[start_col]][i]
    end <- data[[end_col]][i]
    died <- data[[died_col]][i]
    bc_died <- data[[bc_died_col]][i]
    bc_month <- data[[bc_month_col]][i]

    if (died == 1L && end > start) {
      # Participant died: rows from start to end-1, dead_t1 = 1 at end-1
      months <- seq.int(start, end - 1L)
      nrows <- length(months)
      dead_t1 <- c(rep(0L, nrows - 1L), 1L)
    } else {
      # Censored or died in entry month: rows from start to end,
      # dead_t1 = NA at end
      months <- seq.int(start, end)
      nrows <- length(months)
      dead_t1 <- c(rep(0L, nrows - 1L), NA_integer_)
    }

    # Breast-cancer-specific death indicator
    bc_dead_t1 <- dead_t1
    if (died == 1L && end > start && (is.na(bc_died) || bc_died == 0L)) {
      bc_dead_t1[nrows] <- 0L
    }

    # Breast cancer diagnosis flag
    bc_long <- as.integer(!is.na(bc_month) & months == bc_month)

    row_list[[i]] <- data.frame(
      id = rep(data[[id_col]][i], nrows),
      arm = rep(data[[arm_col]][i], nrows),
      month = months,
      month2 = months - start,
      dead_t1 = dead_t1,
      bc_dead_t1 = bc_dead_t1,
      bc_long = bc_long,
      stringsAsFactors = FALSE
    )
  }

  out <- do.call(rbind, row_list)
  rownames(out) <- NULL
  out
}
