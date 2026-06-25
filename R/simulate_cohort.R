# Simulate the participant-level cohort for the example datasets.
#
# One row per participant. Entry is restricted to months 1-60 (Jan 2000 -
# Dec 2004) to ensure at least four years of potential follow-up. Roughly 15%
# of participants die during follow-up; about 2% die from breast cancer.
# Used by the example-data generation script under data-raw.
#
# When `negative_control = TRUE`, an `nc_death` indicator column is added: a
# small, disjoint subset of the deaths is attributed to the negative-control
# cause (death from cancer of the corpus uteri in Garcia-Albeniz et al.). The
# default (FALSE) draws no extra random numbers and leaves the output
# unchanged, so the shipped example data is reproduced exactly.
simulate_cohort <- function(n, max_month, negative_control = FALSE) {
  ids <- seq_len(n)
  ages <- sample(70L:84L, n, replace = TRUE)
  start_months <- sample(1L:60L, n, replace = TRUE)

  # Approximately 15 % of participants die during follow-up.
  # Time from entry to death is drawn from an exponential with mean 50 months.
  die_prob <- 0.15
  die_flag <- stats::runif(n) < die_prob
  die_lag <- pmin(
    ceiling(stats::rexp(n, rate = 1 / 50)),
    max_month - start_months
  )
  death_months <- ifelse(die_flag, start_months + die_lag, NA_integer_)
  # Ensure death happens at month 2 or later so expand_to_long works cleanly
  death_months <- ifelse(
    !is.na(death_months) & death_months <= start_months,
    start_months + 1L,
    death_months
  )

  admin_end_months <- pmin(
    max_month,
    ifelse(is.na(death_months), max_month, death_months)
  )

  # Breast cancer deaths: ~2 % of all participants, subset of those who die
  die_idx <- which(die_flag)
  n_bc_deaths <- max(1L, round(n * 0.02))
  bc_death_idx <- sample(die_idx, size = min(n_bc_deaths, length(die_idx)))

  bc_deaths <- rep(0L, n)
  bc_deaths[bc_death_idx] <- 1L

  # BC diagnosis months
  bc_months <- rep(NA_integer_, n)

  for (i in bc_death_idx) {
    # bc_death participants always die after entry (death_month >= start + 1L,
    # enforced above), so the diagnosis month is drawn from before the death.
    dm <- death_months[i]
    sm <- start_months[i]
    bc_months[i] <- sample(sm:(dm - 1L), 1L)
  }

  # Additional non-fatal BC diagnoses (~3 %)
  non_die_idx <- setdiff(seq_len(n), die_idx)
  n_extra_bc <- max(1L, round(n * 0.03))
  extra_bc_idx <- sample(
    non_die_idx,
    size = min(n_extra_bc, length(non_die_idx))
  )
  for (i in extra_bc_idx) {
    sm <- start_months[i]
    em <- admin_end_months[i]
    bc_months[i] <- sample(sm:em, 1L)
  }

  out <- data.frame(
    id = ids,
    age = ages,
    start_month = start_months,
    end_month = admin_end_months,
    death_month = death_months,
    bc_death = bc_deaths,
    bc_month = bc_months,
    stringsAsFactors = FALSE
  )

  # Negative-control deaths: a small subset of the (non-breast-cancer) deaths
  # attributed to a cause unrelated to screening. Only drawn when requested, so
  # the default output and RNG stream are untouched.
  if (negative_control) {
    nc_deaths <- rep(0L, n)
    nc_candidates <- setdiff(die_idx, bc_death_idx)
    if (length(nc_candidates) > 0L) {
      n_nc_deaths <- max(1L, round(n * 0.02))
      n_take <- min(n_nc_deaths, length(nc_candidates))
      nc_idx <- nc_candidates[sample.int(length(nc_candidates), n_take)]
      nc_deaths[nc_idx] <- 1L
    }
    out$nc_death <- nc_deaths
  }

  out
}
