# Empty false-positive result with the correct column types, returned by the
# guard clauses of false_positives().
empty_fp_result <- function() {
  data.frame(
    arm = character(0),
    period = character(0),
    n_hist = integer(0),
    n_positive = integer(0),
    fpr = numeric(0),
    stringsAsFactors = FALSE
  )
}
