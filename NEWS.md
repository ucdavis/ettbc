# ettbc (development version)

* Added `simulate_screening_cohort()`: an exported generator that simulates a
  synthetic cohort of arbitrary size and returns the three linked data frames
  (`cohort`, `screening_mammograms`, `diagnostic_mammograms`) the pipeline
  needs. It wraps the internal generators behind a single seeded random-number
  stream, so `simulate_screening_cohort(100, 108, seed = 2020)` reproduces the
  shipped example datasets exactly; the seed is set locally and the caller's
  `.Random.seed` is restored on exit. The "Using ettbc" article uses it to
  demonstrate the full `clone_censor()` -> `compute_ipw_weights()` ->
  `fit_outcome_hr()` -> `predict_survival_ipw()` -> `bootstrap_ci()` pipeline
  end to end on a larger simulated cohort (#12).
* Added `augment_long_covariates()`: builds the time-varying screening
  covariates the weight and propensity steps need from the long-format data and
  the mammogram events, porting the SAS `cann17b` augmentation. It adds
  `scrmammo`, `dxmammo`, `anymammo`, `tslm`, `tslm_lag`, and `monthBC`, forcing
  a screen at entry, resetting the time-since-last-mammogram clock at any
  mammogram, not counting a screen in the month after a breast-cancer
  diagnosis, and reclassifying a screen within `dx_reclass_months` of the
  previous mammogram as diagnostic (#12).
* Added `fit_screening_propensity()`: fits the pooled logistic
  screening-propensity model (SAS `cann17b` denominator) and returns the
  predicted `p_scrmammo` that `compute_ipw_weights()` consumes. The linear
  predictor uses `tslm_lag` (linear plus a restricted-cubic-spline basis),
  `month2` and `month2^2`, and any user-supplied baseline/time-varying
  covariates; the model is fit on the `tslm_lag >= min_tslm_lag` decision
  window, deduplicated to one row per participant-month. Together with
  `augment_long_covariates()` this lets `clone_censor()` output drive
  `compute_ipw_weights()` end to end without hand-set columns (#12).
* Removed leftover package-template scaffolding: the `example_function()`
  function (and its test and man page), the `quarto_vignette.qmd` and
  `quarto_article.qmd` template-demo vignettes, and the generic `CHECKLIST.md`
  and `USAGE.md` template setup guides. Rewrote `README` (`.Rmd`/`.md`) and the
  "Getting Started" vignette to describe `{ettbc}` and demonstrate the
  `clone_censor()` -> `expand_to_long()` pipeline on the synthetic example
  data, and replaced the placeholder `inst/extdata/README.md`.
* Added `predict_survival_unadjusted()`, `predict_survival_baseline_adjusted()`,
  and `predict_survival_ipw()`: fit pooled logistic regression models with
  restricted cubic spline time terms and arm-by-time interactions, then apply
  g-computation to produce marginal survival curves for each trial arm. Time is
  modeled with a full-rank Harrell restricted-cubic-spline basis (a linear
  `month3` term plus `length(rcs_knots) - 2` nonlinear terms) following the SAS
  `%RCSPLINE` macro, rather than `splines::ns()`, which previously aliased with
  the linear term and left the design rank-deficient. The marginal survival
  curves are unchanged; the spline terms now vanish at month 0, so the
  `fit_outcome_hr()` arm odds ratio is the well-defined contrast at baseline.
  All three functions apply the `max_month` filter before model fitting,
  require both arms to be present (before and after filtering), and validate
  `weight_col` when supplied (#1).
* Added `compute_ipw_weights()`: computes stabilized cumulative IPW weights for
  each participant-arm-month, truncated at the 99th percentile computed
  separately within each arm. CONTINUE-arm weight logic matches the SAS
  `cann17b` implementation: updates occur at every month in the `tslm_lag`
  11–13 compliance window (not only when `scrmammo == 1`), using conditional
  uniform probabilities (1/3, 1/2, 1 at months 11, 12, 13 respectively), and
  stop after a breast-cancer diagnosis (#1).
* Added `fit_outcome_hr()`: fits an IPW-weighted pooled logistic regression and
  returns the odds ratio (hazard ratio approximation) for the STOPBASE arm with
  a 95% Wald CI. Uses cluster-robust variance via `sandwich::vcovCL()` when
  `sandwich` is available (new `cluster_id_col` argument). Validates both
  `weight_col` and `cluster_id_col` before fitting. Added `sandwich` to
  `Suggests` (#1).
* Added `bootstrap_ci()`: nonparametric bootstrap for 95% percentile confidence
  intervals on the IPW-estimated survival difference. Failed iterations are
  counted; a warning is issued when the failure rate exceeds `fail_threshold`
  (default 10%). The caller's RNG state is saved and restored on exit.
  Validates that `n_boot` is a positive integer (#1).
* Added `false_positives()`: computes false positive rates for histological
  evaluations, stratified by trial arm and screening round. Filters evaluations
  to within each arm's observed follow-up and deduplicates repeat evaluations
  within `window_months` per participant-arm (#1).
* Added `extract_screening_mammograms()`, `extract_any_mammograms()`, and
  `extract_diagnostic_mammograms()`: template functions for extracting mammogram
  events from Medicare claims data by HCPCS code (#1).
* Added `cli` to `Imports` in `DESCRIPTION` (the restricted cubic spline basis
  is computed directly, so `splines` is no longer a dependency).

* Added `clone_censor()`: implements the clone-censor step of the target trial
  emulation methodology. Creates two clones per participant (STOPBASE and
  CONTINUE arms) and applies the corresponding censoring rules (#1).
* Added `expand_to_long()`: converts cloned data to one row per
  participant-arm-month for use in discrete-time survival analysis (#1).
* Added example synthetic datasets: `cohort`, `screening_mammograms`, and
  `diagnostic_mammograms` (#1).
* Added vignette article "Using ettbc: Emulating a Target Trial for Breast
  Cancer Screening" (#1).
* Updated `DESCRIPTION` title and description to reflect the package purpose.
* Migrated the `@claude`, Claude review, and `NEWS.md` changelog-check GitHub
  Actions workflows to the reusable workflows in `d-morrison/gha`.
* Internal refactor: decomposed the per-participant clone-censor logic in
  `clone_censor()` into smaller helper functions, factored the cumulative
  mortality computation in the "Using ettbc" vignette into a reusable helper,
  and split the example-data generation into focused simulation functions now
  living in `R/`. Helper functions were reorganized to one function per file,
  anonymous functions replaced with named helpers, and nested calls rewritten
  as pipes. No user-facing behavior changes.

# ettbc 0.0.0.9000

* Initial development version
