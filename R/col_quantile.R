# Column-wise quantile of a bootstrap matrix (one value per month column),
# ignoring failed iterations (NA rows).
col_quantile <- function(mat, prob) {
  apply(mat, 2L, stats::quantile, prob, na.rm = TRUE, names = FALSE)
}
