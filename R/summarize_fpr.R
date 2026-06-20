# Mark true positives, assign the screening-round period, and aggregate the
# false positive rate within each arm-by-period group.
summarize_fpr <- function(hist_arm, arm_col, hist_month2_col, bc_month_col,
                          first_round_months, window_months) {
  h_m2 <- hist_arm[[hist_month2_col]]
  bc_m2 <- hist_arm[[bc_month_col]]

  # True positive: BC diagnosis within window_months of the evaluation
  hist_arm$positive <- (
    !is.na(bc_m2) & bc_m2 >= h_m2 & bc_m2 <= h_m2 + window_months
  )

  # Period based on 0-indexed follow-up month (month2 scale)
  hist_arm$period <- ifelse(
    h_m2 <= first_round_months,
    "first_round",
    "beyond_first_round"
  )

  grp_key <- paste(hist_arm[[arm_col]], hist_arm$period, sep = "\x1f")
  # split() never produces empty groups, so each group has at least one row.
  result_list <- hist_arm |>
    split(grp_key) |>
    lapply(fpr_group_row, arm_col = arm_col)

  # Seed with the typed empty frame so an empty group list still yields a
  # properly-typed (zero-row) result rather than NULL.
  result <- do.call(rbind, c(list(empty_fp_result()), result_list))
  rownames(result) <- NULL
  result
}
