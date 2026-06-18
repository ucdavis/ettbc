# Find first non-compliant month in CONTINUE arm
find_cont_censor <- function(ucen_cont, start, total_months) {
  for (m in seq.int(start, total_months)) {
    if (!ucen_cont[m]) return(m)
  }
  NA_integer_
}
