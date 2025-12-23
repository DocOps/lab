# Ruby Coding Guide for DocOps Lab AI Agents

This document is intended for AI agents operating within a DocOps Lab environment.

## Conventions

DocOps Lab largely follows Ruby’s community conventions, with some exceptions. Conventions are either reiterated or clarified here.

However, conventions are not exhaustively listed, and deviations are rarely pointed out as such.

### Naming Conventions

- Use `snake_case` for variable and method names.
- Use `CamelCase` for class and module names.
- Use `SCREAMING_SNAKE_CASE` for constants.
- Use descriptive names that convey the purpose of the variable, method, or class.
- Avoid abbreviations unless they are widely understood.
- Use verbs for method names to indicate actions.
- Use nouns for class and module names to indicate entities.

### Architectural Conventions

- Use classes and class instance methods for objects that work like _objects_ — they have state and do not act on other objects' state.
- Use module methods acting on objects or carrying out general operations/utility functions.
- Use Rake for internal (developer) CLI; use Thor for user-facing CLI
- Gems may begin life as a module within another gem.

### Path Conventions

- Use `lib/` for main application code.

   - `lib/<project_name>.rb` for the main file
   - `lib/<project_name>/` for supporting files and modules
   - `lib/<project_name>/<module_name>/` for submodules
- Use `spec/` for specifications and tests.
- Use `docs/` or `_docs/` for documentation.
- Use `build/` for pre-runtime artifacts.
- Use `_build/` as default in applications that generate files at runtime, unless another path is more appropriate (ex: `_site/` in Jekyll-centric apps).
- Do NOT assume or insist upon perfect alignment with Ruby path conventions:

   - `SomeModule` or `SomeClass` may be sourced at `lib/some_module.rb` or `lib/some_class.rb` instead of `lib/some/module.rb` or `lib/some/class.rb`.
   - Some modules like `SchemaGraphy` and `AsciiDoc` are never broken up into `schema_graphy` or `ascii_doc` namespaces.
   - Modules with multiple parallel sibling modules in a category like (`WriteOps`, `DraftOps`) belong in paths like `lib/ops/write.rb` instead of `lib/write_ops.rb` or `lib/write/ops.rb`.

### Syntax Conventions

- Use 2 spaces for indentation.
- Limit lines to 120 characters or so when possible.
- Use parentheses for method calls with arguments, but omit them for methods without arguments.
- Do not use parentheses in method definitions (`def method_name arg1, arg2`).
- Use single quotes for strings that do not require interpolation or special symbols.
- Use double quotes for strings that require interpolation or special symbols.

### Commenting Conventions

See [DocOps Lab Code Commenting Guidance](/docs/code-commenting/) for detailed commenting conventions.

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

