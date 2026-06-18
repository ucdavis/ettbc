# Summarise one arm-by-period group into a single false-positive-rate row.
# Used by summarize_fpr().
fpr_group_row <- function(grp, arm_col) {
  n_hist <- nrow(grp)
  n_pos <- sum(grp$positive, na.rm = TRUE)
  data.frame(
    arm = grp[[arm_col]][1L],
    period = grp$period[1L],
    n_hist = n_hist,
    n_positive = n_pos,
    fpr = 1.0 - n_pos / n_hist,
    stringsAsFactors = FALSE
  )
}
