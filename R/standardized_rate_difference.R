#' Direct-Standardized Rate Difference Between Arms
#'
#' Computes the difference in a binary outcome rate between the CONTINUE and
#' STOPBASE arms, **directly standardized** to the pooled sample over a set of
#' stratifying variables, with a nonparametric bootstrap percentile confidence
#' interval. This ports the treatment-pattern secondary analyses of
#' García-Albéniz et al. (SAS `cann26`/`cann27`/`cann28`: surgery,
#' chemotherapy, and radiotherapy receipt among screen-detected cancers),
#' which used `PROC STDRATE` (`method = direct`, `effect = diff`) standardized
#' by age and comorbidity.
#'
#' @details
#' For each arm the stratum-specific outcome rate is computed, then averaged
#' using the pooled-sample stratum distribution as the reference (direct
#' standardization). The standardized rate difference is
#' `rate(CONTINUE) - rate(STOPBASE)`. Standardization is restricted to strata
#' present in **both** arms (common support); the reference weights are
#' rescaled to sum to one over those strata. Multiply by `mult` to report a
#' rate per
#' `mult` people (the SAS code used `mult = 100`).
#'
#' The confidence interval is the central `conf_level` percentile range of the
#' standardized rate difference across `n_boot` bootstrap resamples of the rows
#' (reference weights are recomputed on each resample). The caller's RNG state
#' is restored on exit.
#'
#' @param data A data frame with one row per person (or person-arm), containing
#'   the outcome, arm, and stratifying columns.
#' @param outcome_col Name of the binary (0/1) outcome column (e.g., receipt of
#'   surgery within 12 months).
#' @param strata_cols Character vector of stratifying column names (e.g., age
#'   group and comorbidity score) defining the standardization strata.
#' @param arm_col Name of the trial arm column (`"CONTINUE"` / `"STOPBASE"`).
#'   Default: `"arm"`.
#' @param mult Rate multiplier; the rates and their difference are scaled by
#'   this. Default: `1` (proportions). Use `100` to match the SAS output.
#' @param n_boot Number of bootstrap resamples. Default: `500L`.
#' @param conf_level Width of the percentile confidence interval.
#'   Default: `0.95`.
#' @param seed Optional integer seed; the caller's RNG state is restored on
#'   exit. Default: `NULL`.
#'
#' @return A named list with `rate_continue` and `rate_stopbase` (the
#'   standardized arm rates), `diff` (their difference), `conf_low`,
#'   `conf_high`, `n_boot`, and `conf_level`. All rates are scaled by `mult`.
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
#' set.seed(1)
#' n <- 400
#' dat <- data.frame(
#'   arm = rep(c("CONTINUE", "STOPBASE"), each = n / 2),
#'   age_group = sample(c("70-74", "75-84"), n, replace = TRUE),
#'   surgery = rbinom(n, 1, 0.5)
#' )
#' standardized_rate_difference(
#'   dat, "surgery", strata_cols = "age_group", n_boot = 200, seed = 1
#' )
standardized_rate_difference <- function(
    data,
    outcome_col,
    strata_cols,
    arm_col = "arm",
    mult = 1,
    n_boot = 500L,
    conf_level = 0.95,
    seed = NULL) {
  required <- c(outcome_col, arm_col, strata_cols)
  missing_cols <- setdiff(required, names(data))
  if (length(missing_cols) > 0L) {
    cli::cli_abort("{.arg data} is missing column{?s}: {.val {missing_cols}}.")
  }
  if (length(strata_cols) == 0L) {
    cli::cli_abort("{.arg strata_cols} must name at least one column.")
  }
  n_boot <- as.integer(n_boot)
  if (length(n_boot) != 1L || is.na(n_boot) || n_boot < 1L) {
    cli::cli_abort("{.arg n_boot} must be a single positive integer.")
  }
  if (length(conf_level) != 1L || conf_level <= 0 || conf_level >= 1) {
    cli::cli_abort("{.arg conf_level} must be a single value in (0, 1).")
  }

  point <- standardized_diff(data, outcome_col, arm_col, strata_cols, mult)

  boot_args <- list(data, outcome_col, arm_col, strata_cols, mult, n_boot)
  boot_diffs <- if (is.null(seed)) {
    do.call(bootstrap_std_diffs, boot_args)
  } else {
    withr::with_seed(seed, do.call(bootstrap_std_diffs, boot_args))
  }

  alpha <- (1 - conf_level) / 2
  bounds <- stats::quantile(
    boot_diffs, c(alpha, 1 - alpha), na.rm = TRUE, names = FALSE
  )

  list(
    rate_continue = point$rate_continue,
    rate_stopbase = point$rate_stopbase,
    diff = point$diff,
    conf_low = bounds[1L],
    conf_high = bounds[2L],
    n_boot = n_boot,
    conf_level = conf_level
  )
}

# Internal helpers --------------------------------------------------------

# Bootstrap the standardized rate difference: resample rows with replacement
# and recompute the standardized difference (reference weights are recomputed
# on each resample). A resample that has no common-support strata yields NA.
#' @noRd
bootstrap_std_diffs <- function(
    data, outcome_col, arm_col, strata_cols, mult, n_boot) {
  n <- nrow(data)
  boot_diffs <- numeric(n_boot)
  for (b in seq_len(n_boot)) {
    resample <- data[sample.int(n, n, replace = TRUE), , drop = FALSE]
    boot <- tryCatch(
      standardized_diff(resample, outcome_col, arm_col, strata_cols, mult),
      error = function(e) NULL
    )
    boot_diffs[b] <- if (is.null(boot)) NA_real_ else boot$diff
  }
  boot_diffs
}

# Direct-standardized rate difference for one dataset, standardizing to the
# pooled-sample stratum distribution over strata present in both arms.
#' @noRd
standardized_diff <- function(data, outcome_col, arm_col, strata_cols, mult) {
  arm <- data[[arm_col]]
  bad <- unique(arm[is.na(arm) | !arm %in% c("CONTINUE", "STOPBASE")])
  if (length(bad) > 0L) {
    cli::cli_abort(
      c(
        "Invalid arm value(s) in {.arg arm_col}: {.val {bad}}.",
        "i" = "Valid arm values are {.val CONTINUE} and {.val STOPBASE}."
      )
    )
  }
  stratum <- interaction(data[strata_cols], drop = TRUE, sep = "\x1f")

  continue <- arm == "CONTINUE"
  stopbase <- arm == "STOPBASE"
  strata_continue <- unique(stratum[continue])
  strata_stopbase <- unique(stratum[stopbase])
  common <- intersect(strata_continue, strata_stopbase)
  if (length(common) == 0L) {
    cli::cli_abort(
      "No strata are present in both arms; cannot standardize."
    )
  }

  in_common <- stratum %in% common
  ref_counts <- table(stratum[in_common])
  ref_weights <- ref_counts / sum(ref_counts)

  outcome <- data[[outcome_col]]
  rate_continue <- direct_rate(outcome, stratum, continue, ref_weights, common)
  rate_stopbase <- direct_rate(outcome, stratum, stopbase, ref_weights, common)

  list(
    rate_continue = rate_continue * mult,
    rate_stopbase = rate_stopbase * mult,
    diff = (rate_continue - rate_stopbase) * mult
  )
}

# Standardized rate for one arm: stratum means weighted by the reference
# distribution over the common strata.
#' @noRd
direct_rate <- function(outcome, stratum, arm_rows, ref_weights, common) {
  total <- 0
  for (s in common) {
    rows <- arm_rows & stratum == s
    total <- total + ref_weights[[as.character(s)]] * mean(outcome[rows])
  }
  total
}
