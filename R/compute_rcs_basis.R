#' Compute Restricted Cubic Spline (RCS) Basis
#'
#' Computes the *nonlinear* restricted-cubic-spline basis terms for a numeric
#' vector, following Harrell's truncated-power parameterization as implemented
#' by the SAS `%RCSPLINE` macro. With `k` knots this returns `k - 2` nonlinear
#' terms (named `rcs1`, `rcs2`, ...); the linear term is supplied separately
#' (e.g., the raw time variable in a model formula). Together the linear term
#' and these nonlinear terms form a full-rank basis for the restricted cubic
#' spline (i.e. natural cubic spline) space, avoiding the rank deficiency that
#' arises when a separate linear term is added to a basis (such as
#' [splines::ns()]) that already spans the linear component.
#'
#' Each term is exactly zero for `x` at or below the first knot. In the
#' `{ettbc}` outcome models this means every spline term vanishes at month 0,
#' so the `STOPBASE` main effect in [fit_outcome_hr()] is the arm contrast at
#' baseline.
#'
#' The basis is used internally by [fit_screening_propensity()] and the
#' `predict_survival_*()` functions, and is exported so other packages can
#' reuse the same Harrell parameterization rather than writing it again.
#'
#' @details
#' For knots `t[1] < ... < t[k]`, term `j` (for `j = 1, ..., k - 2`) is
#' `((x - t[j])_+^3 - (x - t[k-1])_+^3 * (t[k] - t[j]) / (t[k] - t[k-1])`
#' `+ (x - t[k])_+^3 * (t[k-1] - t[j]) / (t[k] - t[k-1])) / (t[k] - t[1])^2`,
#' where `(u)_+ = max(u, 0)`. The `n_knots >= 3` guard ensures at least one
#' nonlinear term is produced.
#'
#' @param x Numeric vector of values (e.g., follow-up time).
#' @param rcs_knots Numeric vector with at least 3 elements: first and last are
#'   boundary knots; all intermediate elements are interior knots.
#'
#' @return A matrix with `length(rcs_knots) - 2` columns named `rcs1`, `rcs2`,
#'   ..., one per nonlinear restricted-cubic-spline degree of freedom.
#'   Restricted cubic splines are constrained to be linear beyond the boundary
#'   knots.
#'
#' @seealso [fit_outcome_hr()] and [predict_survival_ipw()], which model time
#'   with this basis.
#'
#' @references
#' Harrell FE. *Regression Modeling Strategies.* Springer; 2015.
#'
#' @export
#'
#' @examples
#' basis <- compute_rcs_basis(0:12, rcs_knots = c(0, 6, 12))
#' head(basis)
#' # Terms vanish at or below the first knot
#' basis[1, ]
compute_rcs_basis <- function(x, rcs_knots) {
  n_knots <- length(rcs_knots)
  if (n_knots < 3L) {
    cli::cli_abort(
      c(
        "{.arg rcs_knots} must have at least 3 elements.",
        "i" = "Provide {.code c(left_boundary, interior_knot, right_boundary)}."
      )
    )
  }
  t_first <- rcs_knots[1L]
  t_last <- rcs_knots[n_knots]
  t_prev <- rcs_knots[n_knots - 1L]
  denom <- t_last - t_prev
  scale <- (t_last - t_first)^2
  cube_pos <- function(u) pmax(u, 0)^3
  n_terms <- n_knots - 2L
  basis <- matrix(0, nrow = length(x), ncol = n_terms)
  for (j in seq_len(n_terms)) {
    t_j <- rcs_knots[j]
    term <- cube_pos(x - t_j) -
      cube_pos(x - t_prev) * (t_last - t_j) / denom +
      cube_pos(x - t_last) * (t_prev - t_j) / denom
    basis[, j] <- term / scale
  }
  colnames(basis) <- paste0("rcs", seq_len(n_terms))
  basis
}
