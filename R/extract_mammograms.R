#' Extract Screening Mammograms from Medicare Claims
#'
#' Filters a Medicare carrier or outpatient claims file to rows containing
#' screening mammography HCPCS codes, and converts claim dates to a 1-indexed
#' study month relative to a reference date.
#'
#' @details
#' This is a **template function** that cannot be run without access to
#' Medicare claims data. It is provided as a reference implementation for
#' users who have access to such data.
#'
#' The default HCPCS codes for screening mammography are:
#'
#' - `"77057"`: Bilateral screening mammography (film)
#' - `"76092"`: Bilateral screening mammography (superseded)
#' - `"G0202"`: Bilateral screening mammography (digital)
#' - `"G0203"`: Bilateral screening mammography (film, FQHC)
#' - `"G0205"`: Bilateral screening mammography (digital, FQHC)
#'
#' @param claims A data frame of Medicare claims. Must contain columns
#'   `id_col`, `date_col`, and `hcpcs_col`.
#' @param id_col Name of the beneficiary identifier column.
#'   Default: `"bene_id"`.
#' @param date_col Name of the service date column (coercible to `Date`).
#'   Default: `"thru_dt"`.
#' @param hcpcs_col Name of the HCPCS procedure code column.
#'   Default: `"hcpcs_cd"`.
#' @param hcpcs_codes Character vector of HCPCS codes identifying screening
#'   mammography claims. Default:
#'   `c("77057", "76092", "G0202", "G0203", "G0205")`.
#' @param ref_date A `Date` object giving the reference date from which study
#'   months are counted (e.g., the first day of the study period).
#' @param study_start_month Integer giving the month index assigned to
#'   `ref_date`. Default: `1L`.
#'
#' @return A data frame with one row per matching claim, containing:
#'
#'   - `id`: Beneficiary identifier (from `id_col`).
#'   - `month`: Study month index (integer, 1-indexed from `ref_date`).
#'
#' @seealso [extract_diagnostic_mammograms()], [extract_any_mammograms()],
#'   [clone_censor()]
#'
#' @references
#' García-Albéniz X, Uno H, Bhatt DL, McArdle PH, Joffe MM, Hernán MA.
#' Continuation of Annual Screening Mammography and Breast Cancer Mortality in
#' Women Older Than 70 Years: A Prospective Observational Study.
#' *Ann Intern Med.* 2020;172(6):381–389. \doi{10.7326/M18-1199}
#'
#' @export
extract_screening_mammograms <- function(
    claims,
    id_col = "bene_id",
    date_col = "thru_dt",
    hcpcs_col = "hcpcs_cd",
    hcpcs_codes = c("77057", "76092", "G0202", "G0203", "G0205"),
    ref_date,
    study_start_month = 1L) {
  extract_mammograms_impl(
    claims, id_col, date_col, hcpcs_col,
    hcpcs_codes, ref_date, study_start_month
  )
}

#' Extract Any Mammograms from Medicare Claims
#'
#' Filters a Medicare carrier or outpatient claims file to rows containing
#' any mammography HCPCS codes (screening or diagnostic), and converts claim
#' dates to a 1-indexed study month relative to a reference date.
#'
#' @details
#' This is a **template function** that cannot be run without access to
#' Medicare claims data. It is provided as a reference implementation for
#' users who have access to such data.
#'
#' The default HCPCS codes cover both screening and diagnostic mammography:
#'
#' - Screening: `"77057"`, `"76092"`, `"G0202"`, `"G0203"`, `"G0205"`
#' - Diagnostic: `"76090"`, `"76091"`, `"G0204"`, `"G0206"`,
#'   `"77055"`, `"77056"`
#'
#' @inheritParams extract_screening_mammograms
#' @param hcpcs_codes Character vector of HCPCS codes identifying any
#'   mammography claims. Default: all screening and diagnostic codes combined.
#'
#' @return A data frame with one row per matching claim, containing:
#'
#'   - `id`: Beneficiary identifier (from `id_col`).
#'   - `month`: Study month index (integer, 1-indexed from `ref_date`).
#'
#' @seealso [extract_screening_mammograms()],
#'   [extract_diagnostic_mammograms()], [clone_censor()]
#'
#' @export
extract_any_mammograms <- function(
    claims,
    id_col = "bene_id",
    date_col = "thru_dt",
    hcpcs_col = "hcpcs_cd",
    hcpcs_codes = c(
      "77057", "76092", "G0202", "G0203", "G0205",
      "76090", "76091", "G0204", "G0206", "77055", "77056"
    ),
    ref_date,
    study_start_month = 1L) {
  extract_mammograms_impl(
    claims, id_col, date_col, hcpcs_col,
    hcpcs_codes, ref_date, study_start_month
  )
}

#' Extract Diagnostic Mammograms from Medicare Claims
#'
#' Filters a Medicare carrier or outpatient claims file to rows containing
#' diagnostic mammography HCPCS codes, and converts claim dates to a 1-indexed
#' study month relative to a reference date.
#'
#' @details
#' This is a **template function** that cannot be run without access to
#' Medicare claims data. It is provided as a reference implementation for
#' users who have access to such data.
#'
#' The default HCPCS codes for diagnostic mammography are:
#'
#' - `"76090"`: Unilateral diagnostic mammography (film)
#' - `"76091"`: Bilateral diagnostic mammography (film)
#' - `"G0204"`: Diagnostic mammography (digital, unilateral)
#' - `"G0206"`: Diagnostic mammography (digital, bilateral)
#' - `"77055"`: Unilateral diagnostic mammography
#' - `"77056"`: Bilateral diagnostic mammography
#'
#' @inheritParams extract_screening_mammograms
#' @param hcpcs_codes Character vector of HCPCS codes identifying diagnostic
#'   mammography claims.
#'   Default: `c("76090", "76091", "G0204", "G0206", "77055", "77056")`.
#'
#' @return A data frame with one row per matching claim, containing:
#'
#'   - `id`: Beneficiary identifier (from `id_col`).
#'   - `month`: Study month index (integer, 1-indexed from `ref_date`).
#'
#' @seealso [extract_screening_mammograms()], [extract_any_mammograms()],
#'   [clone_censor()]
#'
#' @export
extract_diagnostic_mammograms <- function(
    claims,
    id_col = "bene_id",
    date_col = "thru_dt",
    hcpcs_col = "hcpcs_cd",
    hcpcs_codes = c("76090", "76091", "G0204", "G0206", "77055", "77056"),
    ref_date,
    study_start_month = 1L) {
  extract_mammograms_impl(
    claims, id_col, date_col, hcpcs_col,
    hcpcs_codes, ref_date, study_start_month
  )
}

# Internal helper ---------------------------------------------------------

#' @noRd
extract_mammograms_impl <- function(
    claims, id_col, date_col, hcpcs_col, hcpcs_codes,
    ref_date, study_start_month) {
  filtered <- claims[claims[[hcpcs_col]] %in% hcpcs_codes, , drop = FALSE]
  if (nrow(filtered) == 0L) {
    return(data.frame(
      id = integer(0), month = integer(0),
      stringsAsFactors = FALSE
    ))
  }

  svc_date <- as.Date(filtered[[date_col]])
  ref <- as.Date(ref_date)

  ref_year_month <- as.integer(format(ref, "%Y")) * 12L +
    as.integer(format(ref, "%m"))
  svc_year_month <- as.integer(format(svc_date, "%Y")) * 12L +
    as.integer(format(svc_date, "%m"))

  month <- svc_year_month - ref_year_month + study_start_month

  data.frame(
    id = filtered[[id_col]],
    month = month,
    stringsAsFactors = FALSE
  )
}
