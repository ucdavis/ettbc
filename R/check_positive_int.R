# Validate x is a single positive whole number and return it as an integer,
# or abort naming arg_name. Rejects non-integer numerics (e.g. 12.9) instead
# of silently truncating them.
#' @noRd
check_positive_int <- function(x, arg_name) {
  is_scalar_number <- length(x) == 1L && is.numeric(x) && !is.na(x)
  is_whole_positive <- is_scalar_number && x == trunc(x) && x >= 1
  if (!is_whole_positive) {
    cli::cli_abort("{.arg {arg_name}} must be a single positive integer.")
  }
  as.integer(x)
}
