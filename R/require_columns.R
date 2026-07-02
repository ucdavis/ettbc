# Abort if any of `required` is missing from `data`, naming `arg_name` in the
# error so the caller knows which argument was underspecified.
#' @noRd
require_columns <- function(data, required, arg_name) {
  missing_cols <- setdiff(required, names(data))
  if (length(missing_cols) > 0L) {
    cli::cli_abort(
      "{.arg {arg_name}} is missing column{?s}: {.val {missing_cols}}."
    )
  }
}
