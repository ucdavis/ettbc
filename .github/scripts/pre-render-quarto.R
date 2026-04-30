#!/usr/bin/env Rscript

# Pre-render script to generate all Quarto formats (HTML + RevealJS)
# This ensures that RevealJS slides are available when pkgdown builds the site

cat("Pre-rendering Quarto documents to all formats...\n")

# Check if quarto package is available
if (!requireNamespace("quarto", quietly = TRUE)) {
  stop("quarto package is required but not installed. Please install it with: install.packages('quarto')")
}

# Find all .qmd files in vignettes (but exclude data-raw)
qmd_files <- list.files(
  path = "vignettes",
  pattern = "\\.qmd$",
  recursive = TRUE,
  full.names = TRUE
)

if (length(qmd_files) == 0) {
  cat("No Quarto (.qmd) files found in vignettes/\n")
  quit(status = 0)
}

# Render each file to all formats
errors <- character()
for (qmd_file in qmd_files) {
  cat(sprintf("Rendering %s...\n", qmd_file))
  tryCatch({
    # Render to all formats specified in the document YAML
    quarto::quarto_render(qmd_file, output_format = "all", quiet = FALSE)
    cat(sprintf("Successfully rendered %s\n", qmd_file))
  }, error = function(e) {
    error_msg <- sprintf("Error rendering %s: %s", qmd_file, e$message)
    cat(error_msg, "\n")
    errors <<- c(errors, error_msg)
  })
}

cat("Pre-rendering complete!\n")

# Exit with error if any renders failed
if (length(errors) > 0) {
  cat("\nErrors occurred during rendering:\n")
  cat(paste(errors, collapse = "\n"), "\n")
  quit(status = 1)
}

