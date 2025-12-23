# GitHub Issues Management for AI Agents

This document is intended for AI agents operating within a DocOps Lab environment.

AI agents assisting in DocOps Lab development tasks should use the Issuer and `gh` CLI tools to manage GitHub issues in project repositories.

Table of Contents

- Managing GitHub Issues with `gh`
- Bulk-posting Issues with Issuer
- Issue Types
- Issue Labels
- Project-specific Labels
      - Standard Documentation Labels
      - Admonition Labels
      - Other Standard Labels

## Managing GitHub Issues with `gh`

The GitHub CLI tool, `gh`, can be used to manage issues from the command line.

See [GitHub CLI Manual: gh issue](https://cli.github.com/manual/gh_issue) for details on using `gh` to create, view, edit, and manage issues and issue metadata.

Some common commands:

Create a new issue.

```
gh issue create --title "Issue Title" --body "Issue description." --label "bug,component:docs" --assignee "username"
```

List open issues.

```
gh issue list --state open
```

View a specific issue.

```
gh issue view <issue-number>
```

## Bulk-posting Issues with Issuer

The `issuer` tool can be used to bulk-post issues to any repository from a YAML file.

Follow the instructions at [Issuer](https://github.com/DocOps/issuer) to install and use the tool.

## Issue Types

**Task** :
   A specific piece of work that does not directly lead to a change to the product. Used for research, infrastructure management, and other sundry/chore tasks not necessarily associated with repository code changes.

**Bug** :
   Reports describing unexpected behavior or malfunctions in the product. Bug issues are used directly and become bugfixes (no technical type change) once resolved.

**Feature** :
   Requests or ideas for new functionality in the product.

**Improvement** :
   Enhancements of existing features or capabilities.

**Epic** :
   An issue or collection of issues with a common goal that may involve work performed across release versions (“milestones”).

## Issue Labels

All DocOps Lab projects use a common convention around GitHub issue labels to categorize and manage issues.

### Project-specific Labels

**`component:<part>`** :
   Label prefix for arbitrarily named product aspects, modules, interfaces, or subsystems. Common components include `component:docker`, `component:cli`, and `component:docs` (see next section). These correspond to the `part` property in ReleaseHx change records.

### Standard Documentation Labels

**`component:docs`** :
   Indicates the issue pertains to documentation infrastructure, layout, deployment, but not core content.

**`documentation`** :
   The issue relates to documentation _content_ updates or improvements.

**`needs:docs`** :
   The issue requires documentation updates as part of its resolution. Documentation updates will likely be in a sub-issue with a `documentation` label.

**`needs:note`** :
   The issue requires a note in the release history when resolved. Release notes are appended to the description body under `## Release Note`.

**`changelog`** :
   The issue summary should be included in the changelog for the next release, even if no release note is included.

### Admonition Labels

**`REMOVAL`** :
   Removes functionality or features.

**`DEPRECATION`** :
   Announces planned removal of functionality or features in a future release. (Only appropriate for `documentation` issues.)

**`BREAKING`** :
   Includes one or more changes that are not backward-compatible.

**`SECURITY`** :
   Addresses or documents a security vulnerability or risk.

### Other Standard Labels

**`question`** :
   User or community member inquiries about the product or project.

**`priority:high`** :
   Indicates that the issue is important and should be prioritized for release as soon as possible.

**`priority:low`** :
   The issue is not urgent and can be addressed in a future release.

**`priority:stretch`** :
   Issue is slated for the next release but can be bumped if it’s holding up releasee.

**`wontfix`** :
   The issue will not be addressed. Comment from maintainers should explain why.

**`duplicate`** :
   The issue is a duplicate of another issue, which should be linked in the comments.

**`posted-by-issuer`** :
   Indicates that the issue was created by the Issuer tool.

**`good first issue`** :
   Designates an issue suitable for new contributors to the project.

**`help wanted`** :
   Indicates that maintainers are seeking assistance from the community to resolve the issue.

