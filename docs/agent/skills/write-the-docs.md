# Documenting Product Changes

This document is intended for AI agents operating within a DocOps Lab environment.

Original sources for this document include:

<!-- detect the origin url based on the slug (origin) -->
- [Product Change Tracking and Documentation](/docs/product-change-docs/)

Each contributor of product code or docs changes is responsible for preparing that change to be included in release documentation, _when applicable_.

Table of Contents

- GitHub Issues Labels
- Change Documentation
  - User-Facing Documentation
  - Internal Documentation
- Release Note Entry

## GitHub Issues Labels

GitHub Issues are use specific labels to indicate documentation expectations.

<dl>
<dt class="hdlist1">`needs:docs`</dt>
<dd>
The issue requires documentation updates as part of its resolution. Documentation updates will likely be in a sub-issue with a `documentation` label.
</dd>
<dt class="hdlist1">`needs:note`</dt>
<dd>
The issue requires a note in the release history when resolved. Release notes are appended to the description body under `## Release Note`.
</dd>
<dt class="hdlist1">`changelog`</dt>
<dd>
The issue summary should be included in the changelog for the next release, even if no release note is included.
</dd>
</dl>

Issues labeled `changelog` will automatically appear in the Changelog section of the Release History document. Release notes must be manually entered.

## Change Documentation

When a change to the product affects user-facing functionality, the documentation needs to change.

For early product versions, most documentation appears in the root `README.adoc` file. When a product has a `docs/content/` path, documentation changes usually have a home in an AsciiDoc (`.adoc`) file in a subdirectory.

Reference matter should be documented where it is defined, such as in `specs/data/*.yml` files.

When a product matures (prior to 1.0), the documentation should move into new paths, separated depending on whether it is user-facing or internal.

In either case, the way to discover where to put documentation changes is to use a `docopslab-dev` _skim_ task on the existing docs source. These skims are semantic outlines of the source files in their converted state. They can be used for navigation, content discovery, and change impact analysis.

### User-Facing Documentation

End-user docs, including API documentation, is usually sourced in `docs/content/`, alongside asset files for the documentation site (images, CSS, etc.).

The `docs/` path is typically a Jekyll site’s source path, but in most cases a pre-build operation will generate supplemental files in `docs/built/` or the like.

If the changes you are documenting are user-facing, use the tasks below to determine where the relevant documentation lives.

<dl>
<dt class="hdlist1">Skim the docs</dt>
</dl>

```
bundle exec rake labdev:skim:adoc[README.adoc,tree,json] > .agent/docs/readme.json
bundle exec rake labdev:skim:adoc[docs/,tree,json] > .agent/docs/skim-docs.json
```

### Internal Documentation

Generally speaking, internal documentation (for developers, maintainers, and their AI agents), belongs in `_docs/` and `.agent/docs/` paths.

The `_docs/agent/` path is for overlays that take priority over parallel docs in `.agent/docs/` (maintained by docopslab-dev library syncing).

<dl>
<dt class="hdlist1">Skim the README</dt>
</dl>

```
bundle exec rake labdev:skim:adoc[README.adoc,tree,json] > .agent/docs/readme.json
```

<dl>
<dt class="hdlist1">Skim the internal docs</dt>
</dl>

```
bundle exec rake labdev:skim:adoc[_docs/,tree,json] > .agent/docs/skim-internal.json
```

<dl>
<dt class="hdlist1">Skim the agent docs to see if any overlay is needed</dt>
</dl>

```
bundle exec rake labdev:skim:md[.agent/docs/:_docs/agent/,tree,json] > .agent/docs/skim-agent.json
```

If a local instruction contradicts or differs arbitrarily from the main DocOps Lab developer/contributor docs, create an overlay file in `_docs/agent/*` with the same sub-path and filename.

## Release Note Entry

User-facing product changes that deserve explanation (not just notice) require a release note.

Add a release note for a given issue by appending it to the issue body following a `## Release Note` heading.

Example

```markdown
## Release Note

The content of the release note goes here, in Markdown format.
Try to keep it to one paragraph with minimal formatting.
```

