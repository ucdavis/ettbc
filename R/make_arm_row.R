# Compute derived columns for a single arm row
make_arm_row <- function(base_row, arm_name, end_col, mend, start, death,
                         bc_death, censor) {
  base_row$arm <- arm_name
  base_row[[end_col]] <- mend
  # Only record censor_month when protocol censoring actually truncated
  # follow-up; NA when death or administrative censoring occurred first.
  base_row$censor_month <- if (!is.na(censor) && censor == mend) {
    censor
  } else {
    NA_integer_
  }
  base_row$fup <- mend - start + 1L
  died <- as.integer(!is.na(death) && death == mend)
  base_row$died <- died
  base_row$bc_died <- as.integer(
    died == 1L && !is.na(bc_death) && bc_death == 1L
  )
  base_row
}
