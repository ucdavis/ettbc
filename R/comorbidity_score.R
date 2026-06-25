#' Weighted Comorbidity Score
#'
#' Computes a weighted comorbidity score for each person from a set of binary
#' condition indicators and a named vector of per-condition weights. This is the
#' general scoring engine behind the Gagne combined comorbidity score (see
#' [gagne_weights()]); supplying a different `weights` vector computes any other
#' additive comorbidity index from the same condition flags.
#'
#' @details
#' The score for a person is the sum, over the conditions named in `weights`, of
#' the weight times the person's 0/1 indicator for that condition. The
#' comorbidity-mapping step (turning ICD diagnosis codes into the condition
#' indicators) is out of scope here; map codes to flags first --- for example
#' with the [comorbidity](https://CRAN.R-project.org/package=comorbidity)
#' package --- then pass the resulting indicator columns to this function.
#'
#' @param data A data frame with one row per person and a 0/1 (or logical)
#'   indicator column for each condition named in `weights`.
#' @param weights A named numeric vector mapping condition column names to
#'   their weights, e.g. the output of [gagne_weights()].
#' @param na_rm Logical; if `TRUE`, missing indicator values are treated as 0
#'   (condition absent). If `FALSE` (the default), any `NA` in a scored column
#'   is an error.
#'
#' @return A numeric vector with one weighted score per row of `data`.
#'
#' @seealso [gagne_weights()] for the García-Albéniz / Gagne weight set.
#'
#' @references
#' Gagne JJ, Glynn RJ, Avorn J, Levin R, Schneeweiss S. A combined comorbidity
#' score predicted mortality in elderly patients better than existing scores.
#' *J Clin Epidemiol.* 2011;64(7):749-759. \doi{10.1016/j.jclinepi.2010.10.004}
#'
#' @export
#'
#' @examples
#' people <- data.frame(
#'   chf = c(0, 1, 0),
#'   dementia = c(0, 0, 1),
#'   metastatic_cancer = c(0, 0, 1)
#' )
#' w <- c(chf = 2, dementia = 2, metastatic_cancer = 5)
#' comorbidity_score(people, w)
comorbidity_score <- function(data, weights, na_rm = FALSE) {
  named_numeric <- is.numeric(weights) &&
    length(weights) > 0L &&
    !is.null(names(weights)) &&
    all(names(weights) != "")
  if (!named_numeric) {
    cli::cli_abort(
      "{.arg weights} must be a non-empty, fully named numeric vector."
    )
  }
  cols <- names(weights)
  missing_cols <- setdiff(cols, names(data))
  if (length(missing_cols) > 0L) {
    cli::cli_abort(c(
      "{.arg data} is missing condition column{?s}: {.val {missing_cols}}.",
      "i" = "Every name in {.arg weights} must be a column of {.arg data}."
    ))
  }

  mat <- as.matrix(data[cols])
  storage.mode(mat) <- "double"

  if (anyNA(mat)) {
    if (!na_rm) {
      cli::cli_abort(c(
        "Condition indicators contain {.code NA}.",
        "i" = "Set {.code na_rm = TRUE} to treat missing indicators as 0."
      ))
    }
    mat[is.na(mat)] <- 0
  }
  if (any(mat != 0 & mat != 1)) {
    cli::cli_abort("Condition indicators must be 0/1 (or logical).")
  }

  drop(mat %*% weights)
}
