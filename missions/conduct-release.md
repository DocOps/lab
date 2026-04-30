# MISSION: Conduct a Product Release

This document is intended for AI agents operating within a DocOps Lab environment.

Original sources for this document include:

<!-- detect the origin url based on the slug (origin) -->
- [Release Process (General)](/docs/release/)

An AI Agent or multiple Agents, in collaboration with a human Operator, can execute the release procedure for a DocOps Lab project/product.

This mission covers the entire process from pre-flight checks to post-release cleanup.

Check the `README.adoc` or `docs/**/release.adoc` file specific to the project you are releasing for specific procedures.

Table of Contents

- Agent Roles
  - Context Management for Multi-role Sessions
  - Task Assignments and Suggestions
- Prerequisite: Attention OPERATOR
- Mission Procedure
  - Stage 0: Mission Prep
  - Evergreen Tasks
  - Stage 1: Pre-flight Checks
  - Stage 2: Release History
  - Stage 3: Merge and Tag
  - Stage 4: Release Announcement
  - Stage 5: Artifact Publication
  - Stage 6: Post-Release Tests & Cleanup
  - Post-mission Debriefing
- Fulfillment Principles
  - ALWAYS
  - NEVER
  - Quality Bar

## Agent Roles

The following agent roles will take a turn at steps in this mission.

<dl>
<dt class="hdlist1">devops/release engineer</dt>
<dd>
Execute the technical steps of the release, including git operations, tagging, and artifact publication.
</dd>
<dt class="hdlist1">project manager</dt>
<dd>
Oversee the release process, ensure conditions are met, and handle communications.
</dd>
<dt class="hdlist1">tech writer</dt>
<dd>
Prepare release notes and ensure documentation is up to date.
</dd>
</dl>

### Context Management for Multi-role Sessions

By default will be up to the Agent to decide whether to hand off to a concurrent or subsequent Agent or “upgrade” role/skills during a session.

The Operator may of course dictate or override this decision.

The goal is to use appropriate agents without cluttering any given agent’s context window.

<dl>
<dt class="hdlist1">Soft-reset between roles</dt>
<dd>
At each transition, declare what you’re loading (role doc + skills) and what you’re backgrounding. Don’t hold all previous stage details in active memory.
</dd>
<dt class="hdlist1">Mission tracker as swap file</dt>
<dd>
Dump detailed handoff notes into `.agent/project-setup-mission.md` after each stage. Read it first when starting new roles to understand what was built and what’s needed.
</dd>
<dt class="hdlist1">Checkpoint between stages</dt>
<dd>
After each stage, ask Operator to review/continue/pause. Creates intervention points if focus dilutes.
</dd>
<dt class="hdlist1">Watch for dilution</dt>
<dd>
Mixing concerns across roles, contradicting earlier decisions, hedging instead of checking files. If noticed, stop and checkpoint.
</dd>
<dt class="hdlist1">Focused lenses</dt>
<dd>
Each role emphasizes different details (Product Engineer = code structure, QA = test coverage, DevOps = automation, PM = coordination). Switch lenses deliberately; shared base knowledge (README, goals, conventions) stays warm.
</dd>
</dl>

### Task Assignments and Suggestions

In the Mission Procedures section, metadata is associated with each task.

All tasks are assigned a preferred `role:` the Agent should assume in carrying out the task. That role has further documentation at `.agent/docs/roles/<role-slug>.md`, and the executing agent should ingest that document entirely before proceeding.

Recommended collaborators are indicated by `with:`.

Recommended upgrades are designated by `upto:`.

Suggested skill/topic readings are indicated by `read:`.

Any working directories or files are listed in `path:`.

## Prerequisite: Attention OPERATOR

This process requires the `docopslab-dev` tooling is installed and synced. Ensure you have the necessary credentials for GitHub and any artifact registries (RubyGems, DockerHub, etc.).

## Mission Procedure

In general, the following stages are to be followed in order and tracked in a mission document.

### Stage 0: Mission Prep

<dl>
<dt class="hdlist1">Create a mission-tracking document</dt>
<dd>
Write a document with detailed steps for fulfilling the mission assigned here, based on any project-specific context. (`role: project-manager; path: .agent/release-mission.md`)
</dd>
</dl>

### Evergreen Tasks

The following tasks apply to most stages.

<dl>
<dt class="hdlist1">Keep the mission-tracking document up to date</dt>
<dd>
At the end of every stage, update the progress. (`path: .agent/release-mission.md`)
</dd>
</dl>

### Stage 1: Pre-flight Checks

<dl>
<dt class="hdlist1">Verify conditions</dt>
<dd>
Ensure the "Definition of Done" is met.

- <input type="checkbox" data-item-complete="0"> All target issues are closed.

- <input type="checkbox" data-item-complete="0"> CI builds and tests pass on `dev/<$tok.majmin>`.

- <input type="checkbox" data-item-complete="0"> Documentation updated and merged. (`role: devops-release-engineer; upto: project-manager; with: Operator`)
</dd>
<dt class="hdlist1">Manual double-checks</dt>
<dd>
Perform the following checks before proceeding.

- <input type="checkbox" data-item-complete="0"> No local paths in `Gemfile`.

- <input type="checkbox" data-item-complete="0"> All documentation changes merged.

- <input type="checkbox" data-item-complete="0"> Version attribute bumped and propagated. (`role: project-manager; with: Operator`)
</dd>
</dl>

### Stage 2: Release History

<dl>
<dt class="hdlist1">Prepare Release Notes doc</dt>
<dd>
Generate and refine the release history.

Generate release notes and changelog using ReleaseHx.
</dd>
</dl>

> **NOTE:** Most projects use ReleaseHx in a unique manner, for diverse testing of its output options. See the project’s `README.adoc`; seek for `releasehx`.

The default procedure if not otherwise specified:

```
bundle update releasehx
bundle exec rhx <$tok.majmin>.<$tok.patch> --md docs/release/<$tok.majmin>.<$tok.patch>.md
```

Edit the Markdown file at `docs/release/<$tok.majmin>.<$tok.patch>.md`.

(`role: devops-release-engineer; upto: tech-writer; with: Operator; read: .agent/docs/skills/release-history.md`)

### Stage 3: Merge and Tag

<dl>
<dt class="hdlist1">Merge the dev branch to `main``</dt>
<dd>
Merge the development branch into the main branch.

```
git checkout main
git pull origin main
git merge --no-ff dev/<$tok.majmin>
git push origin main
```
</dd>
<dt class="hdlist1">Tag the release</dt>
<dd>
Create and push the release tag.

```
git tag -a v<$tok.majmin>.<$tok.patch> -m "Release <$tok.majmin>.<$tok.patch>"
git push origin v<$tok.majmin>.<$tok.patch>
```
</dd>
</dl>

### Stage 4: Release Announcement

<dl>
<dt class="hdlist1">Create GitHub release</dt>
<dd>
Publish the release on GitHub.

Use the GitHub CLI to create a release:
</dd>
</dl>

```
gh release create v<$tok.majmin>.<$tok.patch> --title "Release <$tok.majmin>.<$tok.patch>" --notes-file docs/releases/<$tok.majmin>.<$tok.patch>.md --target main
```

Or else use the GitHub web interface to manually register the release, and copy/paste the contents of `docs/release/<$tok.majmin>.<$tok.patch>.md` into the release notes field. (`role: project-manager; with: devops-release-engineer`)

### Stage 5: Artifact Publication

<dl>
<dt class="hdlist1">Publish artifacts</dt>
<dd>
Build and publish the final artifacts.

Use the `publish.sh` script with proper credentials in place.
</dd>
</dl>

```
./scripts/publish.sh
```

This step concludes the release process. (`role: devops-release-engineer; with: Operator`)

### Stage 6: Post-Release Tests & Cleanup

<dl>
<dt class="hdlist1">Test published artifacts</dt>
<dd>
Manually fetch and install/activate any gems, images, or other binary files, and spot check published documentation. (`role: devops-release-engineer; upto: qa-testing-engineer; with: Operator`)
</dd>
<dt class="hdlist1">Post-release tasks</dt>
<dd>
Perform necessary cleanup and preparation for the next cycle.

- <input type="checkbox" data-item-complete="0"> Cut a _release_ branch for patching (`release/<$tok.majmin>`).

- <input type="checkbox" data-item-complete="0"> Update `:next_prod_vrsn:` in docs.

- <input type="checkbox" data-item-complete="0"> Create next development branch (`dev/<next>`).

- <input type="checkbox" data-item-complete="0"> Notify stakeholders. (`role: project-manager; with: devops-release-engineer`)
</dd>
</dl>

### Post-mission Debriefing

<dl>
<dt class="hdlist1">Review the Mission Report</dt>
<dd>
Highlight outstanding or special notices from the Mission Report. (`role: Agent; with: Operator; read: .agent/reports/release-mission.md`)
</dd>
<dt class="hdlist1">Suggest modifications to _this_ mission assignment</dt>
<dd>
Taking into account any bumps, blockers, or unexpected occurrences during fulfillment of this mission, recommend changes or additions to **“MISSION: Conduct a Product Release”** itself. (`role: Agent; with: Operator; path: ../lab/_docs/agent/missions/conduct-release.adoc`).
</dd>
</dl>

> **IMPORTANT:** In case of emergency rollback or patching, see `.agent/docs/skills/product-release-rollback.md`.

## Fulfillment Principles

### ALWAYS

- Always ask the Operator when you don’t know exactly how DocOps Lab prefers a step be carried out.

- Always follow the mission procedure as closely as possible, adapting only when necessary due to project-specific constraints.

- Always document any deviations from the standard procedure and the reasons for them in the Mission Report.

- Always look for a DRY way to define product metadata/attrbutes in README.adoc and YAML files (`specs/data/*-def.yml`).

- Always pause for Operator approval before ANY publishing or deployment action, including pushing/posting to GitHub.

### NEVER

- Never get creative or innovative without Operator permission.

- Never skip steps in the mission procedure without documenting the reason.

- Never assume the Operator understands DocOps Lab conventions without explanation.

### Quality Bar

A successful release is one where all artifacts are published correctly, the documentation accurately reflects the changes, and the repository is in a clean state for the next development cycle.

