
<!-- README.md is generated from README.Rmd. Please edit that file -->

# `{rpt}` (<u>R</u> <u>p</u>ackage <u>t</u>emplate)

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/UCD-SERG/rpt/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/UCD-SERG/rpt/actions)
[![Codecov test
coverage](https://codecov.io/gh/UCD-SERG/rpt/branch/main/graph/badge.svg)](https://app.codecov.io/gh/UCD-SERG/rpt)
[![CodeFactor](https://www.codefactor.io/repository/github/ucd-serg/rpt/badge)](https://www.codefactor.io/repository/github/ucd-serg/rpt)
[![CRAN
status](https://www.r-pkg.org/badges/version/rpt)](https://cran.r-project.org/package=rpt)
[![](http://cranlogs.r-pkg.org/badges/grand-total/rpt)](https://cran.r-project.org/package=rpt)
[![](http://cranlogs.r-pkg.org/badges/last-month/rpt)](https://cran.r-project.org/package=rpt)
[![](http://cranlogs.r-pkg.org/badges/last-week/rpt)](https://cran.r-project.org/package=rpt)
[![License:
MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://cran.r-project.org/web/licenses/MIT)

<!-- badges: end -->

The goal of `{rpt}` is to …

## Installation

You can install the development version of `{rpt}` from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("UCD-SERG/rpt")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(rpt)
## basic example code
```

## Development

### Building the Documentation Site

This package uses [altdoc](https://altdoc.etiennebacher.com/) with
[Quarto](https://quarto.org/) to build its documentation site. To build
and preview the documentation locally:

``` r
# Load the package
pkgload::load_all()

# Render the documentation
altdoc::render_docs()

# Preview the site
altdoc::preview_docs()
```

The documentation is automatically built and deployed to GitHub Pages
via GitHub Actions when changes are pushed to the main branch.

## Other R Package Template Options

If you’re looking for alternative R package templates, you may also want
to consider:

- [r.pkg.template](https://github.com/insightsengineering/r.pkg.template/) -
  A comprehensive R package template from Insights Engineering

## Code of Conduct

Please note that the `{rpt}` project is released with a [Contributor
Code of
Conduct](https://contributor-covenant.org/version/2/1/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.
