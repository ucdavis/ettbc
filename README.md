<!-- README.md is generated from README.Rmd. Please edit that file -->

# `{ettbc}`

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/ucdavis/ettbc/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/ucdavis/ettbc/actions)
[![Codecov test
coverage](https://codecov.io/gh/ucdavis/ettbc/branch/main/graph/badge.svg)](https://app.codecov.io/gh/ucdavis/ettbc)
[![CodeFactor](https://www.codefactor.io/repository/github/ucdavis/ettbc/badge)](https://www.codefactor.io/repository/github/ucdavis/ettbc)
[![License:
MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://cran.r-project.org/web/licenses/MIT)

<!-- badges: end -->

`{ettbc}` emulates a target trial of screening mammography for breast cancer,
using the **clone-censor-reweight** methodology of [García-Albéniz et al.
(2020)](https://doi.org/10.7326/M18-1199). That study estimated the effect of
continuing (vs. stopping) annual screening mammography on breast cancer
mortality in Medicare beneficiaries older than 70.

The package provides the analytic building blocks of that pipeline:

- `clone_censor()` — clone each participant into the STOPBASE and CONTINUE
  arms and apply each arm’s censoring rule.
- `expand_to_long()` — expand the cloned data to one row per
  participant-arm-month for discrete-time survival analysis.
- `compute_ipw_weights()` — stabilized inverse-probability-of-censoring
  weights.
- `fit_outcome_hr()` — IPW-weighted pooled logistic regression for the arm
  hazard ratio.
- `predict_survival_unadjusted()`, `predict_survival_baseline_adjusted()`,
  `predict_survival_ipw()` — g-computation marginal survival curves.
- `bootstrap_ci()` — percentile bootstrap confidence intervals.
- `false_positives()` — false-positive rates for histological evaluations.
- `extract_screening_mammograms()` and companions — templates for extracting
  mammogram events from Medicare claims by HCPCS code.

The package is experimental and not yet an end-to-end reproduction of the
published analysis; see the open issues for the remaining gaps.

## Installation

You can install the development version of `{ettbc}` from
[GitHub](https://github.com/ucdavis/ettbc) with:

``` r
# install.packages("pak")
pak::pak("ucdavis/ettbc")
```

## Example

`{ettbc}` ships three synthetic datasets (`cohort`, `screening_mammograms`,
`diagnostic_mammograms`) that mimic the structure of the original study data.
The clone-censor step turns the one-row-per-participant cohort into two rows
per participant — one for each trial arm:

``` r
library(ettbc)

cloned <- clone_censor(
  cohort,
  screening_mammograms,
  diagnostic_mammograms
)

nrow(cloned) # two rows per participant
#> [1] 200
head(cloned[, c("id", "arm", "start_month", "end_month", "fup", "bc_died")])
#>   id      arm start_month end_month fup bc_died
#> 1  1 STOPBASE          26        38  13       0
#> 2  2 STOPBASE          33        45  13       0
#> 3  3 STOPBASE          28        42  15       0
#> 4  4 STOPBASE           1        12  12       0
#> 5  5 STOPBASE          17        28  12       0
#> 6  6 STOPBASE          40        52  13       0
```

`expand_to_long()` then prepares the data for the
inverse-probability-weighted survival analysis:

``` r
long <- expand_to_long(cloned)
head(long[, c("id", "arm", "month", "month2", "dead_t1")])
#>   id      arm month month2 dead_t1
#> 1  1 STOPBASE    26      0       0
#> 2  1 STOPBASE    27      1       0
#> 3  1 STOPBASE    28      2       0
#> 4  1 STOPBASE    29      3       0
#> 5  1 STOPBASE    30      4       0
#> 6  1 STOPBASE    31      5       0
```

See the article [“Using
ettbc”](https://ucdavis.github.io/ettbc/articles/using-ettbc.html) for the
full walkthrough.

## Development

### Building the Documentation Site

This package uses [altdoc](https://altdoc.etiennebacher.com/) with
[Quarto](https://quarto.org/) to build its documentation site. To build and
preview the documentation locally:

``` r
# Load the package
pkgload::load_all()

# Render the documentation
altdoc::render_docs()

# Preview the site
altdoc::preview_docs()
```

The documentation is automatically built and deployed to GitHub Pages via
GitHub Actions when changes are pushed to the main branch.

## Code of Conduct

Please note that the `{ettbc}` project is released with a [Contributor Code of
Conduct](https://contributor-covenant.org/version/2/1/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.
