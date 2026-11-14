# Ruby Quality Evaluation Boundaries

This document is intended for AI agents operating within a DocOps Lab environment.

## Responsibilities

**RuboCop** owns formatting, lint, security cops, and approved numeric Ruby thresholds.

**RSpec** owns behavioral contracts, definition agreement, extension-family contracts, architecture allowlists, and process-status behavior.

**Documentation and review** own responsibility placement and other judgments that do not have stable mechanical signals.

**Habit Hooks** may explain and group findings, but it must not duplicate RuboCop thresholds.

## Command Contracts

**`bundle exec rake labdev:lint:ruby`:**
   Runs the current Ruby linter through the project-owned interface.

**`bundle exec rake 'labdev:eval:coach[scope]'`:**
   Produces complete advisory output across `all`, `branch`, or one path.

**`bundle exec rake 'labdev:eval:gate[scope]'`:**
   Applies the approved blocking policy across `all`, `branch`, or one path.

The evaluation tasks are the canonical planned interface until the quality-harness package implements and registers them. Callers must check task availability before invoking them.

## Implementation Order

1. Make existing lint tasks propagate false results and tool crashes as nonzero process statuses.
2. Prove each gate with passing and deliberately failing subprocess fixtures.
3. Introduce coaching and gating as separate tasks.
4. Measure reference repositories before approving additional metric thresholds.
5. Add a branch-scoped gate to hooks only after runtime and failure behavior are deterministic.

## Baselines and Exclusions

Do not introduce a hidden debt baseline for new scaffolding.

Use narrow, documented exclusions for established code only when a rule has known signal and a current violation cannot yet be changed safely.

Never measure class-to-module or singleton-to-instance ratios as a quality gate.

## Agent Application

Check that a task is registered before invoking a planned evaluation interface.

Report the command’s actual process status with its diagnostics.

Do not convert a documented review judgment into a new mechanical threshold.

Do not expand an architecture allowlist or RuboCop exclusion without explaining the concrete exception.

