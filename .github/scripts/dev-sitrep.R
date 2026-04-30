cat("R version:", R.version.string, "\n\n")

r_version <- paste(R.version$major, R.version$minor, sep = ".")
cat("Checking R version >= 4.1.0... ")
if (getRversion() >= "4.1.0") {
  cat("PASSED (", r_version, ")\n\n", sep = "")
} else {
  cat("FAILED (", r_version, ")\n\n", sep = "")
  stop("R version must be >= 4.1.0")
}

cat("Key installed packages:\n")
key_packages <- c(
  "devtools", "rcmdcheck", "lintr",
  "spelling", "testthat"
)
for (pkg in key_packages) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    cat(
      "  -", pkg, ":",
      as.character(packageVersion(pkg)), "\n"
    )
  } else {
    cat("  -", pkg, ": NOT INSTALLED\n")
  }
}

cat("\nTotal packages installed:",
    nrow(installed.packages()), "\n")
cat("\nDevelopment environment setup complete!\n")
