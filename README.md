
<!-- README.md is generated from README.Rmd. Please edit that file -->

# `{ettbc}`

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/ucdavis/ettbc/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/ucdavis/ettbc/actions)
[![Codecov test
coverage](https://codecov.io/gh/ucdavis/ettbc/branch/main/graph/badge.svg)](https://app.codecov.io/gh/ucdavis/ettbc)
[![CodeFactor](https://www.codefactor.io/repository/github/ucdavis/ettbc/badge)](https://www.codefactor.io/repository/github/ucdavis/ettbc)
[![CRAN
status](https://www.r-pkg.org/badges/version/ettbc)](https://cran.r-project.org/package=ettbc)
[![](http://cranlogs.r-pkg.org/badges/grand-total/ettbc)](https://cran.r-project.org/package=ettbc)
[![](http://cranlogs.r-pkg.org/badges/last-month/ettbc)](https://cran.r-project.org/package=ettbc)
[![](http://cranlogs.r-pkg.org/badges/last-week/ettbc)](https://cran.r-project.org/package=ettbc)
[![License:
MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://cran.r-project.org/web/licenses/MIT)

<!-- badges: end -->

The goal of `{ettbc}` is to …

## Installation

You can install the development version of `{ettbc}` from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("ucdavis/ettbc")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(ettbc)
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

## Code of Conduct

Please note that the `{ettbc}` project is released with a [Contributor
Code of
Conduct](https://contributor-covenant.org/version/2/1/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.
