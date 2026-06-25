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
#' cancer (`bc_died == 0`). When `nc_died_col` is supplied, a negative-control
#' cause-specific outcome `nc_dead_t1` is built the same way from that column.
#' The negative-control outcome (death from cancer of the corpus uteri in
#' García-Albéniz et al.) supports the falsification analysis in
#' [negative_control_analysis()]: continued screening mammography should have
#' no effect on a death unrelated to the breast.
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
#' @param nc_died_col Name of an optional negative-control death indicator
#'   column (e.g., death from cancer of the corpus uteri). When supplied, an
#'   `nc_dead_t1` cause-specific outcome column is added to the output. `NULL`
#'   (the default) omits it.
#'
#' @return A data frame with one row per participant-arm-month, containing:
#'
#'   - `id`: Participant identifier
#'   - `arm`: Trial arm (`"STOPBASE"` or `"CONTINUE"`)
#'   - `month`: Calendar month (integer, same scale as input)
#'   - `month2`: Month relative to trial entry, 0-indexed
#'   - `dead_t1`: Death in the next interval: 1 / 0 / `NA`
#'   - `bc_dead_t1`: Breast cancer death in the next interval
#'   - `bc_long`: Breast cancer diagnosis at this month (0/1)
#'   - `nc_dead_t1`: Negative-control death in the next interval (appended only
#'     when `nc_died_col` is supplied)
#'
#' @seealso [clone_censor()] for the preceding step and
#'   [negative_control_analysis()] for the falsification analysis that consumes
#'   `nc_dead_t1`.
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
    bc_month_col = "bc_month",
    nc_died_col = NULL) {
  add_nc <- !is.null(nc_died_col)
  if (add_nc && !nc_died_col %in% names(data)) {
    cli::cli_abort(c(
      "{.arg nc_died_col} ({.val {nc_died_col}}) not found in {.arg data}.",
      "i" = "Pass the negative-control death column, or {.code NULL}."
    ))
  }

  n <- nrow(data)
  if (n == 0L) {
    out <- data.frame(
      id = integer(0), arm = character(0), month = integer(0),
      month2 = integer(0), dead_t1 = integer(0),
      bc_dead_t1 = integer(0), bc_long = integer(0),
      stringsAsFactors = FALSE
    )
    if (add_nc) out$nc_dead_t1 <- integer(0)
    return(out)
  }

  row_list <- vector("list", n)

  for (i in seq_len(n)) {
    row_list[[i]] <- expand_participant(
      id = data[[id_col]][i],
      arm = data[[arm_col]][i],
      start = data[[start_col]][i],
      end = data[[end_col]][i],
      died = data[[died_col]][i],
      bc_died = data[[bc_died_col]][i],
      bc_month = data[[bc_month_col]][i],
      nc_died = if (add_nc) data[[nc_died_col]][i] else NULL
    )
  }

  out <- do.call(rbind, row_list)
  rownames(out) <- NULL
  out
}

# Build a cause-specific death indicator from the all-cause `dead_t1` vector:
# keep the event row (the trailing 1) only when the death was attributed to
# this cause (`cause_died == 1`), otherwise set it to 0. Censored or surviving
# participants have no event row and are returned unchanged.
cause_specific_dead_t1 <- function(dead_t1, died, end, start, cause_died) {
  out <- dead_t1
  if (died == 1L && end > start && (is.na(cause_died) || cause_died == 0L)) {
    out[length(out)] <- 0L
  }
  out
}

# Expand one participant-arm row to one row per month
expand_participant <- function(
    id, arm, start, end, died, bc_died, bc_month, nc_died = NULL) {
  if (died == 1L && end > start) {
    months <- seq.int(start, end - 1L)
    nrows <- length(months)
    dead_t1 <- c(rep(0L, nrows - 1L), 1L)
  } else {
    months <- seq.int(start, end)
    nrows <- length(months)
    dead_t1 <- c(rep(0L, nrows - 1L), NA_integer_)
  }

  bc_dead_t1 <- cause_specific_dead_t1(dead_t1, died, end, start, bc_died)

  out <- data.frame(
    id = rep(id, nrows),
    arm = rep(arm, nrows),
    month = months,
    month2 = months - start,
    dead_t1 = dead_t1,
    bc_dead_t1 = bc_dead_t1,
    bc_long = as.integer(!is.na(bc_month) & months == bc_month),
    stringsAsFactors = FALSE
  )

  if (!is.null(nc_died)) {
    out$nc_dead_t1 <- cause_specific_dead_t1(dead_t1, died, end, start, nc_died)
  }
  out
}
