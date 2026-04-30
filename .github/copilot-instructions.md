# Copilot Instructions for R Package Template

## Repository Overview

This is a template repository for creating R packages following UCD-SERG standards.

- **Type**: R package template
- **Language**: R (>= 4.1.0)
- **Key Dependencies**: See DESCRIPTION file

## Setup Requirements

### Copilot Setup Workflow

The repository includes a `.github/workflows/copilot-setup-steps.yml` workflow that automatically configures the GitHub Copilot coding agent's environment with all required dependencies.

#### What the Workflow Does

1. Installs system dependencies (libcurl, libssl, libxml2, graphics libraries)
2. Sets up R (>= 4.1.0)
3. Installs R package dependencies
4. Verifies installation

#### Skipping Setup Steps

For pull requests that primarily edit workflows or other metadata rather than the main R package code, you can add the `skip-cp-setup` label to skip the heavy dependency installation steps. This allows Copilot to install dependencies on-the-fly as needed instead of pre-installing everything.

When the `skip-cp-setup` label is present:
- The workflow will only checkout the repository code
- All dependency installation steps will be skipped
- Copilot can still install specific dependencies as needed during task execution

#### When to Use This Template

1. Clone or use this repository as a template
2. Replace all instances of `packagename` with your actual package name
3. Update DESCRIPTION, README.Rmd, and other files with your package details
4. Add your R functions to `R/` directory
5. Add tests to `tests/testthat/` directory
6. Run `devtools::document()` to generate documentation
7. Run `devtools::check()` to validate your package

## Development Workflow

### Building and Checking

```r
# Install development dependencies
devtools::install_dev_deps()

# Generate documentation
devtools::document()

# Run R CMD check
devtools::check()

# Run tests
devtools::test()

# Build package
devtools::build()
```

### Linting

```r
# Lint the package
lintr::lint_package()
```

### Testing

```r
# Run all tests
devtools::test()

# Run specific test file
devtools::test_file("tests/testthat/test-example_function.R")

# Run tests with coverage
covr::package_coverage()
```

## Local Validation Requirements

**CRITICAL**: Before committing any code changes or requesting review, ALWAYS run the following validation commands locally:

1. **`lintr::lint_package()`** - Check code style and identify linting issues
2. **`devtools::document()`** - Generate/update documentation from roxygen2 comments
3. **`devtools::test()`** - Run all test suites to ensure tests pass
4. **`devtools::check()`** - Run R CMD check to validate package structure and compliance
5. **`altdoc::render_docs(verbose = TRUE)`** - **MANDATORY**: Build the full documentation website locally and inspect the output to ensure all documentation renders correctly, including vignettes, articles, and any special formats (e.g., RevealJS presentations)
6. **`altdoc::preview_docs()`** - **MANDATORY BEFORE REVIEW**: Launch local preview server and visually inspect the rendered documentation in a browser to verify:
   - All equations render correctly (check for LaTeX math symbols, not raw text or HTML)
   - All code blocks display properly with syntax highlighting
   - All images and figures load correctly  
   - All links work (internal and external)
   - Navigation sidebar functions properly
   - Search functionality works

These commands must be run in this order and all must pass without errors before pushing changes or requesting code review. This ensures that CI/CD workflows will pass and prevents wasting reviewer time on fixable issues.

**IMPORTANT**: For changes affecting documentation or vignettes, you MUST build and visually inspect the documentation site output (located in `docs/`) to verify that everything renders as expected. **DO NOT REQUEST REVIEW** until you have personally verified the deployed documentation looks correct in a browser.

### Example Validation Workflow

```r
# Complete validation sequence before committing
devtools::document()              # Update documentation
devtools::test()                  # Verify all tests pass
devtools::check()                 # Run full package check
lintr::lint_package()             # Verify code style
altdoc::render_docs(verbose = TRUE)  # Build altdoc site to verify documentation

# Manually inspect docs/ directory to verify rendering
# Check docs/vignettes/*.md for correct output
# Verify links and images work correctly

# CRITICAL: Preview the site in a browser before requesting review
altdoc::preview_docs()    # Launch preview server
# Open browser and visually verify:
# - Math equations render (not raw LaTeX or HTML)
# - Code blocks have syntax highlighting
# - All images display
# - Navigation works
# - Search works

# Only commit and push if all checks pass AND visual inspection confirms correct rendering
```
# Check docs/vignettes/*.md for correct output
# Verify links and images work correctly

# Only commit and push if all checks pass AND visual inspection confirms correct rendering
```

## Package Structure

- `R/` - R source files
- `tests/testthat/` - Unit tests
- `man/` - Documentation (auto-generated)
- `vignettes/` - Long-form documentation
- `data/` - Package data
- `data-raw/` - Scripts to generate package data
- `inst/` - Additional files to include in the package
- `.github/` - GitHub Actions workflows and templates

## Code Style

- Follow the [tidyverse style guide](https://style.tidyverse.org)
- Use roxygen2 for documentation
- Include tests for all exported functions
- Update NEWS.md for user-facing changes
  - Use the `(#issue_number)` notation to link to issues (e.g., `(#123)`)
  - Use the `(#PR_number)` notation to link to pull requests
  - Use `@username` to credit **external** contributors only (not internal team members)
  - See [R Packages - NEWS.md](https://r-pkgs.org/other-markdown.html#sec-news) for details

## Version Management

**CRITICAL**: Always keep the development version ahead of the main branch version.

- When working on a development branch, ensure the version in `DESCRIPTION` is higher than the version on `main`
- Use the fourth component for development versions (e.g., `0.1.0.9000` for development following `0.1.0` release)
- Before merging to `main`, update to a release version (e.g., `0.1.1`, `0.2.0`, etc.)
- After merging a release to `main`, immediately bump the development version on the development branch

### Version Numbering Guidelines

- **Major version** (X.0.0): Breaking changes, major new features
- **Minor version** (0.X.0): New features, backward compatible
- **Patch version** (0.0.X): Bug fixes, backward compatible
- **Development version** (0.0.0.X): Development work, not released

See [R Packages - Version numbers](https://r-pkgs.org/lifecycle.html#sec-lifecycle-version-number) for details.
### Using Pipes to Emphasize Primary Inputs

Use pipes (`|>` or `%>%`) to emphasize the primary input and make sequences of actions more readable:

- **Use pipes for sequences**: When applying multiple transformations to a single primary object (typically a data frame), use pipes to show the flow of data through the transformations
- **Emphasize the main subject**: Pipes keep the focus on the primary input by placing it at the start of the pipeline
- **Avoid for multiple objects**: Don't use pipes when multiple unrelated objects are involved; use direct function calls or intermediate variables instead
- **Formatting**: 
  - Add a space before the pipe operator
  - Place each step on a new line for multi-step pipelines
  - Indent continuation lines for clarity

**Example:**

```r
# Good: Pipe emphasizes the primary input (iris) and the sequence of transformations
iris |>
  summarize(across(where(is.numeric), mean), .by = Species) |>
  pivot_longer(!Species, names_to = "measure", values_to = "value") |>
  arrange(value)

# Less clear: Nested functions obscure the flow
arrange(
  pivot_longer(
    summarize(iris, across(where(is.numeric), mean), .by = Species),
    !Species, names_to = "measure", values_to = "value"
  ),
  value
)
```

For more details, see the [tidyverse style guide on pipes](https://style.tidyverse.org/pipes.html).

## UCD-SERG Lab Manual

Follow the guidance provided in the [UCD-SERG Lab Manual](https://ucd-serg.github.io/lab-manual/). The corresponding source files are available at [github.com/UCD-SERG/lab-manual](https://github.com/UCD-SERG/lab-manual) if easier to read.

## Communication and Documentation

### Explaining Changes in Pull Requests

When making changes to code or workflows, **proactively explain your reasoning** in commit messages and PR descriptions:

- **For version pinning decisions**: Explain whether you're using floating tags (e.g., `@v2`) vs. specific versions (e.g., `@v2.9.4`) and why
- **For configuration changes**: Explain the rationale behind boolean vs. string values, or other non-obvious choices
- **For workflow modifications**: Describe what problem you're solving and why your approach is the best solution
- **For dependency updates**: Explain why you're updating and what benefits or fixes it brings

**Example:**
Instead of just changing `@v2.9.4` to `@v2`, include in your commit message or PR description:
> "Using @v2 (moving tag) instead of @v2.9.4 (pinned version) to automatically receive bug fixes and updates within the v2 major version while maintaining stability."

This proactive communication prevents reviewers from needing to ask clarifying questions and helps future maintainers understand the decisions made.

## Continuous Integration

The template includes GitHub Actions workflows for:
- R-CMD-check on multiple platforms
- Test coverage reporting
- altdoc documentation deployment
- Spell checking
- Linting
- Version checking
- NEWS.md changelog checking
