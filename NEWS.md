# ettbc (development version)

* Applied fifth-round review feedback to analysis helpers:
  - `compute_ipw_weights()`: corrected CONTINUE-arm weight logic —
    (a) the weight now updates at every month in the compliance window
    (`tslm_lag` 11–13), not only when `scrmammo == 1`;
    (b) the numerator now uses conditional probabilities under the discrete
    uniform distribution (1/3 at month 11, 1/2 at month 12, 1 at month 13),
    matching the SAS `cann17b` logic instead of cumulative probabilities;
    (c) weight updates stop after a breast-cancer diagnosis (`bc_month_col`
    and `month2_col` are now passed to the internal `compute_w_continue_grp()`
    helper).
  - `fit_outcome_hr()`: added single-arm guard using `check_both_arms()` on
    both the raw input and the filtered model data, consistent with the
    `predict_survival_*` helpers.
  - `predict_survival_unadjusted()`, `predict_survival_baseline_adjusted()`,
    `predict_survival_ipw()`: `check_both_arms()` is now also called on the
    filtered `fit_data` (after `max_month` and `NA` outcome filtering) to
    catch cases where filtering removes all rows for one arm.

* Applied fourth-round review feedback to analysis helpers:
  - `false_positives()`: updated `@return` documentation to clarify that
    arm-period combinations with no histological evaluations are omitted from
    the result.
  - `predict_survival_unadjusted()`, `predict_survival_baseline_adjusted()`,
    and `predict_survival_ipw()`: added an explicit guard that errors with a
    clear message when only one trial arm is present in `long_data`, since the
    pooled logistic regression is rank-deficient without both arms.
  - `NEWS.md`: corrected stale reference to `anymammo_col` in first-round
    entry; the CONTINUE arm helper uses `tslm_lag` for compliance-window reset
    detection (not a separate `anymammo_col` parameter).

* Applied third-round review feedback to analysis helpers:
  - `bootstrap_ci()`: `set.seed()` now saves and restores the caller's RNG
    state on exit so that seeding is confined to this function call.
    `col_quantile()` now passes `names = FALSE` to `stats::quantile()` so
    `apply()` always returns a plain numeric vector instead of a named 1×N
    matrix.
  - `compute_ipw_weights()`: removed the `anymammo_col` parameter (and
    corresponding `compute_w_continue_grp()` argument) since `tslm_lag`
    already captures compliance-window resets from any mammogram. Updated
    documentation for `tslm_lag_col` to clarify it measures months since the
    last *any* mammogram.

* Applied second-round review feedback to analysis helpers:
  - `fit_outcome_hr()`: fixed doc formula variable names (`month3`/`ns1`/`ns2`);
    clarified that the STOPBASE main-effect OR is the baseline-time ratio from a
    model with arm-by-time interactions; confidence intervals now use Wald
    formula in both the sandwich and fallback branches (consistent named numeric
    vector output).
  - `compute_ipw_weights()`: arm-specific p99 truncation no longer errors when
    only one arm is present in the input.
  - `extract_mammograms_impl()`: empty-result `id` column now preserves the
    type of `claims[[id_col]]` instead of defaulting to `integer(0)`.
  - `bootstrap_ci()`: failed iterations are now counted; a `cli::cli_warn()` is
    issued when the failure rate exceeds `fail_threshold` (new argument, default
    10%). `cli` added to `Imports`.
* Added tests for `predict_survival_baseline_adjusted()` and
  `predict_survival_ipw()` (output structure, empty-data handling, and
  weight-handling).

* Applied review feedback to analysis helpers:
  - `predict_survival_unadjusted()`, `predict_survival_baseline_adjusted()`,
    and `predict_survival_ipw()` now apply `max_month` filtering **before**
    model fitting, matching the SAS `cann15/16/21` implementation. Added
    `id_col` parameter and fixed hardcoded `"id"` column in baseline
    deduplication.
  - `compute_ipw_weights()` now computes separate 99th-percentile truncation
    thresholds for each arm (STOPBASE and CONTINUE). The CONTINUE arm
    helper uses `tslm_lag` to detect compliance-window resets from any
    mammogram (screening or diagnostic), since `tslm_lag` measures months
    since the last any-mammogram.
  - `false_positives()` now filters histological evaluations to within each
    arm's observed follow-up, uses the 0-indexed `month2` for
    first-round/beyond-first-round classification, and deduplicates repeat
    evaluations within `window_months` months per participant-arm. An empty
    result is now returned safely when no events match the cohort.
  - `fit_outcome_hr()` now uses cluster-robust (sandwich) confidence intervals
    when the `sandwich` package is installed (new `cluster_id_col` argument),
    matching the SAS `PROC SURVEYLOGISTIC` cluster-variance approach.
  - `bootstrap_ci()` now returns an NA-filled result for empty input instead
    of erroring.
* Added `sandwich` to `Suggests`.
* Added tests for `false_positives()`, `extract_mammograms()`, and
  `bootstrap_ci()` seed reproducibility and empty-input handling.
* Fixed British spellings in documentation and `NEWS.md` (`stabilised` →
  `stabilized`); added technical terms to spell-check wordlist.

* Added `predict_survival_unadjusted()`, `predict_survival_baseline_adjusted()`,
  and `predict_survival_ipw()`: fit pooled logistic regression models with
  restricted cubic spline time terms and arm-by-time interactions, then
  apply g-computation to produce marginal survival curves for each trial arm
  (#1).
* Added `compute_ipw_weights()`: computes stabilized cumulative IPW weights
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
