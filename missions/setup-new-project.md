# MISSION: Start a New DocOps Lab Project

This document is intended for AI agents operating within a DocOps Lab environment.

An AI Agent or multiple Agents, in collaboration with a human Operator, can initialize and prepare a codebase for a new DocOps Lab project.

This codebase can be based on an existing specification document, or one can be drafted during this procedure.

Table of Contents

- Agent Roles
- Context Management for Multi-role Sessions
      - Task Assignments and Suggestions
- Prerequisite: Attention OPERATOR
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

**planner/architect (optional)**:
   If there is no specification yet, this agent works with the Operator and any relevant documentation to draft a project specification and/or definition documents.

**product engineer** :
   Initialize the basic environment and dependencies; oversee DevOps, DocOps, and QA contributions; wireframe/scaffold basic library structure.

**QA/testing engineer** :
   Set up testing frameworks and initial/demonstrative test cases.

**DevOps/release engineer** :
   Set up CI/CD pipelines, containerization, and infrastructure as code.

**project manager** :
   Review the initial project setup; create initial work issues and tasks for further development.

**tech writer** :
   Assist in writing/reviewing specification docs and README.

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

This process requires the `docopslab-dev` tooling is installed and synced, or at the very least the `.agent/docs/` library maintained by that tool be in place.

For unorthodox projects, simply copying an up-to-date version of that library to your project root directory should suffice.

## Mission Procedure

In general, the following stages are to be followed in order and tracked in a mission document.

### Stage 0: Mission Prep

**Create a mission-tracking document** :
   Write a document with detailed steps for fulfilling the mission assigned here, based on any project-specific context that might rule in or out some of the following stages or steps. (`role: project-manager; path: .agent/project-setup-mission.md`)

### Evergreen Tasks

The following tasks apply to most stages.

**Keep the mission-tracking document up to date** :
   At the end of every stage, update the progress. (`path: .agent/project-setup-mission.md`)

**Perform tests as needed** :
   Run tests to ensure the initial setup is functioning as expected. (`role: qa-testing-engineer; read: [.agent/docs/skills/tests-running.md, specs/tests/README.adoc]`)

**Update docs as needed** :
   Continuously improve the relevant `README.adoc` and other documentation based on new insights or changes in the project setup. (`role: tech-writer; read: .agent/docs/skills/asciidoc.md, .agent/docs/skills/readme-driven-dev.md, paths: [README.adoc, specs/docs/**/*.adoc, specs/tests/README.adoc]`)

### Stage 1: Project Specification

**Specification review** :
   _If the project already contains one or more specification documents (`specs/docs/*.adoc`) and/or an extensive `README.adoc` file_, review them for thoroughness and advise of missing information, ambiguities, inconsistencies, and potential pitfalls. (`role: planner-architect; with: operator; upto: [product-engineer, product-manager]`)

**Draft a specification** :
   _If no specification and no detailed `README.adoc` exists_, work with the Operator to draft a basic project specification/requirements document in AsciiDoc and data/interface definition files in YAML/SGYML. (`role: planner-architect; with: [product-manager, tech-writer]; upto: product-developer; read: [.agent/docs/skills/asciidoc.md, .agent/docs/skills/schemagraphy-sgyml.md], path: specs/docs/<subject-slug>-requirements.adoc`)

**Create/enrich README** :
   The `README.adoc` file is _the_ primary document for every DocOps Lab repo. Make it great. (`role: tech-writer; with: [planner-architect, product-manager]; upto: product-engineer; read: .agent/docs/skills/asciidoc.md, .agent/docs/skills/readme-driven-dev.md`, path: `README.adoc`)

### Stage 2: Codebase/Environment Setup

**Establish initial files** :
   Create the basic project directory structure and initial files, including `README.adoc`, `.gitignore`, `Dockerfile`, `Rakefile`, along with any necessary configuration files. (`role: product-engineer; read: .agent/docs/topics/common-project-paths.md`)

**Establish versioning** :
   Define the revision code (probably `0.1.0`) in the `README.adoc` and make sure the base module/code reads it from there as SSoT. (`role: product-engineer; read: .agent/docs/skills/readme-driven-dev.md; path: README.adoc`)

**Populate initial files** :
   Fill in the initial files with dependency requirements, boilerplate content, placeholder comments, project description, based on the Specification. (`role: product-engineer; read: .agent/docs/skills/code-commenting.md`, path: `[Rakefile, .gitignore, lib/**, <product-slug>.gemspec, etc]`)

**Instantiate environment/dependencies** :
   Install dependency libraries (usually `bundle install`, `npm install`, and so forth). (`role: product-engineer)

**Update the README** :
   Add relevant details from this stage to the project’s `README.adoc` file. Include basic setup/quickstart instructions for developers. (`role: product-engineer; upto: tech-writer; read: .agent/docs/skills/asciidoc.md, .agent/docs/skills/readme-driven-dev.md`, path: `README.adoc`)

**Commit to Git** :
   Test the `.gitignore` and any pre-commit hooks by adding and committing files. Adjust `.gitignore` as needed and amend commits until correct. (`role: product-engineer; read: .agent/docs/skills/git.md;`)

### Stage 3: Testing Framework Setup

**Create basic testing scaffold** :
   Prompt the Operator to provide relevant examples from similar repos and modify it for the current project’s use case. (`role: qa-testing-engineer; with: operator; upto: product-engineer; read: [README.adoc, specs/ .agent/docs/skills/tests-writing.md, .agent/docs/skills/rake-cli-dev.md]; path: specs/tests/`)

**Populate initial test cases** :
   Draft initial test cases that cover basic functionality and edge cases based on the project specification. (`role: qa-testing-engineer; upto: product-engineer; read: .agent/docs/skills/tests-writing.md; paths: specs/tests/rspec/`)

**Create a testing README** :
   Draft the initial docs for the testing regimen. (`role: qa-testing-engineer; upto: tech-writer; read: .agent/docs/skills/asciidoc.md, .agent/docs/skills/readme-driven-dev.md`, path: `specs/tests/README.adoc`)

**Update the project README** :
   Make a note of the tests path and docs in the main `README.adoc` file. (`role: qa-testing-engineer; upto: tech-writer; read: .agent/docs/skills/asciidoc.md, .agent/docs/skills/readme-driven-dev.md`, path: `README.adoc`)

**Commit to Git** :
   Add and commit testing files to Git. (`role: qa-testing-engineer; read: .agent/docs/skills/git.md;`)

### Stage 4: CI/CD Pipeline Setup

**Draft initial CI/CD workflows** :
   Set up GitHub Actions workflows for building, testing, and deploying the project. Integrate tests into `Rakefile` or other scripts as appropriate. (`role: devops-release-engineer; upto: product-engineer; read: .agent/docs/skills/devops-ci-cd.md; paths: [Rakefile, .github/workflows/, .scripts/**]`)

**Commit to Git** :
   Add and commit CI/CD files to Git. (`role: devops-release-engineer; read: .agent/docs/skills/git.md;`)

### Stage 5: Initial Product Code

**Write code to initial tests** :
   Implement the minimum viable code to pass the initial test cases. (`role: product-engineer; with: [Operator, qa-testing-engineer]; read: [specs/tests/rspec/**, specs/docs/*.adoc]; upto: [qa-testing-engineer, devops-release-engineer]; paths: [lib/**, specs/tests/rspec/**]`)

**Commit to Git** :
   Add and commit the initial product code to Git. (`role: product-engineer; read: .agent/docs/skills/git.md;`)

### Stage 6: Review Initial Project Setup

**Review mission report** :
   Check the mission progress document for any `TODO`s or notes from previous stages.
   Triage these and consider invoking new roles to fulfill the steps.
   (`role: project-manager; with: Operator; read: .agent/project-setup-mission.md; path: .agent/reports/project-setup-mission.md`)

**Check project against README and specs** :
   Read through the relevant specifications to ensure at least the _scaffolding_ to meet the project requirements is in place. Take note of any place the codebase falls short. (`role: project-manager; read: [README.adoc, specs/**/*.{adoc,yml,yaml}]; upto: [planner-architect, product-engineer, qa-testing-engineer, devops-release-engineer]; path: .agent/reports/project-setup-mission.md; with: Operator`)

### Stage 7: Agent Documentation

**Draft an AGENTS.md file from template** :
   Use the `AGENTS.markdown` file available through `docopslab-dev` (sync initially, then set `sync: false` in `.config/docopslab-dev.yml`). Follow the instructions in the doc to transform it into a localized edition of the prime doc. (`role: Agent; path: AGENTS.adoc`)

### Stage 8: Squash and Push to GitHUb

The repository should now be ready for sharing.

**Squash commits** :
   Squash any previous commits into `initial commit`. (`role: product-engineer; read: .agent/docs/skills/git.md;`)

**Push to GitHub** :
   Push the local repository to a new remote GitHub repository.

### Stage 9: Configure GH Issues Board

**Set up GH Issues facility for the project** :
   Use `gh` tool or instruct the Operator to use the GH Web UI to prepare the Issues facility. Make sure to set up appropriate labels and milestones, and ensure API read/write access. (`role: project-manager; read: [.agent/docs/skills/github-issues.md];`)

### Stage 10: Create Initial Work Issues

**Draft an IMYML file** :
   Add all the issues to a scratch file in IMYML format. (`role: project-manager; read: .agent/docs/skills/github-issues.md; path: .agent/scratch/initial-issues.yml; with: Operator`)

**Bulk create initial issues** :
   Use the `issuer` tool to generate remote GH Issues entries based on the issues draft file. (`role: project-manager; cmds: 'bundle exec issuer --help'; path: .agent/scratch/initial-issues.yml; upto: [product-engineer, tech-writer, devops-release-engineer, qa-testing-engineer, docops-engineer]`)

### Post-mission Debriefing

**Review Mission Report** :
   Highlight outstanding or special notices from the Mission Report. (`role: Agent; with: Operator; read: .agent/reports/project-setup-mission.md`)

**Suggest modifications to _this_ mission assignment** :
   Taking into account any bumps, blockers, or unexpected occurrences during fulfillment of this mission, recommend changes or additions to **“MISSION: Start a New DocOps Lab Project”** itself. Put yourself in the shoes of a future agent facing down an unknown project. (`role: Agent; with: Operator; path: ../lab/_docs/agent/missions/setup-new-project.adoc`).

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

