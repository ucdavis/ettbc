#' Simulate a Synthetic Breast Cancer Screening Cohort
#'
#' Generates a synthetic cohort of arbitrary size with the structure required
#' by the `{ettbc}` pipeline: a participant table plus linked screening- and
#' diagnostic-mammogram event tables. The values are entirely simulated and do
#' not represent real patients; the function exists so analyses, examples, and
#' the package vignettes can be demonstrated end to end without Medicare claims.
#'
#' @details
#' The three returned data frames are produced, in order, by the package's
#' internal generators (`simulate_cohort()`,
#' `simulate_screening_mammograms()`, and `simulate_diagnostic_mammograms()`),
#' sharing a single random-number stream. Calling
#' `simulate_screening_cohort(100, 108, seed = 2020)` therefore reproduces the
#' shipped [cohort], [screening_mammograms], and [diagnostic_mammograms]
#' example datasets exactly.
#'
#' Roughly 80% of participants are annual "adherers"; about 15% die during
#' follow-up and about 2% die from breast cancer. Months are numbered
#' consecutively from 1, matching the convention used throughout the package.
#' Each participant has a pre-entry screening mammogram so the CONTINUE arm
#' compliance window is seeded at trial entry.
#'
#' When `seed` is supplied, it is applied with [withr::with_seed()], which
#' restores the caller's `.Random.seed` afterwards, so reproducible simulation
#' does not perturb the surrounding random-number stream.
#'
#' @param n Number of participants to simulate. Default: `100L`.
#' @param max_month Total number of months in the study period. Default:
#'   `108L` (January 2000 through December 2008).
#' @param seed Optional integer seed for reproducibility. `NULL` (the default)
#'   leaves the random-number stream untouched.
#'
#' @return A named list of three linked data frames:
#'
#'   - `cohort`: One row per participant, as documented in [cohort].
#'   - `screening_mammograms`: One row per screening-mammogram event, as
#'     documented in [screening_mammograms].
#'   - `diagnostic_mammograms`: One row per diagnostic-mammogram event, as
#'     documented in [diagnostic_mammograms].
#'
#' @seealso [clone_censor()] for the next step in the pipeline, and [cohort],
#'   [screening_mammograms], [diagnostic_mammograms] for the shipped example
#'   datasets this function reproduces.
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
#' sim <- simulate_screening_cohort(n = 200, seed = 1)
#' nrow(sim$cohort)
#' head(sim$screening_mammograms)
#'
#' cloned <- clone_censor(
#'   sim$cohort, sim$screening_mammograms, sim$diagnostic_mammograms
#' )
#' nrow(cloned)
simulate_screening_cohort <- function(n = 100L, max_month = 108L, seed = NULL) {
  n <- as.integer(n)
  if (length(n) != 1L || is.na(n) || n < 1L) {
    cli::cli_abort("{.arg n} must be a single positive integer.")
  }
  max_month <- as.integer(max_month)
  if (length(max_month) != 1L || is.na(max_month) || max_month < 1L) {
    cli::cli_abort("{.arg max_month} must be a single positive integer.")
  }

  if (is.null(seed)) {
    return(simulate_screening_tables(n, max_month))
  }
  withr::with_seed(seed, simulate_screening_tables(n, max_month))
}

# Build the three linked synthetic tables from one shared RNG stream.
#' @noRd
simulate_screening_tables <- function(n, max_month) {
  cohort <- simulate_cohort(n, max_month)
  screening_mammograms <- simulate_screening_mammograms(cohort, max_month)
  diagnostic_mammograms <- simulate_diagnostic_mammograms(cohort, max_month)
  list(
    cohort = cohort,
    screening_mammograms = screening_mammograms,
    diagnostic_mammograms = diagnostic_mammograms
  )
}
