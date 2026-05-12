# ettbc (development version)

* Added `predict_survival_unadjusted()`, `predict_survival_baseline_adjusted()`,
  and `predict_survival_ipw()`: fit pooled logistic regression models with
  restricted cubic spline time terms and arm-by-time interactions, then apply
  g-computation to produce marginal survival curves for each trial arm. All
  three functions now apply the `max_month` filter before model fitting,
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
* Added `splines` to `Imports` in `DESCRIPTION`.

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

# ettbc 0.0.0.9000

* Initial development version
