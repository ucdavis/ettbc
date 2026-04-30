# Feature Request: Multi-version Documentation Support

## Description

Add support for multi-version documentation similar to [r-pkgdown-multiversion](https://github.com/insightsengineering/r-pkgdown-multiversion), allowing users to browse documentation for different package versions.

## Current State

The current altdoc workflow (PR #XX) provides basic version management by deploying:
- Main branch documentation to the root URL
- Tagged releases to `/<tag>/` subdirectories (e.g., `/v1.0.0/`)
- PR previews to `/preview/pr<number>/` subdirectories

## Desired Enhancement

Implement a comprehensive multi-version documentation system that:

1. **Version Selector UI**: Add a version dropdown/selector in the documentation interface
2. **Version Index**: Maintain a list of all available documentation versions
3. **Default Version Routing**: Smart routing to latest stable/development versions
4. **Version Archival**: Preserve documentation for older versions
5. **Cross-version Navigation**: Easy switching between versions

## Target Branch

This feature should be implemented on the `copilot/switch-to-altdoc` branch as an enhancement to the new altdoc-based documentation system.

## Potential Approaches

1. **Custom Script Approach**: Build a custom version manager that:
   - Scans gh-pages branch for available versions
   - Generates a version index JSON file
   - Injects version selector UI into docsify

2. **Docsify Plugin**: Create or use a docsify plugin for version management

3. **Alternative Backend**: Evaluate if switching to mkdocs or quarto_website provides better built-in multi-version support

## References

- [r-pkgdown-multiversion](https://github.com/insightsengineering/r-pkgdown-multiversion)
- [altdoc documentation](https://altdoc.etiennebacher.com/)
- [docsify documentation](https://docsify.js.org/)

## Priority

Enhancement - not blocking current altdoc migration
