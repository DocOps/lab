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

<dl>
<dt class="hdlist1">Task</dt>
<dd>
A specific piece of work that does not directly lead to a change to the product. Used for research, infrastructure management, and other sundry/chore tasks not necessarily associated with repository code changes.
</dd>
<dt class="hdlist1">Bug</dt>
<dd>
Reports describing unexpected behavior or malfunctions in the product. Bug issues are used directly and become bugfixes (no technical type change) once resolved.
</dd>
<dt class="hdlist1">Feature</dt>
<dd>
Requests or ideas for new functionality in the product.
</dd>
<dt class="hdlist1">Improvement</dt>
<dd>
Enhancements of existing features or capabilities.
</dd>
<dt class="hdlist1">Epic</dt>
<dd>
An issue or collection of issues with a common goal that may involve work performed across release versions (“milestones”).
</dd>
</dl>

## Issue Labels

All DocOps Lab projects use a common convention around GitHub issue labels to categorize and manage issues.

### Project-specific Labels

<dl>
<dt class="hdlist1">`component:<part>`</dt>
<dd>
Label prefix for arbitrarily named product aspects, modules, interfaces, or subsystems. Common components include `component:docker`, `component:cli`, and `component:docs` (see next section). These correspond to the `part` property in ReleaseHx change records.
</dd>
</dl>

### Standard Documentation Labels

<dl>
<dt class="hdlist1">`component:docs`</dt>
<dd>
Indicates the issue pertains to documentation infrastructure, layout, deployment, but not core content.
</dd>
<dt class="hdlist1">`documentation`</dt>
<dd>
The issue relates to documentation _content_ updates or improvements.
</dd>
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

### Admonition Labels

<dl>
<dt class="hdlist1">`REMOVAL`</dt>
<dd>
Removes functionality or features.
</dd>
<dt class="hdlist1">`DEPRECATION`</dt>
<dd>
Announces planned removal of functionality or features in a future release. (Only appropriate for `documentation` issues.)
</dd>
<dt class="hdlist1">`BREAKING`</dt>
<dd>
Includes one or more changes that are not backward-compatible.
</dd>
<dt class="hdlist1">`SECURITY`</dt>
<dd>
Addresses or documents a security vulnerability or risk.
</dd>
</dl>

### Other Standard Labels

<dl>
<dt class="hdlist1">`question`</dt>
<dd>
User or community member inquiries about the product or project.
</dd>
<dt class="hdlist1">`priority:high`</dt>
<dd>
Indicates that the issue is important and should be prioritized for release as soon as possible.
</dd>
<dt class="hdlist1">`priority:low`</dt>
<dd>
The issue is not urgent and can be addressed in a future release.
</dd>
<dt class="hdlist1">`priority:stretch`</dt>
<dd>
Issue is slated for the next release but can be bumped if it’s holding up releasee.
</dd>
<dt class="hdlist1">`wontfix`</dt>
<dd>
The issue will not be addressed. Comment from maintainers should explain why.
</dd>
<dt class="hdlist1">`duplicate`</dt>
<dd>
The issue is a duplicate of another issue, which should be linked in the comments.
</dd>
<dt class="hdlist1">`posted-by-issuer`</dt>
<dd>
Indicates that the issue was created by the Issuer tool.
</dd>
<dt class="hdlist1">`good first issue`</dt>
<dd>
Designates an issue suitable for new contributors to the project.
</dd>
<dt class="hdlist1">`help wanted`</dt>
<dd>
Indicates that maintainers are seeking assistance from the community to resolve the issue.
</dd>
</dl>

