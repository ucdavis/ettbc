# Evaluate `code` with a locally set random seed, restoring the caller's RNG
# stream afterwards so seeding for reproducibility does not perturb the global
# `.Random.seed`. When `seed` is `NULL`, `code` is evaluated with no seeding.
# Mirrors the save/restore behaviour used in bootstrap_ci() so seed handling is
# consistent across the package.
#' @noRd
with_seed_local <- function(seed, code) {
  if (is.null(seed)) {
    return(code)
  }
  has_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  old_seed <- if (has_seed) {
    get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  } else {
    NULL
  }
  on.exit({
    if (is.null(old_seed)) {
      if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
        rm(".Random.seed", envir = .GlobalEnv)
      }
    } else {
      assign(".Random.seed", old_seed, envir = .GlobalEnv) # nolint: object_name_linter
    }
  }, add = TRUE)
  set.seed(seed)
  code
}
