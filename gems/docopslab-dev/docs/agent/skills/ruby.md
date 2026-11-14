# Ruby Coding Guide for DocOps Lab AI Agents

This document is intended for AI agents operating within a DocOps Lab environment.

## Conventions

DocOps Lab largely follows Ruby’s community conventions, with some exceptions. The rule statements, rationale, enforcement classifications, and examples below are generated from`gems/docopslab-dev/specs/data/ruby-conventions-def.yml`. The definition is the source to edit when a convention changes.

### Architecture and responsibility

Choose a Ruby form from the role and lifecycle of the code, never from a target class-to-module ratio.

#### Choose classes and modules by role

**Rule:**
   Use a class for stateful entities, lifecycle collaborators, value records, errors, and framework-required subclasses; use a module for namespaces, stateless operations, protocols designed for inclusion, filters, and compatibility facades.

**Rationale:**
   Role and lifecycle expose design intent, while class-to-module ratios say nothing reliable about maintainability.

**Enforcement:**
   `doc-only`; reviewed in architecture review.

   No ratio is measured or gated.

Good: A change carries identity and release state in an instance.

```ruby
class Change
  def initialize attrs = {}, release:
    @release = release
    @summ = attrs['summ']
  end
end
```

Source pattern: `releasehx/lib/releasehx/rhyml/change.rb`.

Bad: A stateless namespace is instantiated without a lifecycle.

```ruby
class AsciiDoc
  def initialize; end
  def load_attributes path
    # Pure conversion with no retained state.
  end
end
```

Source pattern: `Counterexample derived from asciisourcerer/lib/sourcerer/asciidoc.rb`.

**Migration:**
   Existing role mismatches are changed only when their behavior or dependencies are already changing.

#### Keep module state visible and replaceable

**Rule:**
   Do not add mutable module state unless the module owns a process-wide lifecycle and provides deterministic reset or replacement.

**Rationale:**
   Hidden singleton state couples tests and embedding consumers to call order.

**Enforcement:**
   `spec`; blocking for new docopslab-dev assignments.

   An architecture spec rejects module instance-variable assignments not listed in this definition.

Good: A temporary cache-root override is restored even after failure.

```ruby
def with_root_override path
  previous = @root_override
  @root_override = path
  yield
ensure
  @root_override = previous
end
```

Source pattern: `lab/gems/docopslab-dev/lib/docopslab/dev/library/cache.rb`.

Bad: A module cache has no replacement or reset boundary.

```ruby
def settings
  @settings ||= load_settings
end
```

Source pattern: `Counterexample derived from lab/gems/docopslab-dev/lib/docopslab/dev/data_utils.rb`.

**Migration:**
   The allowlist records existing debt and must not grow without an approved lifecycle exception.

#### Put behavior beside its governing responsibility

**Rule:**
   Put invariant-preserving behavior on the stateful class, pure transforms in named modules, one-shot coordination in focused operation modules, and reusable configured workflows in collaborator instances.

**Rationale:**
   Placement should reveal the state and dependencies that govern a behavior.

**Enforcement:**
   `doc-only`; reviewed when responsibilities or dependencies change.

   File length alone does not require a split.

Good: Change predicates remain with the state they interpret.

```ruby
class Change
  def breaking? = tags.include?('breaking')
end
```

Source pattern: `releasehx/lib/releasehx/rhyml/change.rb`.

Bad: A generic utility takes ownership of an entity invariant.

```ruby
module Utils
  def self.breaking? change
    change.tags.include?('breaking')
  end
end
```

Source pattern: `Counterexample derived from releasehx/lib/releasehx/rhyml/change.rb`.

**Migration:**
   Generic utility namespaces should be split only as affected workflows are revised.

#### Treat singleton syntax as a readability choice

**Rule:**
   Use either `def self.method` or `class << self` according to local readability; neither form carries architectural meaning.

**Rationale:**
   Both forms expose the same kind of callable surface, and forced conversion creates churn without clarifying responsibility.

**Enforcement:**
   `doc-only`; locally reviewed.

   Keep one form coherent within a small related method group when practical.

Good: A singleton-method group shares one explicit visibility scope.

```ruby
class << self
  def project_attributes
    # Load attributes.
  end

  def reset_project_attributes!
    # Reset the cache.
  end
end
```

Source pattern: `lab/gems/docopslab-dev/lib/docopslab/dev/data_utils.rb`.

Bad: A mechanical rewrite is justified as an architecture improvement.

```ruby
# Do not rewrite this only to change singleton syntax.
def self.project_attributes
  # Load attributes.
end
```

Source pattern: `Counterexample derived from lab/gems/docopslab-dev/lib/docopslab/dev/data_utils.rb`.

**Migration:**
   No existing singleton syntax changes are required.

#### Use dual module APIs intentionally

**Rule:**
   Use `module_function` only when callers need module-level access and an including class needs the same methods as private instance behavior.

**Rationale:**
   The directive creates two API forms and can obscure which one consumers are expected to call.

**Enforcement:**
   `doc-only`; reviewed at the public API boundary.

   Ordinary stateless namespaces may use explicit singleton methods instead.

Good: Frontmatter helpers deliberately expose one small functional API.

```ruby
module YamlFrontmatter
  module_function

  def extract source_text
    # Parse frontmatter.
  end
end
```

Source pattern: `asciisourcerer/lib/sourcerer/yaml_frontmatter.rb`.

Bad: A large operations namespace duplicates every method as an instance API without a consumer.

```ruby
module SyncOps
  module_function
  # Many workflow methods follow, but no includer exists.
end
```

Source pattern: `Counterexample derived from lab/gems/docopslab-dev/lib/docopslab/dev/sync_ops.rb`.

**Migration:**
   Existing uses remain unless their public API is already being revised.

### Definitions and extensions

Keep data contracts visible and keep executable behavior in Ruby.

#### Use YAML for definitions and Ruby for behavior

**Rule:**
   Put human-edited product definitions, schema-validated settings, and records with multiple generated consumers in YAML; keep intrinsic method defaults and executable behavior in Ruby.

**Rationale:**
   YAML improves human editing and derivation only when the content is genuinely data rather than indirect control flow.

**Enforcement:**
   `spec`; blocking where a YAML definition has a runtime consumer.

   Contract specs must connect the definition, resolver, and generated or runtime consumer.

Good: Task descriptions and examples are data while task execution remains Ruby.

```yaml
labdev:
  lint:
    ruby:
      _desc: Run RuboCop on Ruby files
```

Source pattern: `lab/gems/docopslab-dev/specs/data/tasks-def.yml`.

Bad: Executable callbacks are encoded as strings in configuration.

```yaml
callback: "DocOpsLab::Dev.run_rubocop(path)"
```

Source pattern: `Counterexample derived from lab/gems/docopslab-dev/specs/data/tasks-def.yml`.

**Migration:**
   Duplicate Ruby and YAML defaults require compatibility review before consolidation.

#### Keep specifications and tests under specs

**Rule:**
   Store definition files in `specs/data/`, natural-language requirements in `specs/docs/`, and Ruby examples in `specs/tests/rspec/`.

**Rationale:**
   One specification tree keeps definitions, requirements, and their verification discoverable together.

**Enforcement:**
   `doc-only`; reviewed when adding a specification asset.

   Runtime resources may live under `lib/` when packaging or direct runtime lookup requires that location.

Good: The task registry is stored beside its contract spec.

```text
specs/data/tasks-def.yml
specs/tests/rspec/tasks_spec.rb
```

Source pattern: `lab/gems/docopslab-dev/specs/data/tasks-def.yml`.

Bad: A product definition is hidden among implementation files without a packaging need.

```text
lib/docopslab/dev/tasks-def.yml
```

Source pattern: `Counterexample derived from lab/gems/docopslab-dev/specs/data/tasks-def.yml`.

**Migration:**
   Existing packaged runtime data may remain where moving it would change lookup behavior.

#### Match extension machinery to discovery needs

**Rule:**
   Use direct namespaced calls for internal features, a factory or registry for named discovery, a public registration API for third-party plugins, and a framework’s native registration for framework extensions.

**Rationale:**
   A universal registry duplicates framework contracts and adds indirection where discovery is not required.

**Enforcement:**
   `doc-only`; reviewed when an extension family is introduced.

   Shared RSpec contracts are required only when implementations claim substitutable behavior.

Good: Liquid filters use Liquid’s native module-level filter contract.

```ruby
module Filters
  module_function
  # Liquid filter methods follow.
end
```

Source pattern: `asciisourcerer/lib/sourcerer/jekyll/liquid/filters.rb`.

Bad: A second registry wraps a framework that already owns discovery.

```ruby
FILTERS.register(:native_liquid, Filters)
```

Source pattern: `Counterexample derived from asciisourcerer/lib/sourcerer/jekyll/liquid/filters.rb`.

**Migration:**
   Do not replace an existing public extension mechanism without a compatibility window.

#### Keep implementation and specifications distinct

**Rule:**
   Put runtime Ruby under `lib/`, definitions and tests under `specs/`, generated build inputs under `build/`, and runtime-generated artifacts under an application-appropriate underscore path.

**Rationale:**
   The layout distinguishes shipped behavior, product contracts, pre-runtime inputs, and disposable runtime output.

**Enforcement:**
   `doc-only`; reviewed when adding a top-level path.

   Namespace-to-path correspondence may remain pragmatic when established names or sibling operation families are clearer. Configure the project’s RuboCop path transform or a narrow exclusion when an intentional acronym path differs from RuboCop’s default transform.

Good: Runtime behavior and its tests occupy distinct trees.

```text
lib/docopslab/dev/cast_ops.rb
specs/tests/rspec/cast_ops_spec.rb
```

Source pattern: `lab/gems/docopslab-dev`.

Bad: Tests are mixed into the shipped library tree.

```text
lib/docopslab/dev/cast_ops_spec.rb
```

Source pattern: `Counterexample derived from lab/gems/docopslab-dev`.

**Migration:**
   Do not move established public require paths solely to create namespace symmetry.

#### Write shared documentation in AsciiDoc

**Rule:**
   Use AsciiDoc for user-facing prose and for prose stored in YAML string nodes; reserve Markdown for tool-owned files that require it.

**Rationale:**
   One authoring language keeps includes, attributes, and generated documentation consistent across DocOps Lab.

**Enforcement:**
   `doc-only`; supplemented by documentation linting.

   Ruby API explanation remains in RDoc or YARD comments next to the code.

Good: A YAML documentation node uses AsciiDoc inline literals.

```yaml
docs: |
  Use `labdev:show:scripts` to see the available scripts.
```

Source pattern: `lab/gems/docopslab-dev/specs/data/tasks-def.yml`.

Bad: A YAML documentation node uses Markdown fenced code.

```yaml
docs: |
  ```sh
  bundle exec rake task
  ```
```

Source pattern: `Counterexample derived from lab/gems/docopslab-dev/specs/data/tasks-def.yml`.

**Migration:**
   Convert affected prose when its containing documentation is next revised.

### Errors and presentation boundaries

Make library outcomes predictable and translate them only at an application boundary.

#### Signal outcomes according to caller expectations

**Rule:**
   Use nil or an empty collection for documented ordinary absence, booleans for predicates, `ArgumentError` for invalid direct arguments, product errors for integration failures, and result records for recoverable batch failures.

**Rationale:**
   A caller should be able to distinguish ordinary data, recoverable partial work, and exceptional failure without parsing messages.

**Enforcement:**
   `doc-only`; reviewed as part of public API design.

   Add product-error subclasses only when callers can respond differently.

Good: Invalid direct arguments raise Ruby’s conventional argument error.

```ruby
raise ArgumentError, 'attrs must be a Hash' unless attrs.is_a?(Hash)
```

Source pattern: `releasehx/lib/releasehx/rhyml/change.rb`.

Bad: Invalid input is converted into a false value with no diagnosis.

```ruby
return false unless attrs.is_a?(Hash)
```

Source pattern: `Counterexample derived from releasehx/lib/releasehx/rhyml/change.rb`.

**Migration:**
   Changes to public nil, false, message, or exception behavior require caller-focused compatibility specs.

#### Rescue broadly only at a boundary

**Rule:**
   Rescue `StandardError` only at process, task, CLI, plugin, or external-service boundaries, and preserve the original cause when translating it.

**Rationale:**
   Broad rescue inside reusable behavior conceals programmer errors and makes failure categories unreliable.

**Enforcement:**
   `doc-only`; advisory until boundary paths are classified.

   A stable path-based check may replace review after the inventory proves its signal.

Good: A cache lookup treats an unreadable external file as ordinary unavailability.

```ruby
def stored_head
  File.read(head_path).strip
rescue StandardError
  nil
end
```

Source pattern: `lab/gems/docopslab-dev/lib/docopslab/dev/library/cache.rb`.

Bad: Domain behavior swallows every defect and returns nil.

```ruby
def breaking?
  tags.include?('breaking')
rescue StandardError
  nil
end
```

Source pattern: `Counterexample derived from releasehx/lib/releasehx/rhyml/change.rb`.

**Migration:**
   Existing broad rescues must be inventoried before any blocking path rule is enabled.

#### Keep reusable library APIs terminal-independent

**Rule:**
   Allow output in task and CLI presentation roles, but do not require a terminal or call `exit` or `abort` from reusable parsing, configuration, conversion, or path APIs.

**Rationale:**
   Embedding consumers need to control reporting and process lifetime.

**Enforcement:**
   `doc-only`; blocking in review for newly added reusable APIs.

   Inject a reporter only when a workflow has meaningful progress to report.

Good: A parser returns a value without writing to the terminal.

```ruby
def extract source_text
  parsed = YAML.safe_load(source_text)
  parsed.is_a?(Hash) ? parsed : {}
end
```

Source pattern: `asciisourcerer/lib/sourcerer/yaml_frontmatter.rb`.

Bad: A reusable parser terminates its host process.

```ruby
def extract source_text
  abort 'Invalid frontmatter' unless source_text
end
```

Source pattern: `Counterexample derived from asciisourcerer/lib/sourcerer/yaml_frontmatter.rb`.

**Migration:**
   Presentation extraction in mature workflows should follow feature work rather than trigger a blanket rewrite.

#### Match command tooling to its audience

**Rule:**
   Use Rake for internal developer workflows and a user-facing CLI framework such as Thor for product commands.

**Rationale:**
   Rake integrates internal build tasks, while a dedicated CLI framework provides discoverable user commands and option handling.

**Enforcement:**
   `doc-only`; reviewed when introducing a command surface.

   Reusable behavior must remain below either presentation layer.

Good: ReleaseHx exposes user commands through Thor.

```ruby
class CLI < Thor
```

Source pattern: `releasehx/lib/releasehx/cli.rb`.

Bad: A public product command is hidden as an undocumented build task.

```ruby
task :publish_for_end_users do
  # Product command behavior.
end
```

Source pattern: `Counterexample derived from releasehx/lib/releasehx/cli.rb`.

**Migration:**
   Existing command surfaces change only with an explicit compatibility plan.

### Verification and evaluation

Test contracts and require every blocking command to return a truthful process status.

#### Test cross-file and substitutable contracts

**Rule:**
   Add contract specs for YAML-to-Ruby definitions and for adapter families whose implementations claim the same behavior.

**Rationale:**
   Contract boundaries fail through drift even when each file or implementation passes isolated tests.

**Enforcement:**
   `spec`; blocking for each declared contract.

   Do not impose shared examples on callbacks that share registration but not behavior.

Good: The task spec compares every described YAML task with registered Rake tasks.

```ruby
missing = described_yaml_paths - all_rake_task_names
expect(missing).to be_empty
```

Source pattern: `lab/gems/docopslab-dev/specs/tests/rspec/tasks_spec.rb`.

Bad: A definition and implementation are tested only for independent parseability.

```ruby
expect(YAML.load_file(path)).to be_a(Hash)
expect(rake_tasks).not_to be_empty
```

Source pattern: `Counterexample derived from lab/gems/docopslab-dev/specs/tests/rspec/tasks_spec.rb`.

**Migration:**
   Add contracts at active boundaries before reorganizing the data they connect.

#### Make every blocking gate truthful

**Rule:**
   A blocking Rake task or hook must produce diagnostics and return a nonzero process status when its underlying check fails or crashes.

**Rationale:**
   A green shell status that contains failed checks defeats hooks, CI, and automation.

**Enforcement:**
   `spec`; blocking once each gate is implemented.

   Subprocess specs must cover one passing fixture and one deliberately failing fixture.

Good: A task converts a false tool result into Rake failure.

```ruby
success = Dev.run_rubocop(target, opts)
raise 'RuboCop failed' unless success
```

Source pattern: `Target contract for lab/gems/docopslab-dev/lib/docopslab/dev/tasks.rb`.

Bad: A task discards the tool result and exits successfully.

```ruby
Dev.run_rubocop(target, opts)
```

Source pattern: `Existing migration case in lab/gems/docopslab-dev/lib/docopslab/dev/tasks.rb`.

**Migration:**
   Failure propagation and subprocess coverage are the first quality-harness implementation priority.

#### Separate coaching from gating

**Rule:**
   Use `labdev:eval:coach[scope]` for complete advisory findings and `labdev:eval:gate[scope]` for the stable blocking policy.

**Rationale:**
   Developers need full visibility without making every experimental signal a release blocker.

**Enforcement:**
   `doc-only`; canonical interface for the planned quality harness.

   RuboCop owns Ruby metric thresholds; the coach explains and groups them without duplicating policy.

Good: The command name makes blocking behavior explicit.

```bash
bundle exec rake 'labdev:eval:gate[branch]'
```

Source pattern: `Approved DocOps Lab quality-harness contract`.

Bad: One ambiguous command changes between advisory and blocking behavior.

```bash
bundle exec rake 'labdev:quality[branch]'
```

Source pattern: `Counterexample derived from the approved quality-harness contract`.

**Migration:**
   Implement the commands only after existing lint tasks propagate failures truthfully.

### Syntax and local style

Use the shared RuboCop configuration for mechanically decidable local style.

#### Use conventional Ruby names

**Rule:**
   Use `snake_case` for variables and methods, `CamelCase` for classes and modules, and `SCREAMING_SNAKE_CASE` for constants.

**Rationale:**
   Conventional names make Ruby APIs predictable without constraining product vocabulary.

**Enforcement:**
   `rubocop`; configured where a corresponding naming cop applies; not reliably blocking until the canonical task propagates failure.

   Descriptive domain terms are preferred over abbreviations that are not already established.

Good: A constant and predicate use their conventional forms.

```ruby
DEFAULT_CANONICAL_PREFIX = 'universal-'
def self.canonical? tag
```

Source pattern: `asciisourcerer/lib/sourcerer/sync/block_parser.rb`.

Bad: Constant and method casing obscure their Ruby roles.

```ruby
defaultCanonicalPrefix = 'universal-'
def self.Canonical tag
```

Source pattern: `Counterexample derived from asciisourcerer/lib/sourcerer/sync/block_parser.rb`.

**Migration:**
   Existing public names require compatibility review before renaming.

#### Indent Ruby with two spaces

**Rule:**
   Use two spaces for each Ruby indentation level and never use tabs for indentation.

**Rationale:**
   The shared indentation makes nested Ruby structure visually consistent across projects.

**Enforcement:**
   `rubocop`; configured; not reliably blocking until the canonical task propagates failure.

   Enforced by RuboCop’s enabled layout cops and default indentation width.

Good: A method body is indented by two spaces.

```ruby
def extract source_text
  source_text.to_s
end
```

Source pattern: `asciisourcerer/lib/sourcerer/yaml_frontmatter.rb`.

Bad: A method body is indented by four spaces.

```ruby
def extract source_text
    source_text.to_s
end
```

Source pattern: `Counterexample derived from asciisourcerer/lib/sourcerer/yaml_frontmatter.rb`.

**Migration:**
   RuboCop automatic correction can repair most violations.

#### Keep Ruby lines within 120 columns

**Rule:**
   Keep Ruby source lines within 120 columns, except for the configured comment and RDoc patterns.

**Rationale:**
   The limit keeps code reviewable without forcing unhelpful wrapping of explanatory comments.

**Enforcement:**
   `rubocop`; configured; not reliably blocking until the canonical task propagates failure.

   Enforced by `Layout/LineLength` with a maximum of 120.

Good: A long call is split at argument boundaries.

```ruby
definition = SchemaGraphy::Loader.load_yaml_with_attributes(
  definition_path,
  attrs)
```

Source pattern: `releasehx/lib/releasehx/configuration.rb`.

Bad: Unrelated operations are compressed onto one long line.

```ruby
definition = load_definition(path); settings = apply_schema(definition['properties'], user_config); config = new(settings)
```

Source pattern: `Counterexample derived from releasehx/lib/releasehx/configuration.rb`.

**Migration:**
   RuboCop automatic correction may require a manual readability pass.

#### Omit parentheses in method definitions

**Rule:**
   Define methods without parentheses around their parameters.

**Rationale:**
   This is the established DocOps Lab Ruby signature style.

**Enforcement:**
   `rubocop`; configured; not reliably blocking until the canonical task propagates failure.

   Enforced by `Style/MethodDefParentheses` with `require_no_parentheses`.

Good: A method definition leaves its parameter list open.

```ruby
def self.load_attributes path, user_only: false
```

Source pattern: `asciisourcerer/lib/sourcerer/asciidoc.rb`.

Bad: A method definition wraps its parameters in parentheses.

```ruby
def self.load_attributes(path, user_only: false)
```

Source pattern: `Counterexample derived from asciisourcerer/lib/sourcerer/asciidoc.rb`.

**Migration:**
   RuboCop automatic correction can repair violations.

#### Use parentheses for calls with arguments

**Rule:**
   Use parentheses for method calls with arguments and omit empty parentheses from argument-free calls.

**Rationale:**
   Call-site parentheses make argument boundaries explicit while preserving concise argument-free calls.

**Enforcement:**
   `rubocop`; configured; not reliably blocking until the canonical task propagates failure.

   Enforced by `Style/MethodCallWithArgsParentheses` with documented allowances for calls spanning multiple lines and for chaining.

Good: A method call encloses its argument.

```ruby
File.join(root, 'current')
```

Source pattern: `lab/gems/docopslab-dev/lib/docopslab/dev/library/cache.rb`.

Bad: A method call leaves its argument bare.

```ruby
File.join root, 'current'
```

Source pattern: `Counterexample derived from lab/gems/docopslab-dev/lib/docopslab/dev/library/cache.rb`.

**Migration:**
   RuboCop automatic correction can repair most violations.

#### Prefer single-quoted strings

**Rule:**
   Use single quotes unless interpolation or an escape sequence requires double quotes.

**Rationale:**
   Literal intent remains visible and consistent across the reference gems.

**Enforcement:**
   `rubocop`; configured; not reliably blocking until the canonical task propagates failure.

   Enforced by `Style/StringLiterals` and `Style/StringLiteralsInInterpolation`.

Good: A literal path segment uses single quotes.

```ruby
File.join(root, 'current')
```

Source pattern: `lab/gems/docopslab-dev/lib/docopslab/dev/library/cache.rb`.

Bad: A literal without interpolation uses double quotes.

```ruby
File.join(root, "current")
```

Source pattern: `Counterexample derived from lab/gems/docopslab-dev/lib/docopslab/dev/library/cache.rb`.

**Migration:**
   RuboCop automatic correction can repair violations.

#### Freeze string literals by file

**Rule:**
   Begin Ruby source files with `# frozen_string_literal: true`.

**Rationale:**
   File-level frozen literals avoid accidental mutation and allocation without scattering calls to `freeze`.

**Enforcement:**
   `rubocop`; configured; not reliably blocking until the canonical task propagates failure.

   Enforced by `Style/FrozenStringLiteralComment`.

Good: A Ruby source file declares frozen literals first.

```ruby
# frozen_string_literal: true
```

Source pattern: `releasehx/lib/releasehx/configuration.rb`.

Bad: A Ruby source file has no frozen-literal declaration.

```ruby
require 'psych'
```

Source pattern: `Counterexample derived from releasehx/lib/releasehx/configuration.rb`.

**Migration:**
   RuboCop automatic correction can add the header.

#### Calibrate metrics before adding gates

**Rule:**
   Keep the shared method-length baseline at 25 during study, honor documented project overrides, and do not enable new complexity or size gates until reference-code distributions and upper-tail examples are reviewed.

**Rationale:**
   Generic thresholds confuse unfamiliarity with risk and create exclusions before the signal is understood.

**Enforcement:**
   `rubocop`; method length follows the effective project configuration but is not reliably blocking until the canonical task propagates failure; other shared metrics remain disabled pending calibration.

   RuboCop is the sole threshold source; no class-to-module ratio is ever measured.

Good: One shared configuration owns the active method-length threshold.

```yaml
Metrics/MethodLength:
  Max: 25
```

Source pattern: `lab/gems/docopslab-dev/assets/config-packs/rubocop/base.yml`.

Bad: A coaching tool silently invents a second threshold.

```yaml
habit_hooks:
  method_length: 15
```

Source pattern: `Counterexample derived from the DocOps Lab quality-harness proposal`.

**Migration:**
   Run a threshold study before enabling complexity, nesting, class-size, or module-size gates.

See [DocOps Lab Code Commenting Guidance](/docs/code-commenting/) for detailed Ruby commenting conventions.

## Agent Workflow

1. Read the convention rule and its enforcement classification before choosing a Ruby structure.
2. Treat `doc-only` rules as review requirements rather than inventing a mechanical proxy.
3. Add or update a contract spec when a rule is classified as `spec`.
4. Run `bundle exec rake labdev:lint:ruby` after changing Ruby source or Ruby-generating scripts.
5. Run scratch files through the target project’s lint task and effective configuration; standalone syntax checks do not substitute for the project policy.
6. Run the relevant RSpec task when the repository provides one.
7. Report a failing command and its actual process status; never infer success from diagnostics alone.

The machine-readable source is `gems/docopslab-dev/specs/data/ruby-conventions-def.yml` in DocOps/lab. Do not edit the generated `_ruby-conventions.adoc` partial.

The planned evaluation interfaces are `labdev:eval:coach[scope]` for complete coaching output and`labdev:eval:gate[scope]` for stable blocking policy. Do not claim that either interface is available until the current project registers the task.

## RuboCop Config

```
# RuboCop configuration for DocOps Lab projects
# This is the baseline configuration distributed via docopslab-dev

plugins:
  - rubocop-rspec

AllCops:
  TargetRubyVersion: 3.2
  NewCops: enable
  DisplayCopNames: true
  DisplayStyleGuide: true

Style/MethodDefParentheses:
  EnforcedStyle: require_no_parentheses

Style/MethodCallWithArgsParentheses:
  EnforcedStyle: require_parentheses
  AllowParenthesesInMultilineCall: true
  AllowParenthesesInChaining: true

# Allow longer lines for documentation
Layout/LineLength:
  Max: 120
  AllowedPatterns:
    - '\A\s*#.*\z' # Comments
    - '\A\s*\*.*\z' # Rdoc comments

# Current inherited gate during the cross-repository threshold study.
# Change this value only after reviewing distributions and upper-tail examples.
Metrics/MethodLength:
  Max: 25

# Allow longer blocks for Rake tasks and RSpec
Metrics/BlockLength:
  AllowedMethods:
    - describe
    - context
    - feature
    - scenario
    - let
    - let!
    - subject
    - task
    - namespace
  Max: 50

# Documentation not required for internal tooling
Style/Documentation:
  Enabled: false

# Allow TODO comments
Style/CommentAnnotation:
  Keywords:
    - TODO
    - FIXME
    - OPTIMIZE
    - HACK
    - REVIEW

Style/CommentedKeyword:
  Enabled: false

Style/StringLiterals:
  Enabled: true
  EnforcedStyle: single_quotes

Style/StringLiteralsInInterpolation:
  Enabled: true
  EnforcedStyle: single_quotes

Style/FrozenStringLiteralComment:
  Enabled: true
  EnforcedStyle: always

Layout/FirstParameterIndentation:
  EnforcedStyle: consistent

Layout/ParameterAlignment:
  EnforcedStyle: with_fixed_indentation

Layout/MultilineMethodCallBraceLayout:
  EnforcedStyle: same_line

Layout/MultilineMethodCallIndentation:
  EnforcedStyle: aligned

Layout/FirstMethodArgumentLineBreak:
  Enabled: true

Layout/TrailingWhitespace:
  Enabled: true

Layout/EmptyLineAfterGuardClause:
  Enabled: true

Layout/HashAlignment:
  Enabled: false

Layout/SpaceAroundOperators:
  Enabled: false

Layout/SpaceAroundEqualsInParameterDefault:
  Enabled: false
  EnforcedStyle: no_space

# These metrics remain advisory candidates until the reference-repository
# calibration study demonstrates stable signal and the Operator approves gates.
# RuboCop remains the sole threshold source when any of them are enabled.
Metrics/AbcSize:
  Enabled: false

Metrics/CyclomaticComplexity:
  Enabled: false

Metrics/PerceivedComplexity:
  Enabled: false

Lint/UnusedMethodArgument:
  Enabled: true

Lint/UselessAssignment:
  Enabled: true

Lint/IneffectiveAccessModifier:
  Enabled: true

Security/YAMLLoad:
  Enabled: false # Projects may intentionally use unsafe YAML loading

Security/Eval:
  Enabled: true # Catch and replace with safer alternatives

# Disable Naming/PredicateMethod - we use generate_, run_, sync_, etc for actions
Naming/PredicateMethod:
  Enabled: false
```

