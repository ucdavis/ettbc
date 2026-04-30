# rpt (development version)

* Switched from pkgdown to altdoc for documentation generation. Now using Quarto Website for documentation with native math equation support via MathJax.
* Removed pkgdown-specific configurations and workflows.
* Retained RevealJS multi-format support for Quarto vignettes and articles.
* Fixed index page rendering by switching from `index.md` to `index.qmd` to properly process Quarto include directive (#58)
* Switched from `pkgdown` to `altdoc` (#45)
* Updated lintr configuration to match serodynamics reference with enhanced linter rules
* PR preview comments now use `recreate: true` to ensure they always appear at the bottom of the PR conversation, preventing them from being hidden in collapsed sections (#31)

* Added RevealJS presentation format for Quarto vignettes and articles in pkgdown documentation. HTML pages now display an "Other Formats" section with links to slide versions (#29)

# rpt 0.0.0.9000

* Initial development version
