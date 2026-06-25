#' Probabilistic Bias Analysis for an Unmeasured Confounder
#'
#' Monte Carlo version of [deterministic_bias_analysis()]: instead of a single
#' set of assumptions, the bias parameters are drawn repeatedly from prior
#' distributions and combined with the sampling uncertainty in the observed risk
#' difference, yielding a simulation interval for the bias-adjusted effect. This
#' ports the probabilistic unmeasured-confounding sensitivity analysis of
#' García-Albéniz et al. (supplementary analysis).
#'
#' @details
#' On each of `n_sim` iterations the function draws the observed risk difference
#' from a normal distribution (`rd`, `rd_se`), draws each bias parameter, and
#' computes the bias-adjusted risk difference
#' `rd_draw - (prev_continue - prev_stopbase) * confounder_effect`. The reported
#' interval is the central `conf_level` percentile range of those draws.
#'
#' Each bias parameter (`prev_continue`, `prev_stopbase`, `confounder_effect`)
#' may be given as a single number (held fixed) or as a length-2 vector
#' `c(min, max)` (drawn from a uniform distribution on that range). Set `rd_se`
#' to `0` to propagate only the bias-parameter uncertainty.
#'
#' @inheritParams deterministic_bias_analysis
#' @param rd_se Standard error of the observed risk difference. Default: `0`
#'   (ignore sampling uncertainty, propagate only the bias parameters).
#' @param prev_continue,prev_stopbase,confounder_effect Either a single value
#'   (fixed) or a length-2 `c(min, max)` uniform range, as described above.
#' @param n_sim Number of Monte Carlo iterations. Default: `1000L`.
#' @param conf_level Width of the reported simulation interval. Default: `0.95`.
#' @param seed Optional integer seed. The caller's RNG state is restored on
#'   exit. Default: `NULL`.
#'
#' @return A named list with `estimate` (median adjusted risk difference),
#'   `conf_low` and `conf_high` (the simulation-interval bounds), `draws` (the
#'   `n_sim` adjusted risk differences), `n_sim`, and `conf_level`.
#'
#' @seealso [deterministic_bias_analysis()] for the single-assumption version.
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
#' probabilistic_bias_analysis(
#'   rd = -0.012,
#'   rd_se = 0.004,
#'   prev_continue = c(0.01, 0.10),
#'   prev_stopbase = 0.05,
#'   confounder_effect = c(0.005, 0.02),
#'   n_sim = 2000,
#'   seed = 1
#' )
probabilistic_bias_analysis <- function(
    rd,
    prev_continue,
    prev_stopbase,
    confounder_effect,
    rd_se = 0,
    n_sim = 1000L,
    conf_level = 0.95,
    seed = NULL) {
  if (length(rd) != 1L || !is.numeric(rd)) {
    cli::cli_abort("{.arg rd} must be a single number.")
  }
  if (length(rd_se) != 1L || !is.numeric(rd_se) || rd_se < 0) {
    cli::cli_abort("{.arg rd_se} must be a single non-negative number.")
  }
  n_sim <- as.integer(n_sim)
  if (length(n_sim) != 1L || is.na(n_sim) || n_sim < 1L) {
    cli::cli_abort("{.arg n_sim} must be a single positive integer.")
  }
  if (length(conf_level) != 1L || conf_level <= 0 || conf_level >= 1) {
    cli::cli_abort("{.arg conf_level} must be a single value in (0, 1).")
  }

  if (!is.null(seed)) {
    has_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    old_seed <- if (has_seed) {
      get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    } else {
      NULL
    }
    on.exit(restore_random_seed(old_seed), add = TRUE)
    set.seed(seed)
  }

  rd_draws <- stats::rnorm(n_sim, mean = rd, sd = rd_se)
  pc <- draw_param(prev_continue, n_sim, "prev_continue")
  ps <- draw_param(prev_stopbase, n_sim, "prev_stopbase")
  eff <- draw_param(confounder_effect, n_sim, "confounder_effect")

  adjusted <- rd_draws - rd_bias(pc, ps, eff)
  alpha <- (1 - conf_level) / 2
  bounds <- stats::quantile(adjusted, c(alpha, 1 - alpha), names = FALSE)

  list(
    estimate = stats::median(adjusted),
    conf_low = bounds[1L],
    conf_high = bounds[2L],
    draws = adjusted,
    n_sim = n_sim,
    conf_level = conf_level
  )
}

# Internal helpers --------------------------------------------------------

# Draw a bias parameter: a single value is held fixed, a length-2 c(min, max)
# is drawn from a uniform distribution. Prevalences are validated to [0, 1].
#' @noRd
draw_param <- function(x, n, name) {
  if (!is.numeric(x) || length(x) < 1L || length(x) > 2L) {
    cli::cli_abort(
      "{.arg {name}} must be a single value or a {.code c(min, max)} range."
    )
  }
  if (grepl("^prev", name)) check_prevalence(x, name)
  if (length(x) == 1L) {
    return(rep(x, n))
  }
  if (x[2L] < x[1L]) {
    cli::cli_abort("{.arg {name}} range must have {.code min <= max}.")
  }
  stats::runif(n, x[1L], x[2L])
}

# Restore (or clear) the caller's .Random.seed, used by the on.exit hook so
# seeding for reproducibility does not perturb the global RNG stream.
#' @noRd
restore_random_seed <- function(old_seed) {
  if (is.null(old_seed)) {
    if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
      rm(".Random.seed", envir = .GlobalEnv)
    }
  } else {
    assign(".Random.seed", old_seed, envir = .GlobalEnv) # nolint: object_name_linter
  }
}
