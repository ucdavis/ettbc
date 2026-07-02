#' Apply Cohort Eligibility Criteria
#'
#' Selects the participants eligible for entry into the target trial and
#' determines each one's study entry month, following the eligibility
#' criteria of García-Albéniz et al. (2020) (SAS `c01_eligibility.sas`):
#' alive and entitled by age at the age threshold, a qualifying screening
#' mammogram near that age, and twelve months of continuous fee-for-service
#' Medicare enrollment ending at entry.
#'
#' @details
#' Three checks are applied, in order:
#'
#' 1. **Alive and entitled by age.** A participant must be alive when they
#'    reach `agein_month_col` (a `death_month_col` at or after
#'    `agein_month_col`, or missing, still counts as alive at that month),
#'    and `orec_col` must equal `0` (entitled by age, not disability or
#'    end-stage renal disease). A missing `agein_month_col` or `orec_col`
#'    disqualifies the participant.
#' 2. **A qualifying screening mammogram.** The earliest screening mammogram
#'    in the `mammo_window_months`-month window starting at
#'    `agein_month_col` becomes the participant's study entry month
#'    (`start_month`). Participants without one are excluded.
#' 3. **Continuous enrollment.** Every one of the `enrollment_window_months`
#'    months ending at the entry month must have a fee-for-service enrollment
#'    record (`buyin_col` value in `eligible_buyin`) with no HMO enrollment
#'    (`hmo_col` value in `eligible_hmo`). A participant-month absent from
#'    `enrollment`, or one outside these codes, disqualifies the participant.
#'
#' The fee-for-service buy-in codes (`"3"`, `"C"`) and the not-in-an-HMO code
#' (`"0"`) are the Medicare `BUYIN`/`HMOIND` values used directly by
#' `c01_eligibility.sas`.
#'
#' @param demographics A data frame with one row per participant, containing
#'   the participant ID, the month each participant turns the entry age
#'   (`agein_month_col`), month of death (`death_month_col`, `NA` if alive),
#'   and original reason for entitlement (`orec_col`).
#' @param enrollment A data frame with one row per participant-month,
#'   containing the participant ID, calendar month (`enrollment_month_col`),
#'   fee-for-service buy-in code (`buyin_col`), and HMO enrollment indicator
#'   (`hmo_col`). A participant-month absent from `enrollment` is treated as
#'   not enrolled.
#' @param mammograms A data frame of screening mammogram events, containing
#'   the participant ID and event month (`mammo_month_col`).
#' @param id_col Name of the participant ID column in `demographics`,
#'   `enrollment`, and `mammograms`. Default: `"id"`.
#' @param agein_month_col Name of the age-threshold month column in
#'   `demographics`. Default: `"agein_month"`.
#' @param death_month_col Name of the death-month column in `demographics`
#'   (`NA` if alive). Default: `"death_month"`.
#' @param orec_col Name of the original-reason-for-entitlement column in
#'   `demographics`. Default: `"orec"`.
#' @param enrollment_month_col Name of the calendar-month column in
#'   `enrollment`. Default: `"month"`.
#' @param buyin_col Name of the fee-for-service buy-in code column in
#'   `enrollment`. Default: `"buyin"`.
#' @param hmo_col Name of the HMO enrollment indicator column in
#'   `enrollment`. Default: `"hmo"`.
#' @param mammo_month_col Name of the event-month column in `mammograms`.
#'   Default: `"month"`.
#' @param eligible_buyin Buy-in codes that count as fee-for-service Part A+B
#'   enrollment. Default: `c("3", "C")`.
#' @param eligible_hmo HMO indicator value(s) that count as *not* enrolled in
#'   an HMO. Default: `"0"`.
#' @param mammo_window_months Width, in months, of the window starting at
#'   `agein_month_col` in which a screening mammogram qualifies as the entry
#'   event. Default: `12L` (approximating the 365-day window in the original
#'   study).
#' @param enrollment_window_months Number of consecutive months of
#'   enrollment, ending at and including the entry month, required for
#'   eligibility. Default: `12L`.
#'
#' @return A data frame with one row per eligible participant:
#'
#'   - `id`: Participant ID (named as `id_col`).
#'   - `agein_month`: The age-threshold month from `demographics` (named as
#'     `agein_month_col`).
#'   - `start_month`: The derived study entry month (the qualifying screening
#'     mammogram month).
#'
#'   Join this onto the participant's other cohort columns (e.g. `end_month`,
#'   `death_month`, `bc_death`, `bc_month`) to build the `data` input expected
#'   by [clone_censor()].
#'
#' @seealso [clone_censor()] for the step this cohort feeds into, and
#'   [comorbidity_score()] for the comorbidity-adjustment side of cohort
#'   construction.
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
#' # Participant 1 is eligible; participant 2 dies before the age threshold;
#' # participant 3 has no qualifying mammogram in the entry window.
#' demographics <- data.frame(
#'   id = 1:3,
#'   agein_month = c(12, 12, 12),
#'   death_month = c(NA, 5, NA),
#'   orec = c(0, 0, 0)
#' )
#' enrollment <- data.frame(
#'   id = rep(1, 12), month = 1:12, buyin = "3", hmo = "0"
#' )
#' mammograms <- data.frame(id = c(1, 3), month = c(12, 30))
#' apply_eligibility_criteria(demographics, enrollment, mammograms)
apply_eligibility_criteria <- function(
    demographics,
    enrollment,
    mammograms,
    id_col = "id",
    agein_month_col = "agein_month",
    death_month_col = "death_month",
    orec_col = "orec",
    enrollment_month_col = "month",
    buyin_col = "buyin",
    hmo_col = "hmo",
    mammo_month_col = "month",
    eligible_buyin = c("3", "C"),
    eligible_hmo = "0",
    mammo_window_months = 12L,
    enrollment_window_months = 12L) {
  check_eligibility_inputs(
    demographics, enrollment, mammograms,
    id_col, agein_month_col, death_month_col, orec_col,
    enrollment_month_col, buyin_col, hmo_col, mammo_month_col
  )
  mammo_window_months <- check_positive_int(
    mammo_window_months, "mammo_window_months"
  )
  enrollment_window_months <- check_positive_int(
    enrollment_window_months, "enrollment_window_months"
  )

  alive <- alive_and_entitled(
    demographics, id_col, agein_month_col, death_month_col, orec_col
  )

  entry <- first_qualifying_mammogram(
    alive, mammograms, id_col, agein_month_col, mammo_month_col,
    mammo_window_months
  )

  enrolled_ids <- continuously_enrolled(
    entry, enrollment, id_col, enrollment_month_col, buyin_col, hmo_col,
    eligible_buyin, eligible_hmo, enrollment_window_months
  )

  out <- entry[entry[[id_col]] %in% enrolled_ids, , drop = FALSE]
  rownames(out) <- NULL
  out
}
