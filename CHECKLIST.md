# Package Setup Checklist

Use this checklist when setting up a new package from this template.

## Initial Setup

- [ ] Create repository from template
- [ ] Clone repository to local machine
- [ ] Rename `packagename.Rproj` to `yourpackage.Rproj`

## Find and Replace

Replace `packagename` with your actual package name in:

- [ ] `DESCRIPTION`
- [ ] `.Rbuildignore` (2 instances)
- [ ] `.gitignore` (3 instances)
- [ ] `README.Rmd` (multiple instances)
- [ ] `altdoc/quarto_website.yml` (if needed for customization)
- [ ] `.github/CONTRIBUTING.md`
- [ ] `.github/ISSUE_TEMPLATE/issue_template.md`
- [ ] `R/packagename-package.R` (rename file and update content)
- [ ] `tests/testthat.R`

## Update Metadata

- [ ] Update `Title` in DESCRIPTION
- [ ] Update `Authors@R` in DESCRIPTION
- [ ] Update `Description` in DESCRIPTION
- [ ] Update `URL` in DESCRIPTION
- [ ] Update `BugReports` in DESCRIPTION
- [ ] Review and update dependencies in DESCRIPTION

## Update Documentation

- [ ] Update `README.Rmd` with your package description
- [ ] Update examples in `README.Rmd`
- [ ] Render README: `rmarkdown::render("README.Rmd")`
- [ ] Update `NEWS.md` with initial version info
- [ ] Update package description in `R/packagename-package.R`

## Code and Tests

- [ ] Remove example function from `R/example_function.R` (or keep as reference)
- [ ] Add your R functions to `R/` directory
- [ ] Add roxygen2 documentation to all functions
- [ ] Generate documentation: `devtools::document()`
- [ ] Remove example test from `tests/testthat/test-example_function.R`
- [ ] Add your tests to `tests/testthat/`
- [ ] Run tests: `devtools::test()`

## Optional Components

- [ ] Add package data to `data/` directory
- [ ] Create data processing scripts in `data-raw/`
- [ ] Update or create vignettes in `vignettes/`
- [ ] Add example files to `inst/extdata/`
- [ ] Update `inst/WORDLIST` with package-specific terms

## Quality Checks

- [ ] Run `devtools::check()` - should pass with no errors, warnings, or notes
- [ ] Run `spelling::spell_check_package()` - fix any typos
- [ ] Run `lintr::lint_package()` - address any style issues
- [ ] Check test coverage: `covr::package_coverage()` - aim for >80%

## GitHub Setup

- [ ] Enable GitHub Actions in repository settings
- [ ] Set up Codecov (optional): add CODECOV_TOKEN secret
- [ ] Enable GitHub Pages for altdoc site
- [ ] Create initial release/tag when ready
- [ ] Add repository topics/tags

## Documentation Website

- [ ] Customize `altdoc/quarto_website.yml` if desired (theme, sidebar, etc.)
- [ ] Organize functions and vignettes in the altdoc sidebar
- [ ] Customize Quarto theme if desired
- [ ] Build site locally: `pkgload::load_all(); altdoc::render_docs()`
- [ ] Preview site locally: `altdoc::preview_docs()`

## Final Steps

- [ ] Review all files for template placeholders
- [ ] Commit all changes
- [ ] Push to GitHub
- [ ] Verify GitHub Actions workflows run successfully
- [ ] Check altdoc site is deployed correctly
- [ ] Create first issue/milestone for development
- [ ] Invite collaborators if applicable

## Before First Release

- [ ] Complete comprehensive testing
- [ ] Review all documentation
- [ ] Update version to 0.1.0 (or 1.0.0)
- [ ] Update NEWS.md with release notes
- [ ] Create GitHub release
- [ ] Consider submitting to CRAN (if applicable)

---

**Tip**: Keep this checklist in your repository during development. Delete it before your first release.
