# Bash CLI Development for Agents

This document is intended for AI agents operating within a DocOps Lab environment.

> **TIP:** Use this guide in combination with the general Bash coding skill.

Table of Contents

- Bash CLIs
  - Bash CLI Model
- General CLI Principles
  - When NOT to Use a CLI
  - Semantic CLI Namespaces
  - General CLI Conventions

## Bash CLIs

Bash scripts are often used for simple CLIs that wrap around more complex operations. Most repo-wide chores that do not require specialized Ruby-based tools like Asciidoctor or other gems are handled with Bash scripts (The significant exception to this are multi-repo libraries like the [DocOps Lab Devtool](/docs/lab-dev-setup/).)

The one truly major Bash CLI we maintain is `docksh`, our Docker shell utility for launching properly configured containers for development, testing, and deployment (sourced in `box`).

### Bash CLI Model

Base CLIs are relatively open ended. Developers should consider how the script might change, but unless it is intended to be elaborate from the start, there is not much reason to fuss over complicated structures.

> **TIP:** See [DocOps Lab Bash Coding Guide](/docs/bash-styles/) for details about implementing Bash CLIs.

Let’s examine our typical Bash script CLI structure:

```
./bashscript.sh [arguments] [options]
```

If a Bash script is likely to eventually need to encompass multiple arguments or options, consider making it a Rake task and invoking Ruby scripts, instead.

## General CLI Principles

Most of our user-facing applications are Ruby gems, and most of those are intended to be used via three primary interfaces:

1. An application specific, openly designed CLI utility.

2. An application configuration file.

3. Subject-matter content or domain-specific data of some kind.

By way of these three interfaces, users can operate the application in a way that is optimized for their particular use case.

CLIs should allow for runtime configuration overrides and even runtime content/data overrides. But most of all they should focus on conveniently putting power in users' hands.

This means leaving the CLI model open to the task at hand, but it also means adhering to some conventions that apply generally to both Ruby and Bash CLIs.

### When NOT to Use a CLI

Even when an application offers a mature, well-designed CLI, there are times when either an application programming interface (API) or a domain-specific language (DSL) is preferable. Typically we want to keep complicated shell commands out of core products and CI/CD pipelines, in favor of native or RESTful APIs or else config-driven or DSL-driven utilities.

### Semantic CLI Namespaces

When designing CLIs, consider the namespaces of the elements we use: subcommands, arguments, and options/flags.

Subcommands should be verbs or nouns that declare operations or contexts. At each position, these elements should be organizable into meaningful categories.

Arguments should be meaningful nouns that represent the primary _subject or subjects_ of the command.

### General CLI Conventions

The definitive reference on CLI design is the [CLI Guidelines](https://clig.dev/) project.

#### Option format

<dl>
<dt class="hdlist1">Use spaces rather than `=` to assign values to options.</dt>
<dd>
Flag forms such as `--option-name value` are preferred over `--option-name=value`.
</dd>
<dt class="hdlist1">Provide long- and short- form flag aliases for common options.</dt>
<dd>
For ex: `-h` and `--help`, `-c` and `--config`.
</dd>
<dt class="hdlist1">Use `--no-` prefix for negated boolean flags when applicable.</dt>
<dd>
For ex: `--no-cache` to disable caching.
</dd>
</dl>

#### Command structure

<dl>
<dt class="hdlist1">Use subcommand only with apps that perform categorically diverse operations,</dt>
<dd>
Prefer flag combinations when possible. Subcommands signal a shift in execution context, and thus they can be greatly helpful when needed. Otherwise, reserve the first argument slot for something a meaningful arbitrary argument.

A CLI with very handy subcommands

```
git fetch
git commmit
git merge
```

No subcommand needed

```
rhx 1.2.1 --config test-config.yml --mapping apis/jira.yml --verbose --fetch --yaml
rhx 1.2.1 --config test-config.yml --html
```

And yes, of course you can combine fixed subcommands with arbitrary arguments.

```
git diff README.adoc
```
</dd>
<dt class="hdlist1">Avoid using Unix-style argument structures.</dt>
<dd>
Arbitrary arguments should come _before_ options, even if that is counter-intuitive. Typically in our apps, users are modifying commands that get executed on the same target, so if the target is an arbitrary file path or version number, it should closely follow the command as an early argument.

Preferred argument order

```
cliname targetfile --option1 value1 --option2 value2 --verbose --force
```

This structure lets users more conveniently change the parts of the command-line that will need more frequent changing.
</dd>
<dt class="hdlist1">Accommodate Unix-style CLIs by adding named options for every arbitrary argument supported.</dt>
<dd>
The trick is to enable those cases where the subject path or code _is_ what gets changed most often.

```
rhx --yaml --version 1.2.6
rhx --yaml --version 1.3.1
```
</dd>
</dl>

