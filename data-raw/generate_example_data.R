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
# The simulation functions live in R/ (simulate_cohort(),
# simulate_screening_mammograms(), simulate_diagnostic_mammograms()). Load the
# package first so they are available, then run this script from the package
# root directory:
#   pkgload::load_all()
#   source("data-raw/generate_example_data.R")

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
