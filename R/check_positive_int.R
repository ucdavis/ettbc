# Coerce x to a single positive integer, or abort naming arg_name.
#' @noRd
check_positive_int <- function(x, arg_name) {
  x <- suppressWarnings(as.integer(x))
  if (length(x) != 1L || is.na(x) || x < 1L) {
    cli::cli_abort("{.arg {arg_name}} must be a single positive integer.")
  }
  x
}
