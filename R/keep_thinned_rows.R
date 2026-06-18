# Keep one participant-arm group's rows after dropping evaluations that fall
# within window_months of a prior kept one. Rows must be sorted ascending by
# the evaluation month. Used by deduplicate_evaluations().
keep_thinned_rows <- function(grp, hist_month2_col, window_months) {
  keep <- thin_within_window(grp[[hist_month2_col]], window_months)
  grp[keep, , drop = FALSE]
}
