# Using This Template

This guide walks you through using this R package template to create your own package.

## Quick Start

1. **Create a new repository from this template**
   - Click "Use this template" on GitHub
   - Name your new repository (e.g., `mypackage`)
   - Clone your new repository

2. **Rename the package**
   
   Replace `packagename` with your actual package name in these files:
   - `DESCRIPTION`
   - `.Rbuildignore`
   - `.gitignore`
   - `README.Rmd`
   - `altdoc/quarto_website.yml` (if needed for customization)
   - `.github/CONTRIBUTING.md`
   - `.github/ISSUE_TEMPLATE/issue_template.md`
   - Rename `packagename.Rproj` to `yourpackage.Rproj`

3. **Update package metadata**
   
   Edit `DESCRIPTION`:
   - Update `Title`, `Version`, `Authors@R`
   - Update `Description`
   - Update `URL` and `BugReports`
   - Add/remove dependencies as needed

4. **Update README**
   
   Edit `README.Rmd`:
   - Update package name and description
   - Add your examples
   - Run `rmarkdown::render("README.Rmd")` to generate README.md

5. **Add your code**
   
   - Add R functions to `R/` directory
   - Add roxygen2 comments above each function
   - Run `devtools::document()` to generate documentation

6. **Add tests**
   
   - Add test files to `tests/testthat/`
   - Name test files `test-*.R`
   - Run `devtools::test()` to run tests

## Detailed Steps

### Setting Up Development Environment

```r
# Install development tools
install.packages(c("devtools", "roxygen2", "testthat", "knitr"))

# Install all dependencies
devtools::install_dev_deps()

# Load your package for development
devtools::load_all()
```

### Writing Functions

1. Create a new R file in `R/` directory
2. Add roxygen2 documentation above your function:

```r
#' Function Title
#'
#' Function description.
#'
#' @param x Description of parameter x
#' @return Description of return value
#' @export
#' @examples
#' my_function(1:10)
my_function <- function(x) {
  # function body
}
```

3. Generate documentation: `devtools::document()`

### Writing Tests

1. Create a test file in `tests/testthat/test-myfunction.R`
2. Add tests using testthat syntax:

```r
test_that("my_function works correctly", {
  result <- my_function(1:10)
  expect_equal(result, expected_value)
})
```

3. Run tests: `devtools::test()`

### Adding Data

1. Put raw data files in `data-raw/`
2. Create a processing script in `data-raw/process_data.R`
3. Process data and save with `usethis::use_data(mydata)`
4. Document data in `R/data.R`

### Writing Vignettes

1. Create vignettes with: `usethis::use_vignette("my-vignette")`
2. Edit the vignette in `vignettes/`
3. Build vignettes: `devtools::build_vignettes()`

### Checking Your Package

Before submitting:

```r
# Check package
devtools::check()

# Check spelling
spelling::spell_check_package()

# Run linter
lintr::lint_package()

# Check test coverage
covr::package_coverage()
```

## GitHub Actions Workflows

The template includes these workflows:

- **R-CMD-check**: Checks package on multiple platforms
- **test-coverage**: Computes test coverage
- **altdoc**: Builds and deploys documentation website
- **check-readme**: Ensures README.md is up to date
- **check-spelling**: Checks spelling in documentation
- **lint-changed-files**: Lints code in pull requests
- **news**: Checks NEWS.md is updated
- **version-check**: Ensures version is incremented
- **pr-commands**: Allows `/document` and `/style` commands in PRs
- **R-check-docs**: Ensures documentation is up to date
- **copilot-setup-steps**: Configures GitHub Copilot environment (add `skip-cp-setup` label to skip setup for workflow/metadata PRs)

### pkgdown PR Preview Comments

The **pkgdown** workflow automatically posts a comment on pull requests with a link to the preview documentation. This comment behavior can be configured in `.github/workflows/pkgdown.yaml`:

**Current configuration** (recommended):
```yaml
- name: Notify pkgdown deployment
  uses: hasura/comment-progress@v2.2.0
  with:
    id: pkgdown-deploy
    recreate: true  # Deletes old comment and creates new one at bottom of PR
```

**Alternative options:**

1. **`recreate: true`** (current setting):
   - Deletes any existing preview comment
   - Creates a new comment at the bottom of the PR conversation
   - Ensures the preview link is always visible and never gets hidden in collapsed sections
   - Best for: Keeping preview easily accessible in long PR conversations

2. **`append: false`** (previous setting):
   - Updates the existing comment in place
   - Comment stays at its original position in the conversation
   - May get hidden when GitHub collapses old comments in long threads
   - Best for: Minimal comment clutter, but preview may become hard to find

Choose `recreate: true` if you want the preview link to always be visible at the end of the PR conversation, or `append: false` if you prefer to minimize the number of comments and don't mind searching for the preview link.

## Best Practices

1. **Follow the tidyverse style guide**: Use `styler::style_pkg()` to format code
2. **Write tests for all exported functions**: Aim for >80% coverage
3. **Update NEWS.md**: Document user-facing changes
4. **Increment version**: Update version in DESCRIPTION for each PR
5. **Use roxygen2 markdown**: Enable markdown in roxygen comments
6. **Add examples**: Include working examples in function documentation
7. **Keep functions focused**: One function should do one thing well

## Customizing the Template

### Removing Unnecessary Workflows

If you don't need certain workflows, delete them from `.github/workflows/`

### Adding Dependencies

Add dependencies to DESCRIPTION:
- **Imports**: Required packages
- **Suggests**: Optional packages (for tests, vignettes)
- **Depends**: Packages that must be attached (rarely needed)

### Configuring altdoc

Customize your documentation website by editing files in `altdoc/`:
- `quarto_website.yml`: Configure Quarto site settings, theme, sidebar, and navigation
- Build site locally: `pkgload::load_all(); altdoc::render_docs()`
- Preview site: `altdoc::preview_docs()`

## Getting Help

- Read [R Packages book](https://r-pkgs.org/)
- Check [tidyverse style guide](https://style.tidyverse.org/)
- See [GitHub Actions for R](https://github.com/r-lib/actions)
- Review model packages:
  - [serocalculator](https://github.com/UCD-SERG/serocalculator)
  - [serodynamics](https://github.com/ucdavis/serodynamics/)
