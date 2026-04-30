#!/usr/bin/env Rscript

# Post-process pkgdown HTML files to add "Other Formats" links
# This script adds links to RevealJS presentations in the pkgdown HTML output

cat("Adding format links to pkgdown articles...\n")
cat(sprintf("Working directory: %s\n", getwd()))

# Find all HTML files in docs/articles that have corresponding RevealJS versions
# Exclude the RevealJS files themselves (those ending with -revealjs.html)
html_files <- list.files(
  path = "docs/articles",
  pattern = "^quarto_.*\\.html$",
  full.names = TRUE
)

# Filter out the revealjs files
html_files <- html_files[!grepl("-revealjs\\.html$", html_files)]

cat(sprintf("Found %d HTML files matching pattern\n", length(html_files)))
if (length(html_files) > 0) {
  cat("Files found:\n")
  cat(paste(" -", html_files, collapse = "\n"), "\n")
}

if (length(html_files) == 0) {
  cat("No HTML files found in docs/articles/\n")
  # List what IS in docs/articles for debugging
  if (dir.exists("docs/articles")) {
    all_files <- list.files("docs/articles", pattern = "\\.html$", full.names = FALSE)
    cat(sprintf("All HTML files in docs/articles: %s\n", paste(all_files, collapse = ", ")))
  } else {
    cat("docs/articles directory does not exist!\n")
  }
  quit(status = 0)
}

# Process each HTML file
for (html_file in html_files) {
  # Extract the base name
  base_name <- sub("\\.html$", "", basename(html_file))
  
  # Check if there's a corresponding RevealJS file
  revealjs_file <- file.path("docs/articles", paste0(base_name, "-revealjs.html"))
  
  cat(sprintf("Checking for RevealJS file: %s\n", revealjs_file))
  
  if (!file.exists(revealjs_file)) {
    cat(sprintf("  RevealJS file not found, skipping %s\n", basename(html_file)))
    next
  }
  
  cat(sprintf("Processing %s...\n", basename(html_file)))
  
  # Read the HTML content
  html_content <- readLines(html_file, warn = FALSE)
  
  # Create the format link HTML
  format_link_html <- sprintf('
<div class="quarto-alternate-formats">
<h2>Other Formats</h2>
<ul>
<li><a href="%s-revealjs.html"><i class="bi bi-file-slides"></i>RevealJS</a></li>
</ul>
</div>', base_name)
  
  # Find the location to insert the link (after the TOC, before main content)
  # Look for the nav closing tag or the main content div
  insert_pos <- NULL
  for (i in seq_along(html_content)) {
    if (grepl('</nav>', html_content[i])) {
      # Check if this is after a TOC by looking backwards
      context <- html_content[max(1, i-50):i]
      if (any(grepl('id="toc"', context, perl = TRUE))) {
        insert_pos <- i
        break
      }
    }
  }
  
  if (is.null(insert_pos)) {
    # Try alternative: find main content div
    for (i in seq_along(html_content)) {
      if (grepl('<main', html_content[i])) {
        insert_pos <- i - 1
        break
      }
    }
  }
  
  if (!is.null(insert_pos)) {
    cat(sprintf("  Inserting format link at position %d\n", insert_pos))
    # Insert the format link
    html_content <- c(
      html_content[1:insert_pos],
      format_link_html,
      html_content[(insert_pos + 1):length(html_content)]
    )
    
    # Write the modified HTML back
    writeLines(html_content, html_file)
    cat(sprintf("  Added RevealJS link to %s\n", basename(html_file)))
  } else {
    cat(sprintf("  Could not find insertion point in %s\n", basename(html_file)))
  }
}

cat("Format link injection complete!\n")
