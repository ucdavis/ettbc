# R Package Template Information

This repository serves as a comprehensive template for creating R packages following UCD-SERG standards.

## Template Statistics

- **Total Files**: 43
- **GitHub Workflows**: 11
- **Documentation Files**: 8
- **Example R Functions**: 3
- **Test Files**: 2

## Based On

This template was created by analyzing and extracting best practices from:

1. **serocalculator** (https://github.com/UCD-SERG/serocalculator)
   - Mature R package for estimating infection rates from serological data
   - Includes comprehensive CI/CD workflows
   - Production-ready pkgdown documentation

2. **serodynamics** (https://github.com/ucdavis/serodynamics)
   - R package for modeling longitudinal antibody responses
   - Advanced testing and documentation structure
   - JAGS integration examples

## Key Features

### 1. Complete Package Structure
- Standard R package directory layout
- Example functions with roxygen2 documentation
- testthat test infrastructure
- Vignette templates

### 2. CI/CD Workflows
- Multi-platform R CMD check (Ubuntu, macOS, Windows)
- Test coverage reporting with Codecov
- Automated pkgdown documentation deployment
- Code quality checks (linting, spelling)
- Version and NEWS.md validation
- PR command support (/document, /style)
- GitHub Copilot environment setup

### 3. Documentation
- README.Rmd with badges template
- pkgdown configuration for website
- Quarto integration for advanced docs
- Comprehensive usage guide (USAGE.md)
- Setup checklist (CHECKLIST.md)

### 4. Development Tools
- Code style configuration (.lintr)
- Spell checking with custom WORDLIST
- RStudio project file
- Git configuration files

### 5. Community Templates
- Contributing guidelines
- Pull request template
- Issue template
- Code of Conduct

## How to Use This Template

See [USAGE.md](../USAGE.md) for detailed instructions and [CHECKLIST.md](../CHECKLIST.md) for a step-by-step setup guide.

### Quick Steps

1. Create new repo from this template
2. Clone and open in RStudio
3. Follow CHECKLIST.md
4. Replace `packagename` throughout
5. Update DESCRIPTION metadata
6. Add your code and tests
7. Run `devtools::check()`
8. Push to GitHub

## Customization

This template is designed to be customizable:

- Remove unnecessary workflows
- Adjust dependencies in DESCRIPTION
- Modify pkgdown configuration
- Update linting rules
- Add package-specific documentation

## Maintenance

This template should be updated periodically to reflect:
- New GitHub Actions versions
- Updated R package best practices
- Changes to model repositories
- Community feedback

## License

MIT License - See LICENSE file

## Contact

For questions or improvements, please open an issue or pull request.
