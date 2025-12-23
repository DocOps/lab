# Agent Rake CLI Guide

This document is intended for AI agents operating within a DocOps Lab environment.

If you need to add or modify Rake tasks for the current project, follow the guidelines in this document.

Table of Contents

- Rake CLIs
- Rake CLI Model

## Rake CLIs

We use Rake for internal repo tasks and chores, including build operations, test-suite execution, unconventional testing, code linting and cleanup, etc.

Users of our released products should never be asked to use `rake` commands during the normal course of daily operations, if ever.

Rake is less versatile than Thor, but it is simpler for executing straightforward methods and series of methods. It likewise requires (and permits) considerably less application-specific creativity and customization.

Innovative UIs are not justified for internal tooling. Our developer-facing utilities are fairly robust, but the UI for executing them need not be.

At DocOps Lab, we save inventive interfaces for domain-optimized operations.

### Rake CLI Model

```
rake domain:action:target[option1,option2]
```

Where both `domain`` and `target` are optional, as of course are arguments that go in the braces.

Think of the domain as a component “scope” within the codebase or project.

Domains either indicate a distinct module or component within the codebase or general tasks using upstream dependencies.

No domain means local, project-specific tasks.

Example 3-part task with an optional argument

```
rake labdev:lint:docs[README.adoc]
```

In the above case, the domain is from the `docopslab-dev` library/gem.

Example 3-part task with a local domain reference

```
rake gemdo:build
```

The above command has a local domain `gemdo` for referencing commands that affect a gem that happens to be embedded in a larger repo. A code repo containing more than one gem might use:

```
rake gemdo:build:gemname
```

