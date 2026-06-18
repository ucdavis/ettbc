# Generate synthetic example data for the ettbc package
#
# This script creates three small example datasets that mirror the structure
# of the breast cancer screening study data used in García-Albéniz et al.
# (2020), but with entirely simulated (fictitious) values.
#
# Months are indexed relative to the study start:
#   month 1  = January 2000
#   month 108 = December 2008
#
# Run this script from the package root directory:
#   source("data-raw/generate_example_data.R")

# ── Simulation helpers ────────────────────────────────────────────────────────

# Simulate the participant-level cohort.
#
# One row per participant. Entry is restricted to months 1–60 (Jan 2000 –
# Dec 2004) to ensure at least four years of potential follow-up. Roughly 15 %
# of participants die during follow-up; about 2 % die from breast cancer.
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
  extra_bc_idx <- sample(non_die_idx, size = min(n_extra_bc, length(non_die_idx)))
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

# Simulate one participant's screening mammogram months.
#
# Adherers receive roughly annual mammograms (±2 month jitter); non-adherers
# receive zero, one, or two post-entry mammograms. Every participant has a
# pre-entry mammogram (10–14 months before entry) to seed the CONTINUE arm
# compliance window.
simulate_participant_screening <- function(sm, em, adherer, max_month) {
  # Pre-study screening mammogram to initialise the compliance window
  pre <- sm - sample(10L:14L, 1L)
  mammo_months <- pre[pre >= 1L]

  if (adherer) {
    # Annual screeners: approximately every 12 months (±2 month jitter)
    t <- sm + sample(10L:14L, 1L) # first post-entry mammo
    while (t <= em && t <= max_month) {
      mammo_months <- c(mammo_months, t)
      t <- t + 12L + sample(-2L:2L, 1L)
    }
  } else {
    # Non-adherers: zero, one, or two post-entry mammograms
    n_mammo <- sample(0L:2L, 1L)
    if (n_mammo > 0L && em > sm + 3L) {
      extra <- sort(sample(seq.int(sm + 3L, pmin(em, max_month)), size = n_mammo))
      mammo_months <- c(mammo_months, extra)
    }
  }

  unique(mammo_months[mammo_months >= 1L & mammo_months <= max_month])
}

# Simulate screening mammogram events for the whole cohort.
#
# Approximately 80 % of participants are "adherers"; the remaining 20 % are
# "non-adherers". Returns one row per screening mammogram event.
simulate_screening_mammograms <- function(cohort, max_month) {
  n <- nrow(cohort)
  is_adherer <- stats::runif(n) < 0.80

  scr_list <- lapply(seq_len(n), function(i) {
    mammo_months <- simulate_participant_screening(
      sm = cohort$start_month[i],
      em = cohort$end_month[i],
      adherer = is_adherer[i],
      max_month = max_month
    )

    if (length(mammo_months) > 0L) {
      data.frame(
        id = cohort$id[i], month = mammo_months, stringsAsFactors = FALSE
      )
    } else {
      NULL
    }
  })

  scr <- do.call(rbind, Filter(Negate(is.null), scr_list))
  rownames(scr) <- NULL
  scr
}

# Simulate diagnostic mammogram events.
#
# About 20 % of participants receive one diagnostic mammogram during follow-up,
# at least 6 months after trial entry. Returns one row per diagnostic event.
simulate_diagnostic_mammograms <- function(cohort, max_month) {
  n <- nrow(cohort)
  dx_prop <- 0.20
  dx_ids <- sample(seq_len(n), size = round(n * dx_prop))

  dx_list <- lapply(dx_ids, function(i) {
    sm <- cohort$start_month[i]
    em <- cohort$end_month[i]
    if (em > sm + 6L) {
      dx_month <- sample(seq.int(sm + 6L, pmin(em, max_month)), 1L)
      data.frame(id = cohort$id[i], month = dx_month, stringsAsFactors = FALSE)
    } else {
      NULL
    }
  })

  dx <- do.call(rbind, Filter(Negate(is.null), dx_list))
  rownames(dx) <- NULL
  dx
}

# ── Generate and save ─────────────────────────────────────────────────────────

set.seed(2020)

n <- 100L # number of simulated participants
max_month <- 108L # December 2008

cohort <- simulate_cohort(n, max_month)
screening_mammograms <- simulate_screening_mammograms(cohort, max_month)
diagnostic_mammograms <- simulate_diagnostic_mammograms(cohort, max_month)

usethis::use_data(
  cohort,
  screening_mammograms,
  diagnostic_mammograms,
  overwrite = TRUE
)
