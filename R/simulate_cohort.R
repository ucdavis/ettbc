# Simulate the participant-level cohort for the example datasets.
#
# One row per participant. Entry is restricted to months 1-60 (Jan 2000 -
# Dec 2004) to ensure at least four years of potential follow-up. Roughly 15%
# of participants die during follow-up; about 2% die from breast cancer.
# Used by the example-data generation script under data-raw.
simulate_cohort <- function(n, max_month) {
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
    dm <- death_months[i]
    sm <- start_months[i]
    if (!is.na(dm) && dm > sm) {
      bc_months[i] <- sample(sm:(dm - 1L), 1L)
    } else {
      bc_months[i] <- sm
    }
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

  data.frame(
    id = ids,
    age = ages,
    start_month = start_months,
    end_month = admin_end_months,
    death_month = death_months,
    bc_death = bc_deaths,
    bc_month = bc_months,
    stringsAsFactors = FALSE
  )
}
