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

**devops/release engineer** :
   Execute the technical steps of the release, including git operations, tagging, and artifact publication.

**project manager** :
   Oversee the release process, ensure conditions are met, and handle communications.

**tech writer** :
   Prepare release notes and ensure documentation is up to date.

### Context Management for Multi-role Sessions

By default will be up to the Agent to decide whether to hand off to a concurrent or subsequent Agent or “upgrade” role/skills during a session.

The Operator may of course dictate or override this decision.

The goal is to use appropriate agents without cluttering any given agent’s context window.

**Soft-reset between roles** :
   At each transition, declare what you’re loading (role doc + skills) and what you’re backgrounding. Don’t hold all previous stage details in active memory.

**Mission tracker as swap file** :
   Dump detailed handoff notes into `.agent/project-setup-mission.md` after each stage. Read it first when starting new roles to understand what was built and what’s needed.

**Checkpoint between stages** :
   After each stage, ask Operator to review/continue/pause. Creates intervention points if focus dilutes.

**Watch for dilution** :
   Mixing concerns across roles, contradicting earlier decisions, hedging instead of checking files. If noticed, stop and checkpoint.

**Focused lenses** :
   Each role emphasizes different details (Product Engineer = code structure, QA = test coverage, DevOps = automation, PM = coordination). Switch lenses deliberately; shared base knowledge (README, goals, conventions) stays warm.

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

**Create a mission-tracking document** :
   Write a document with detailed steps for fulfilling the mission assigned here, based on any project-specific context. (`role: project-manager; path: .agent/release-mission.md`)

### Evergreen Tasks

The following tasks apply to most stages.

**Keep the mission-tracking document up to date** :
   At the end of every stage, update the progress. (`path: .agent/release-mission.md`)

### Stage 1: Pre-flight Checks

**Verify conditions** :
   Ensure the "Definition of Done" is met.

   - [ ] All target issues are closed.
   - [ ] CI builds and tests pass on `dev/x.y`.
   - [ ] Documentation updated and merged. (`role: devops-release-engineer; upto: project-manager; with: Operator`)

**Manual double-checks** :
   Perform the following checks before proceeding.

   - [ ] No local paths in `Gemfile`.
   - [ ] All documentation changes merged.
   - [ ] Version attribute bumped and propagated. (`role: project-manager; with: Operator`)

### Stage 2: Release History

**Prepare Release Notes doc** :
   Generate and refine the release history.

   Generate release notes and changelog using ReleaseHx.

```
bundle update releasehx
bundle exec releasehx <$tok.majmin>.<$tok.patch> --md docs/release/<$tok.majmin>.<$tok.patch>.md
```

Edit the Markdown file at `docs/release/<$tok.majmin>.<$tok.patch>.md`.

> **NOTE:** This step may vary significantly depending on project’s implementation of ReleaseHx.

See the project’s `README.adoc`; seek for `releasehx`. (`role: devops-release-engineer; upto: tech-writer; with: Operator; read: .agent/docs/skills/release-history.md`)

### Stage 3: Merge and Tag

**Merge the dev branch to `main``** :
   Merge the development branch into the main branch.

   include::../../task/release.adoc[tag="step-merge"])

**Tag the release** :
   Create and push the release tag.

   ```
   git tag -a v<$tok.majmin>.<$tok.patch> -m "Release <$tok.majmin>.<$tok.patch>"
   git push origin v<$tok.majmin>.<$tok.patch>
   ```

### Stage 4: Release Announcement

**Create GitHub release** :
   Publish the release on GitHub.

   Use the GitHub CLI to create a release:

```
gh release create v<$tok.majmin>.<$tok.patch> --title "Release <$tok.majmin>.<$tok.patch>" --notes-file docs/releases/<$tok.majmin>.<$tok.patch>.md --target main
```

Or else use the GitHub web interface to manually register the release, and copy/paste the contents of `docs/releasehx/<$tok.majmin>.<$tok.patch>.md` into the release notes field. (`role: project-manager; with: devops-release-engineer`)

### Stage 5: Artifact Publication

**Publish artifacts** :
   Build and publish the final artifacts.

   Use the `publish.sh` script with proper credentials in place.

```
./scripts/publish.sh
```

This step concludes the release process. (`role: devops-release-engineer; with: Operator`)

### Stage 6: Post-Release Tests & Cleanup

**Test published artifacts** :
   Manually fetch and install/activate any gems, images, or other binary files, and spot check published documentation. (`role: devops-release-engineer; upto: qa-testing-engineer; with: Operator`)

**Post-release tasks** :
   Perform necessary cleanup and preparation for the next cycle.

   - [ ] Cut a _release_ branch for patching (`release/<$tok.majmin>`).
   - [ ] Update `:next_prod_vrsn:` in docs.
   - [ ] Create next development branch (`dev/<next>`).
   - [ ] Notify stakeholders. (`role: project-manager; with: devops-release-engineer`)

### Post-mission Debriefing

**Review the Mission Report** :
   Highlight outstanding or special notices from the Mission Report. (`role: Agent; with: Operator; read: .agent/reports/release-mission.md`)

**Suggest modifications to _this_ mission assignment** :
   Taking into account any bumps, blockers, or unexpected occurrences during fulfillment of this mission, recommend changes or additions to **“MISSION: Conduct a Product Release”** itself. (`role: Agent; with: Operator; path: ../lab/_docs/agent/missions/conduct-release.adoc`).

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

