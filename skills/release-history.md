# Preparing a Version Release History Document

This document is intended for AI agents operating within a DocOps Lab environment.

Original sources for this document include:

<!-- detect the origin url based on the slug (origin) -->
- [Product Change Tracking and Documentation](/docs/product-change-docs/)

ReleaseHx automatically generates release notes and changelogs from GitHub Issues and PRs when properly labeled.

> **NOTE:** Every DocOps Lab project implements ReleaseHx differently as a way of “eating our own dog food”.

Refer to any given project’s documentation for specific instructions on how to prepare changes for inclusion in release notes and changelogs.

The general procedure is as follows:

1. Generate a draft release history in YAML.

```
bundle exec rhx <version> --yaml --fetch
```
2. Edit the generated YAML to ensure clarity and completeness.
3. Generate the Markdown version.

```
bundle exec rhx <version> --md docs/release/<version>.md
```

