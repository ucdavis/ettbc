# Drop repeat histological evaluations within window_months of a prior kept
# evaluation, applied separately within each participant-arm.
deduplicate_evaluations <- function(hist_arm, id_col, arm_col,
                                    hist_month2_col, window_months) {
  hist_arm <- hist_arm[order(
    hist_arm[[id_col]], hist_arm[[arm_col]],
    hist_arm[[hist_month2_col]]
  ), , drop = FALSE]
  grp_key <- paste(hist_arm[[id_col]], hist_arm[[arm_col]], sep = "\x1f")

  kept <- hist_arm |>
    split(grp_key) |>
    lapply(
      keep_thinned_rows,
      hist_month2_col = hist_month2_col, window_months = window_months
    )

  out <- do.call(rbind, kept)
  rownames(out) <- NULL
  out
}
