# ettbc (development version)

* Added `predict_survival_unadjusted()`, `predict_survival_baseline_adjusted()`,
  and `predict_survival_ipw()`: fit pooled logistic regression models with
  restricted cubic spline time terms and arm-by-time interactions, then
  apply g-computation to produce marginal survival curves for each trial arm
  (#1).
* Added `compute_ipw_weights()`: computes stabilised cumulative IPW weights
  for each participant-arm-month, with separate weight models for the
  STOPBASE and CONTINUE arms, truncated at the 99th percentile (#1).
* Added `fit_outcome_hr()`: fits an IPW-weighted pooled logistic regression
  and returns the odds ratio (hazard ratio approximation) for the STOPBASE arm
  with 95% confidence interval (#1).
* Added `bootstrap_ci()`: nonparametric bootstrap for 95% percentile
  confidence intervals on the IPW-estimated survival difference (#1).
* Added `false_positives()`: computes false positive rates for histological
  evaluations, stratified by trial arm and screening round (#1).
* Added `extract_screening_mammograms()`, `extract_any_mammograms()`, and
  `extract_diagnostic_mammograms()`: template functions for extracting
  mammogram events from Medicare claims data by HCPCS code (#1).
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
