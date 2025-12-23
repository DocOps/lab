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
- General Style (Conventional Commits)
      - Commit Description
      - Commit Types
      - Commit Body Conventions
- Use `gh` the GitHub CLI Tool

## The Basics

1. Follow proper branching procedures as outlined in Repository State.
2. Commit messages should be concise and easy for users to edit.  
See Commit Messages for guidance.
3. Always prompt user to approve commits before pushing.
4. Use `gh` for interacting with GitHub whenever possible.  
See Use `gh` the GitHub CLI Tool for more information.

## Repository State

Development is done on development _trunk_ branches named like `dev/x.y`, where `x` is the major version and `y` is the minor.

To start development on a new release version:

```
git checkout main
git pull origin main
git checkout -b dev/1.2
git checkout -b chore/bump-version-1.2.0
git commit -am "Bumped version attributes in README"
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
git commit -m "feat: add widget"
git push -u origin feat/add-widget
gh pr create --base dev/1.2 --title "feat: add widget" --body "Adds a new widget to the dashboard."
```

**Branch naming conventions** :
   - `feat/…​` for new features OR improvements
   - `fix/…​` for bugfixes
   - `chore/…​` for version bumps and sundry tasks with no product impact
   - `epic/…​` for large features or changes that span releases

### Commit Message Conventions

**Description (first line) conventions**:
   - Use present-tense descriptive verbs (“adds widget”, not “added” or “add”)
   - `feat: …​` for new features OR improvements
   - `fix: …​` for bugfixes
   - `chore: …​` for version bumps and sundry tasks with no product impact
   - `docs: …​` for documentation changes
   - `test: …​` for test code changes
   - `refactor: …​` for code restructuring with no functional changes
   - `style: …​` for formatting, missing semi-colons, etc; no functional changes
   - `perf: …​` for performance improvements
   - `auto: …​` for changes to CI/CD pipelines and build system

**Body conventions** :
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
git commit -m "feat: add widget"
git merge --squash feat/add-widget
git commit -m "feat: add widget"
git push origin dev/1.2
```

Delete merged branches.

## Dev Branch Rules

- Always branch from `dev/x.y`.
- Always squash-merge into `dev/x.y`.
- Never merge directly into `main`.

## Commit Messages

This document outlines the protocols for authoring Git commit messages in DocOps Lab projects.

### General Style (Conventional Commits)

DocOps Lab _loosely_ follows the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification for Git commit messages.

Enforcement is not strict, but using Conventional Commits style is encouraged for consistency and clarity.

> **NOTE:** Most DocOps Lab projects do not base Changelog/Release Notes generation on commit messages.

The basic outline for a Conventional Commit message is:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Commit Description

The commit description should be concise and to the point, summarizing the change in 50 characters or less.

Use the _past tense_ rather than imperative mood (e.g., "Added feature X" instead of "Add feature X").

### Commit Types

- Use present-tense descriptive verbs (“adds widget”, not “added” or “add”)
- `feat: …​` for new features OR improvements
- `fix: …​` for bugfixes
- `chore: …​` for version bumps and sundry tasks with no product impact
- `docs: …​` for documentation changes
- `test: …​` for test code changes
- `refactor: …​` for code restructuring with no functional changes
- `style: …​` for formatting, missing semi-colons, etc; no functional changes
- `perf: …​` for performance improvements
- `auto: …​` for changes to CI/CD pipelines and build system

### Commit Body Conventions

- Use the body to explain what and why vs. how.
- Reference issues and pull requests as needed.
- Use bullet points (`- text`) and paragraphs as needed for clarity.
- Do not hard-wrap lines, but _do_:

   - use 1-sentence per line
   - keep sentences short

## Use `gh` the GitHub CLI Tool

For interacting with GitHub, always prefer using the [GitHub CLI (`gh`)](https://cli.github.com/) tool for issues, PRs, and other GH operations.

