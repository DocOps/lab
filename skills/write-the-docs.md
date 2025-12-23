# Documenting Product Changes

This document is intended for AI agents operating within a DocOps Lab environment.

Original sources for this document include:

<!-- detect the origin url based on the slug (origin) -->
- [Product Change Tracking and Documentation](/docs/product-change-docs/)

Each contributor of product code or docs changes is responsible for preparing that change to be included in release documentation, _when applicable_.

Table of Contents

- GitHub Issues Labels
- Change Documentation
- Release Note Entry

## GitHub Issues Labels

GitHub Issues are use specific labels to indicate documentation expectations.

**`needs:docs`** :
   The issue requires documentation updates as part of its resolution. Documentation updates will likely be in a sub-issue with a `documentation` label.

**`needs:note`** :
   The issue requires a note in the release history when resolved. Release notes are appended to the description body under `## Release Note`.

**`changelog`** :
   The issue summary should be included in the changelog for the next release, even if no release note is included.

Issues labeled `changelog` will automatically appear in the Changelog section of the Release History document. Release notes must be manually entered.

## Change Documentation

When a change to the product affects user-facing functionality, the documentation needs to change.

For early product versions, most documentation appears in the root `README.adoc` file. When a product has a `docs/content/` path, documentation changes usually have a home in an AsciiDoc (`.adoc`) file in a subdirectory.

Reference matter should be documented where it is defined, such as in `specs/data/*.yml` files.

## Release Note Entry

User-facing product changes that deserve explanation (not just notice) require a release note.

Add a release note for a given issue by appending it to the issue body following a `## Release Note` heading.

Example

```markdown
## Release Note

The content of the release note goes here, in Markdown format.
Try to keep it to one paragraph with minimal formatting.
```

