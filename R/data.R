#' Simulated Breast Cancer Screening Cohort
#'
#' A synthetic dataset of 100 participants illustrating the data structure
#' required by [clone_censor()]. Values are entirely simulated and do not
#' represent real patients.
#'
#' @details
#' Months are numbered consecutively from 1 (January 2000) to 108
#' (December 2008), matching the convention used in the original SAS
#' implementation of García-Albéniz et al. (2020). Participants enter the
#' study between months 1 and 60 (January 2000 – December 2004) to allow
#' adequate follow-up.
#'
#' Approximately 15 % of participants die during follow-up; roughly 2 % die
#' from breast cancer. Administrative censoring occurs at month 108.
#'
#' @format A data frame with 100 rows and 7 columns:
#' \describe{
#'   \item{`id`}{Integer participant identifier (1–100).}
#'   \item{`age`}{Age at study entry (70–84 years).}
#'   \item{`start_month`}{Month of trial entry (1–60).}
#'   \item{`end_month`}{Last follow-up month, equal to the minimum of the
#'     death month and the administrative end of study (month 108).}
#'   \item{`death_month`}{Month of all-cause death; `NA` if alive at last
#'     follow-up.}
#'   \item{`bc_death`}{Breast cancer death indicator (0/1).}
#'   \item{`bc_month`}{Month of breast cancer diagnosis; `NA` if no
#'     diagnosis during follow-up.}
#' }
#'
#' @seealso [clone_censor()], [screening_mammograms], [diagnostic_mammograms]
#'
#' @references
#' García-Albéniz X, Uno H, Bhatt DL, McArdle PH, Joffe MM, Hernán MA.
#' Continuation of Annual Screening Mammography and Breast Cancer Mortality in
#' Women Older Than 70 Years: A Prospective Observational Study.
#' *Ann Intern Med.* 2020;172(6):381–389. \doi{10.7326/M18-1199}
#'
#' @examples
#' head(cohort)
"cohort"

#' Simulated Screening Mammogram Events
#'
#' A synthetic dataset of screening mammogram events for the participants in
#' [cohort]. Values are entirely simulated.
#'
#' @details
#' Approximately 80 % of participants are "adherers" who receive roughly annual
#' screening mammograms. A pre-entry mammogram (10–14 months before trial
#' entry) is included for each participant to seed the CONTINUE arm compliance
#' window in [clone_censor()].
#'
#' @format A data frame with one row per screening mammogram event, with
#' 2 columns:
#' \describe{
#'   \item{`id`}{Participant identifier, matching [cohort]`$id`.}
#'   \item{`month`}{Month of screening mammogram (1–108).}
#' }
#'
#' @seealso [clone_censor()], [cohort], [diagnostic_mammograms]
#'
#' @examples
#' head(screening_mammograms)
"screening_mammograms"

#' Simulated Diagnostic Mammogram Events
#'
#' A synthetic dataset of diagnostic mammogram events for approximately 20 %
#' of the participants in [cohort]. Values are entirely simulated.
#'
#' @format A data frame with one row per diagnostic mammogram event, with
#' 2 columns:
#' \describe{
#'   \item{`id`}{Participant identifier, matching [cohort]`$id`.}
#'   \item{`month`}{Month of diagnostic mammogram (1–108).}
#' }
#'
#' @seealso [clone_censor()], [cohort], [screening_mammograms]
#'
#' @examples
#' head(diagnostic_mammograms)
"diagnostic_mammograms"
