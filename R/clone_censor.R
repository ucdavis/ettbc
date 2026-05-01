#' Clone and Censor Participants for Target Trial Emulation
#'
#' Creates two clones of each participant — one assigned to each of two
#' hypothetical trial arms — and applies the corresponding censoring rules.
#' This implements the "clone-censor" step of the target trial emulation
#' methodology described in García-Albéniz et al. (2020).
#'
#' @details
#' Each participant is cloned into two arms:
#'
#' - **STOPBASE**: The clone is censored the first time the participant receives
#'   a screening mammogram after the initial grace period
#'   (`stop_grace_months`). Within the grace period, and after a breast cancer
#'   diagnosis, screening mammograms do not trigger censoring.
#' - **CONTINUE**: The clone is censored the first time the participant goes
#'   longer than `continue_grace_months` months without any mammogram (screening
#'   or diagnostic). Breast cancer diagnosis prevents censoring.
#'
#' Months are numbered as consecutive integers starting from 1 (representing
#' the first month of the study period), matching the convention used in the
#' original SAS implementation.
#'
#' @param data A data frame with one row per participant, containing columns
#'   for participant ID, study entry month, last follow-up month, death month,
#'   breast cancer death indicator, and breast cancer diagnosis month.
#' @param scr_mammo A data frame with one row per screening mammogram event,
#'   containing columns for participant ID and event month.
#' @param dx_mammo A data frame with one row per diagnostic mammogram event,
#'   containing columns for participant ID and event month.
#' @param id_col Name of the participant ID column in `data`, `scr_mammo`, and
#'   `dx_mammo`. Default: `"id"`.
#' @param start_col Name of the study entry month column in `data`.
#'   Default: `"start_month"`.
#' @param end_col Name of the last follow-up month column in `data`
#'   (administrative censoring, e.g., end of study or loss to follow-up).
#'   Default: `"end_month"`.
#' @param death_col Name of the death month column in `data`
#'   (`NA` if alive at end of follow-up). Default: `"death_month"`.
#' @param bc_death_col Name of the breast cancer death indicator column in
#'   `data` (0/1). Default: `"bc_death"`.
#' @param bc_month_col Name of the breast cancer diagnosis month column in
#'   `data` (`NA` if no diagnosis). Default: `"bc_month"`.
#' @param mammo_month_col Name of the mammogram month column in `scr_mammo`
#'   and `dx_mammo`. Default: `"month"`.
#' @param stop_grace_months Number of months after study entry during which a
#'   screening mammogram does not trigger censoring in the STOPBASE arm.
#'   Default: `9`.
#' @param continue_grace_months Length of the compliance window (in months) in
#'   the CONTINUE arm. A participant remains on-protocol for this many months
#'   following any mammogram (screening or diagnostic). Default: `13`.
#' @param total_months Total number of months in the study period.
#'   Default: `108` (corresponding to January 2000 through December 2008).
#'
#' @return A data frame with two rows per participant (one per arm), containing
#'   all columns from `data` plus:
#'   \describe{
#'     \item{`arm`}{Trial arm: `"STOPBASE"` or `"CONTINUE"`}
#'     \item{`end_month`}{Last observed month (minimum of death, administrative
#'       censoring, and protocol censoring). Overwrites the input `end_col`
#'       column.}
#'     \item{`censor_month`}{Month of protocol deviation censoring,
#'       or `NA` if the participant was not censored for protocol
#'       non-adherence.}
#'     \item{`fup`}{Follow-up time in months (`end_month - start_month + 1`).}
#'     \item{`died`}{Overall mortality indicator (0/1): 1 if death was the
#'       reason for ending follow-up.}
#'     \item{`bc_died`}{Breast cancer mortality indicator (0/1).}
#'   }
#'
#' @seealso [expand_to_long()] for expanding the cloned dataset to one row per
#'   participant-arm-month.
#'
#' @references
#' García-Albéniz X, Uno H, Bhatt DL, McArdle PH, Joffe MM, Hernán MA.
#' Continuation of Annual Screening Mammography and Breast Cancer Mortality in
#' Women Older Than 70 Years: A Prospective Observational Study.
#' *Ann Intern Med.* 2020;172(6):381–389. \doi{10.7326/M18-1199}
#'
#' Hernán MA, Robins JM. Using Big Data to Emulate a Target Trial When a
#' Randomized Trial Is Not Available. *Am J Epidemiol.*
#' 2016;183(8):758–764. \doi{10.1093/aje/kwv254}
#'
#' @export
#'
#' @examples
#' cloned <- clone_censor(
#'   cohort,
#'   screening_mammograms,
#'   diagnostic_mammograms
#' )
#' head(cloned)
clone_censor <- function(
    data,
    scr_mammo,
    dx_mammo,
    id_col = "id",
    start_col = "start_month",
    end_col = "end_month",
    death_col = "death_month",
    bc_death_col = "bc_death",
    bc_month_col = "bc_month",
    mammo_month_col = "month",
    stop_grace_months = 9L,
    continue_grace_months = 13L,
    total_months = 108L) {
  ids <- data[[id_col]]
  starts <- data[[start_col]]
  admin_ends <- data[[end_col]]
  deaths <- data[[death_col]]
  bc_deaths <- data[[bc_death_col]]
  bc_months <- data[[bc_month_col]]

  n <- nrow(data)

  # Build per-participant mammography month lookup
  scr_by_id <- split(scr_mammo[[mammo_month_col]], scr_mammo[[id_col]])
  dx_by_id <- split(dx_mammo[[mammo_month_col]], dx_mammo[[id_col]])

  stop_rows <- vector("list", n)
  cont_rows <- vector("list", n)

  for (i in seq_len(n)) {
    pid <- ids[i]
    start <- starts[i]
    admin_end <- admin_ends[i]
    death <- deaths[i]
    bc_death <- bc_deaths[i]
    bc_month <- bc_months[i]

    scr <- scr_by_id[[as.character(pid)]]
    dx <- dx_by_id[[as.character(pid)]]
    if (is.null(scr)) scr <- integer(0)
    if (is.null(dx)) dx <- integer(0)

    # ---- STOPBASE arm ----
    # Build uncensorable (UCEN) indicator vector
    ucen_stop <- logical(total_months)

    # Uncensorable from breast cancer diagnosis onwards
    if (!is.na(bc_month) && bc_month >= 1L && bc_month <= total_months) {
      ucen_stop[seq.int(bc_month, total_months)] <- TRUE
    }

    # Uncensorable for first stop_grace_months months after entry
    grace_stop <- min(start + stop_grace_months, total_months)
    ucen_stop[seq.int(start, grace_stop)] <- TRUE

    # Find first censoring month: first screening mammo outside grace period
    censor_stop <- NA_integer_
    for (m in seq.int(start + 1L, total_months)) {
      if (m %in% scr && !ucen_stop[m]) {
        censor_stop <- m
        break
      }
    }

    mend_stop <- min(
      if (!is.na(death)) death else Inf,
      admin_end,
      if (!is.na(censor_stop)) censor_stop else Inf
    )
    died_stop <- as.integer(!is.na(death) && death == mend_stop)
    bc_died_stop <- as.integer(
      died_stop == 1L && !is.na(bc_death) && bc_death == 1L
    )

    # ---- CONTINUE arm ----
    ucen_cont <- logical(total_months)

    # Uncensorable from breast cancer diagnosis onwards
    if (!is.na(bc_month) && bc_month >= 1L && bc_month <= total_months) {
      ucen_cont[seq.int(bc_month, total_months)] <- TRUE
    }

    # Grace period at entry: uncensorable for continue_grace_months months
    grace_cont <- min(start + continue_grace_months - 1L, total_months)
    ucen_cont[seq.int(start, grace_cont)] <- TRUE

    # Uncensorable for continue_grace_months months following each dx mammo
    for (m in dx) {
      if (m >= 1L && m <= total_months) {
        grace_dx <- min(m + continue_grace_months, total_months)
        ucen_cont[seq.int(m, grace_dx)] <- TRUE
      }
    }

    # Uncensorable for continue_grace_months months following each scr mammo
    for (m in scr) {
      if (m >= 1L && m <= total_months) {
        grace_scr <- min(m + continue_grace_months, total_months)
        ucen_cont[seq.int(m, grace_scr)] <- TRUE
      }
    }

    # Find first non-compliant month from entry onwards
    censor_cont <- NA_integer_
    for (m in seq.int(start, total_months)) {
      if (!ucen_cont[m]) {
        censor_cont <- m
        break
      }
    }

    mend_cont <- min(
      if (!is.na(death)) death else Inf,
      admin_end,
      if (!is.na(censor_cont)) censor_cont else Inf
    )
    died_cont <- as.integer(!is.na(death) && death == mend_cont)
    bc_died_cont <- as.integer(
      died_cont == 1L && !is.na(bc_death) && bc_death == 1L
    )

    # Build one-row result for each arm, carrying through all input columns
    base_stop <- data[i, , drop = FALSE]
    base_cont <- data[i, , drop = FALSE]

    base_stop$arm <- "STOPBASE"
    base_stop[[end_col]] <- mend_stop
    base_stop$censor_month <- censor_stop
    base_stop$fup <- mend_stop - start + 1L
    base_stop$died <- died_stop
    base_stop$bc_died <- bc_died_stop

    base_cont$arm <- "CONTINUE"
    base_cont[[end_col]] <- mend_cont
    base_cont$censor_month <- censor_cont
    base_cont$fup <- mend_cont - start + 1L
    base_cont$died <- died_cont
    base_cont$bc_died <- bc_died_cont

    stop_rows[[i]] <- base_stop
    cont_rows[[i]] <- base_cont
  }

  out <- rbind(
    do.call(rbind, stop_rows),
    do.call(rbind, cont_rows)
  )
  rownames(out) <- NULL
  out
}
