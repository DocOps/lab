# AI Agent Instructions for Git Operations

This document is intended for AI agents operating within a DocOps Lab environment.

You are an AI agent that helps with git operations.

This document describes protocols for committing and pushing changes to a git DocOps Lab Git repository and interacting with GitHub on behalf of a DocOps Lab contributor.

Table of Contents

- The Basics
- Repository State
- Development Procedures
  - Commit Message Conventions
  - Merging Changes
- Dev Branch Rules
- Commit Messages
  - General Style
  - Commit Subject
  - Commit Types
  - Commit Body Conventions
- Use `gh` the GitHub CLI Tool

## The Basics

1. Follow proper branching procedures as outlined in Repository State.
2. Commit messages should be concise and easy for users to edit.  
See Commit Messages for guidance.
3. Always prompt Operator to approve commits before pushing.
4. Use `gh` for interacting with GitHub whenever possible.  
See Use `gh` the GitHub CLI Tool for more information.
5. NEVER sign commits as a co-author.

## Repository State

Development is done on development _trunk_ branches named like `dev/x.y`, where `x` is the major version and `y` is the minor.

To start development on a new release version:

```
git checkout main
git pull origin main
git checkout -b dev/1.2
git checkout -b chore/bump-version-1.2.0
git commit -am "chore: Bump version attributes"
git checkout dev/1.2
git merge chore/bump-version-1.2.0
git push -u origin dev/1.2
```

## Development Procedures

Work on feature or fix branches off the corresponding `dev/x.y` trunk.

```
git checkout dev/1.2
git checkout -b feat/add-widget
… implement …
git add .
git commit -m "feat: Add widget"
git push -u origin feat/add-widget
gh pr create --base dev/1.2 --title "feat: Add widget" --body "Adds a new widget to the dashboard."
```

**Branch naming conventions:**
   - `feat/…​` for new features OR improvements
   - `fix/…​` for bugfixes
   - `chore/…​` for version bumps and sundry tasks with no product impact
   - `epic/…​` for large features or changes that span releases

### Commit Message Conventions

**Subject conventions:**
   - `create: Add installation guide` for new docs or UI content
   - `edit: Clarify setup notes` for minor edits to docs or UI content
   - `feat: Add widget` for new features OR improvements
   - `fix: Handle missing widget config` for bugfixes
   - `chore: Bump gem version` for version bumps and sundry tasks with no product impact
   - `test: Cover widget validation` for test code changes
   - `refactor: Extract widget parser` for code restructuring with no functional changes
   - `style: Format widget examples` for formatting, missing semi-colons, etc; no functional changes
   - `perf: Cache widget lookup` for performance improvements
   - `auto: Update release workflow` for changes to CI/CD pipelines and build system
   - `revert: Restore previous widget behavior` for reverting previous changes

**Body conventions:**
   - Use the body to explain what and why vs. how.
   - Reference issues and pull requests as needed.
   - Use bullet points (`- text`) and paragraphs as needed for clarity.
   - Do not hard-wrap lines, but _do_:

     - use 1-sentence per line
     - keep sentences short

### Merging Changes

Squash-merge branches back into `dev/x.y`:

```
git checkout dev/1.2
git checkout -b feat/add-widget
… implement …
git add .
git commit -m "feat: Add widget"
git merge --squash feat/add-widget
git commit -m "feat: Add widget"
git push origin dev/1.2
```

Delete merged branches.

## Dev Branch Rules

- Always branch from `dev/x.y`.
- Always squash-merge into `dev/x.y`.
- Never merge directly into `main`.

## Commit Messages

This document outlines the protocols for authoring Git commit messages in DocOps Lab projects.

### General Style

DocOps Lab _loosely_ follows the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification for Git commit messages.

Enforcement is not strict, but using modified Conventional Commits style is encouraged for consistency and clarity.

> **NOTE:** <table>
> <tr>
> <td>
> <i class="fa icon-note" title="Note"></i>
> </td>
> <td>
> Most DocOps Lab projects do not base Changelog/Release Notes generation on commit messages.
> </td>
> </tr>
> </table>

The basic outline for a Conventional Commit message is:

```
<type>[optional scope]: <subject>

[optional body]

[optional footer(s)]
```

### Commit Subject

The commit subject is the text after `<type>[optional scope]:`. It should be concise and to the point, summarizing the change in 50 characters or less.

Start the subject with a capitalized imperative verb. For example, use “feat: Add widget” instead of “feat: add widget” or “feat: Added widget”.

### Commit Types

- `create: Add installation guide` for new docs or UI content
- `edit: Clarify setup notes` for minor edits to docs or UI content
- `feat: Add widget` for new features OR improvements
- `fix: Handle missing widget config` for bugfixes
- `chore: Bump gem version` for version bumps and sundry tasks with no product impact
- `test: Cover widget validation` for test code changes
- `refactor: Extract widget parser` for code restructuring with no functional changes
- `style: Format widget examples` for formatting, missing semi-colons, etc; no functional changes
- `perf: Cache widget lookup` for performance improvements
- `auto: Update release workflow` for changes to CI/CD pipelines and build system
- `revert: Restore previous widget behavior` for reverting previous changes

### Commit Body Conventions

- Use the body to explain what and why vs. how.
- Reference issues and pull requests as needed.
- Use bullet points (`- text`) and paragraphs as needed for clarity.
- Do not hard-wrap lines, but _do_:

  - use 1-sentence per line
  - keep sentences short

## Use `gh` the GitHub CLI Tool

For interacting with GitHub, always prefer using the [GitHub CLI (`gh`)](https://cli.github.com/) tool for issues, PRs, and other GH operations.

