# MISSION: Start a New DocOps Lab Project

This document is intended for AI agents operating within a DocOps Lab environment.

An AI Agent or multiple Agents, in collaboration with a human Operator, can initialize and prepare a codebase for a new DocOps Lab project.

This codebase can be based on an existing specification document, or one can be drafted during this procedure.

Table of Contents

- Agent Roles
  - Context Management for Multi-role Sessions
  - Task Assignments and Suggestions
- Prerequisite: Attention OPERATOR
- Quick Start: Using the CLI (Recommended)
- Mission Procedure
  - Stage 0: Mission Prep
  - Evergreen Tasks
  - Stage 1: Project Specification
  - Stage 2: Codebase/Environment Setup
  - Stage 3: Testing Framework Setup
  - Stage 4: CI/CD Pipeline Setup
  - Stage 5: Initial Product Code
  - Stage 6: Review Initial Project Setup
  - Stage 7: Agent Documentation
  - Stage 8: Squash and Push to GitHUb
  - Stage 9: Configure GH Issues Board
  - Stage 10: Create Initial Work Issues
  - Post-mission Debriefing
- Fulfillment Principles
  - ALWAYS
  - NEVER
  - Quality Bar

## Agent Roles

The following agent roles will take a turn at steps in this mission.

<dl>
<dt class="hdlist1">planner/architect (optional)</dt>
<dd>
If there is no specification yet, this agent works with the Operator and any relevant documentation to draft a project specification and/or definition documents.
</dd>
<dt class="hdlist1">product engineer</dt>
<dd>
Initialize the basic environment and dependencies; oversee DevOps, DocOps, and QA contributions; wireframe/scaffold basic library structure.
</dd>
<dt class="hdlist1">QA/testing engineer</dt>
<dd>
Set up testing frameworks and initial/demonstrative test cases.
</dd>
<dt class="hdlist1">DevOps/release engineer</dt>
<dd>
Set up CI/CD pipelines, containerization, and infrastructure as code.
</dd>
<dt class="hdlist1">project manager</dt>
<dd>
Review the initial project setup; create initial work issues and tasks for further development.
</dd>
<dt class="hdlist1">tech writer</dt>
<dd>
Assist in writing/reviewing specification docs and README.
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

This process requires the `docopslab-dev` tooling is installed and synced, or at the very least the `.agent/docs/` library maintained by that tool be in place.

For unorthodox projects, simply copying an up-to-date version of that library to your project root directory should suffice.

## Quick Start: Using the CLI (Recommended)

The `docopslab-dev` gem provides a standalone CLI tool for rapid project initialization. This is the recommended approach for new projects:

```
docker run -it --rm -v "$(pwd):/workspace" docopslab/dev init
```

The CLI automatically performs the following:

1. Initializes a Git repository (if not already initialized)

2. Creates the manifest file at `.config/docopslab-dev.yml`

3. Generates default project configuration files for all tools

4. Initializes templates from the manifest using SyncCast

The resulting project is ready for development with no additional steps required.

> **TIP:** The manifest file created by `init` should be Git tracked for the project.

## Mission Procedure

In general, the following stages are to be followed in order and tracked in a mission document.

### Stage 0: Mission Prep

<dl>
<dt class="hdlist1">Create a mission-tracking document</dt>
<dd>
Write a document with detailed steps for fulfilling the mission assigned here, based on any project-specific context that might rule in or out some of the following stages or steps. (`role: project-manager; path: .agent/project-setup-mission.md`)
</dd>
</dl>

### Evergreen Tasks

The following tasks apply to most stages.

<dl>
<dt class="hdlist1">Keep the mission-tracking document up to date</dt>
<dd>
At the end of every stage, update the progress. (`path: .agent/project-setup-mission.md`)
</dd>
<dt class="hdlist1">Perform tests as needed</dt>
<dd>
Run tests to ensure the initial setup is functioning as expected. (`role: qa-testing-engineer; read: [.agent/docs/skills/tests-running.md, specs/tests/README.adoc]`)
</dd>
<dt class="hdlist1">Update docs as needed</dt>
<dd>
Continuously improve the relevant `README.adoc` and other documentation based on new insights or changes in the project setup. (`role: tech-writer; read: .agent/docs/skills/asciidoc.md, .agent/docs/skills/readme-driven-dev.md, paths: [README.adoc, specs/docs/**/*.adoc, specs/tests/README.adoc]`)
</dd>
</dl>

### Stage 1: Project Specification

<dl>
<dt class="hdlist1">Specification review</dt>
<dd>
_If the project already contains one or more specification documents (`specs/docs/*.adoc`) and/or an extensive `README.adoc` file_, review them for thoroughness and advise of missing information, ambiguities, inconsistencies, and potential pitfalls. (`role: planner-architect; with: operator; upto: [product-engineer, product-manager]`)
</dd>
<dt class="hdlist1">Draft a specification</dt>
<dd>
_If no specification and no detailed `README.adoc` exists_, work with the Operator to draft a basic project specification/requirements document in AsciiDoc and data/interface definition files in YAML/SGYML. (`role: planner-architect; with: [product-manager, tech-writer]; upto: product-developer; read: [.agent/docs/skills/asciidoc.md, .agent/docs/skills/schemagraphy-sgyml.md], path: specs/docs/<subject-slug>-requirements.adoc`)
</dd>
<dt class="hdlist1">Create/enrich README</dt>
<dd>
The `README.adoc` file is _the_ primary document for every DocOps Lab repo. Make it great. (`role: tech-writer; with: [planner-architect, product-manager]; upto: product-engineer; read: .agent/docs/skills/asciidoc.md, .agent/docs/skills/readme-driven-dev.md`, path: `README.adoc`)
</dd>
</dl>

### Stage 2: Codebase/Environment Setup

<dl>
<dt class="hdlist1">Establish initial files</dt>
<dd>
Create the basic project directory structure and initial files, including `README.adoc`, `.gitignore`, `Dockerfile`, `Rakefile`, along with any necessary configuration files. (`role: product-engineer; read: .agent/docs/topics/common-project-paths.md`)
</dd>
<dt class="hdlist1">Establish versioning</dt>
<dd>
Define the revision code (probably `0.1.0`) in the `README.adoc` and make sure the base module/code reads it from there as SSoT. (`role: product-engineer; read: .agent/docs/skills/readme-driven-dev.md; path: README.adoc`)
</dd>
<dt class="hdlist1">Populate initial files</dt>
<dd>
Fill in the initial files with dependency requirements, boilerplate content, placeholder comments, project description, based on the Specification. (`role: product-engineer; read: .agent/docs/skills/code-commenting.md`, path: `[Rakefile, .gitignore, lib/**, <product-slug>.gemspec, etc]`)
</dd>
<dt class="hdlist1">Instantiate environment/dependencies</dt>
<dd>
Install dependency libraries (usually `bundle install`, `npm install`, and so forth). (`role: product-engineer)
</dd>
<dt class="hdlist1">Update the README</dt>
<dd>
Add relevant details from this stage to the project’s `README.adoc` file. Include basic setup/quickstart instructions for developers. (`role: product-engineer; upto: tech-writer; read: .agent/docs/skills/asciidoc.md, .agent/docs/skills/readme-driven-dev.md`, path: `README.adoc`)
</dd>
<dt class="hdlist1">Commit to Git</dt>
<dd>
Test the `.gitignore` and any pre-commit hooks by adding and committing files. Adjust `.gitignore` as needed and amend commits until correct. (`role: product-engineer; read: .agent/docs/skills/git.md;`)
</dd>
</dl>

### Stage 3: Testing Framework Setup

<dl>
<dt class="hdlist1">Create basic testing scaffold</dt>
<dd>
Prompt the Operator to provide relevant examples from similar repos and modify it for the current project’s use case. (`role: qa-testing-engineer; with: operator; upto: product-engineer; read: [README.adoc, specs/ .agent/docs/skills/tests-writing.md, .agent/docs/skills/rake-cli-dev.md]; path: specs/tests/`)
</dd>
<dt class="hdlist1">Populate initial test cases</dt>
<dd>
Draft initial test cases that cover basic functionality and edge cases based on the project specification. (`role: qa-testing-engineer; upto: product-engineer; read: .agent/docs/skills/tests-writing.md; paths: specs/tests/rspec/`)
</dd>
<dt class="hdlist1">Create a testing README</dt>
<dd>
Draft the initial docs for the testing regimen. (`role: qa-testing-engineer; upto: tech-writer; read: .agent/docs/skills/asciidoc.md, .agent/docs/skills/readme-driven-dev.md`, path: `specs/tests/README.adoc`)
</dd>
<dt class="hdlist1">Update the project README</dt>
<dd>
Make a note of the tests path and docs in the main `README.adoc` file. (`role: qa-testing-engineer; upto: tech-writer; read: .agent/docs/skills/asciidoc.md, .agent/docs/skills/readme-driven-dev.md`, path: `README.adoc`)
</dd>
<dt class="hdlist1">Commit to Git</dt>
<dd>
Add and commit testing files to Git. (`role: qa-testing-engineer; read: .agent/docs/skills/git.md;`)
</dd>
</dl>

### Stage 4: CI/CD Pipeline Setup

<dl>
<dt class="hdlist1">Draft initial CI/CD workflows</dt>
<dd>
Set up GitHub Actions workflows for building, testing, and deploying the project. Integrate tests into `Rakefile` or other scripts as appropriate. (`role: devops-release-engineer; upto: product-engineer; read: .agent/docs/skills/devops-ci-cd.md; paths: [Rakefile, .github/workflows/, .scripts/**]`)
</dd>
<dt class="hdlist1">Commit to Git</dt>
<dd>
Add and commit CI/CD files to Git. (`role: devops-release-engineer; read: .agent/docs/skills/git.md;`)
</dd>
</dl>

### Stage 5: Initial Product Code

<dl>
<dt class="hdlist1">Write code to initial tests</dt>
<dd>
Implement the minimum viable code to pass the initial test cases. (`role: product-engineer; with: [Operator, qa-testing-engineer]; read: [specs/tests/rspec/**, specs/docs/*.adoc]; upto: [qa-testing-engineer, devops-release-engineer]; paths: [lib/**, specs/tests/rspec/**]`)
</dd>
<dt class="hdlist1">Commit to Git</dt>
<dd>
Add and commit the initial product code to Git. (`role: product-engineer; read: .agent/docs/skills/git.md;`)
</dd>
</dl>

### Stage 6: Review Initial Project Setup

<dl>
<dt class="hdlist1">Review mission report</dt>
<dd>
Check the mission progress document for any `TODO`s or notes from previous stages.
Triage these and consider invoking new roles to fulfill the steps.
(`role: project-manager; with: Operator; read: .agent/project-setup-mission.md; path: .agent/reports/project-setup-mission.md`)
</dd>
<dt class="hdlist1">Check project against README and specs</dt>
<dd>
Read through the relevant specifications to ensure at least the _scaffolding_ to meet the project requirements is in place. Take note of any place the codebase falls short. (`role: project-manager; read: [README.adoc, specs/**/*.{adoc,yml,yaml}]; upto: [planner-architect, product-engineer, qa-testing-engineer, devops-release-engineer]; path: .agent/reports/project-setup-mission.md; with: Operator`)
</dd>
</dl>

### Stage 7: Agent Documentation

<dl>
<dt class="hdlist1">Draft an AGENTS.md file from template</dt>
<dd>
Use the `AGENTS.markdown` file available through `docopslab-dev` (sync initially, then set `sync: false` in `.config/docopslab-dev.yml`). Follow the instructions in the doc to transform it into a localized edition of the prime doc. (`role: Agent; path: AGENTS.adoc`)
</dd>
</dl>

### Stage 8: Squash and Push to GitHUb

The repository should now be ready for sharing.

<dl>
<dt class="hdlist1">Squash commits</dt>
<dd>
Squash any previous commits into `initial commit`. (`role: product-engineer; read: .agent/docs/skills/git.md;`)
</dd>
<dt class="hdlist1">Push to GitHub</dt>
<dd>
Push the local repository to a new remote GitHub repository.
</dd>
</dl>

### Stage 9: Configure GH Issues Board

<dl>
<dt class="hdlist1">Set up GH Issues facility for the project</dt>
<dd>
Use `gh` tool or instruct the Operator to use the GH Web UI to prepare the Issues facility. Make sure to set up appropriate labels and milestones, and ensure API read/write access. (`role: project-manager; read: [.agent/docs/skills/github-issues.md];`)
</dd>
</dl>

### Stage 10: Create Initial Work Issues

<dl>
<dt class="hdlist1">Draft an IMYML file</dt>
<dd>
Add all the issues to a scratch file in IMYML format. (`role: project-manager; read: .agent/docs/skills/github-issues.md; path: .agent/scratch/initial-issues.yml; with: Operator`)
</dd>
<dt class="hdlist1">Bulk create initial issues</dt>
<dd>
Use the `issuer` tool to generate remote GH Issues entries based on the issues draft file. (`role: project-manager; cmds: 'bundle exec issuer --help'; path: .agent/scratch/initial-issues.yml; upto: [product-engineer, tech-writer, devops-release-engineer, qa-testing-engineer, docops-engineer]`)
</dd>
</dl>

### Post-mission Debriefing

<dl>
<dt class="hdlist1">Review Mission Report</dt>
<dd>
Highlight outstanding or special notices from the Mission Report. (`role: Agent; with: Operator; read: .agent/reports/project-setup-mission.md`)
</dd>
<dt class="hdlist1">Suggest modifications to _this_ mission assignment</dt>
<dd>
Taking into account any bumps, blockers, or unexpected occurrences during fulfillment of this mission, recommend changes or additions to **“MISSION: Start a New DocOps Lab Project”** itself. Put yourself in the shoes of a future agent facing down an unknown project. (`role: Agent; with: Operator; path: ../lab/_docs/agent/missions/setup-new-project.adoc`).
</dd>
</dl>

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

A good output is a codebase that a human engineer could pick up and continue developing with minimal onboarding due to logical structure and conventions as well as clear documentation of the architecture, setup process, and project-specific considerations.

