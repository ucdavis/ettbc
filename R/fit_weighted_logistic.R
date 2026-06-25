#' Fit a Weighted Pooled Logistic Regression
#'
#' Fits a binomial (logit) generalized linear model from a formula and data,
#' optionally weighted by a named column. This is the shared fitting primitive
#' behind the package's IP-weighted models ([fit_outcome_hr()] and
#' [predict_survival_ipw()]): the weighted-GLM step now has a single, tested
#' implementation. It is exported so sibling packages can reuse the same
#' weighted pooled-logistic fit (see the discrete-time outcome-model
#' consolidation discussion in the package's issue tracker).
#'
#' @param data A data frame containing the model variables and, when
#'   `weight_col` is supplied, the weight column.
#' @param formula A model formula passed to [stats::glm()].
#' @param weight_col Name of a numeric weight column in `data`, or `NULL`
#'   (the default) for an unweighted fit.
#'
#' @return The fitted [stats::glm] object (binomial family, logit link).
#'
#' @seealso [fit_outcome_hr()] and [predict_survival_ipw()], which build their
#'   formula and call this function for the fit.
#'
#' @export
#'
#' @examples
#' df <- data.frame(
#'   y = c(0, 1, 0, 1, 1),
#'   x = c(1, 2, 3, 4, 5),
#'   w = c(1, 1, 2, 2, 1)
#' )
#' fit <- fit_weighted_logistic(df, y ~ x, weight_col = "w")
#' coef(fit)
fit_weighted_logistic <- function(data, formula, weight_col = NULL) {
  glm_args <- list(
    formula = formula,
    data = data,
    family = stats::binomial(link = "logit")
  )
  if (!is.null(weight_col)) {
    if (!weight_col %in% names(data)) {
      cli::cli_abort(c(
        "{.arg weight_col} ({.val {weight_col}}) not found in data.",
        "i" = "Ensure the column exists in {.arg data}."
      ))
    }
    w <- data[[weight_col]]
    if (!is.numeric(w)) {
      cli::cli_abort(
        "{.arg weight_col} ({.val {weight_col}}) must be numeric."
      )
    }
    glm_args$weights <- w
  }
  # Non-integer IPW weights make a binomial GLM's weights * y product
  # non-integer, so stats::glm() emits "non-integer #successes in a binomial
  # glm!". The fit is valid; we discard the model-based standard errors anyway
  # (bootstrap_ci() gets its intervals from the bootstrap), so muffle only this
  # expected message and let any other warning (non-convergence, separation)
  # surface.
  withCallingHandlers(
    do.call(stats::glm, glm_args),
    warning = function(w) {
      if (grepl("non-integer #successes", conditionMessage(w), fixed = TRUE)) {
        invokeRestart("muffleWarning")
      }
    }
  )
}
