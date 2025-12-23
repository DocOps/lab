# Writing Tests for DocOps Lab Projects

This document is intended for AI agents operating within a DocOps Lab environment.

As an AI agent, you can help DocOps Lab developers write comprehensive tests following established patterns and categories.

Tests should be organized into these categories:

**Unit Tests** :
   - Module loading and initialization
   - Class structure validation
   - Basic functionality verification
   - Individual method testing

**Integration Tests** :
   - Data processing workflows
   - Template rendering operations
   - Configuration loading scenarios
   - API client functionality (where applicable)

**Validation Tests** :
   - File format compliance (YAML, JSON)
   - Configuration schema validation
   - Template syntax verification
   - Command-line option parsing

All Ruby gem projects with tests should implement these standard Rake tasks in their `Rakefile`:

**`bundle exec rake rspec`** :
   Run RSpec test suite using the standard pattern matcher.

**`bundle exec rake cli_test`** :
   Validate command-line interface functionality. May test basic CLI loading, help output, version information.

**`bundle exec rake yaml_test`** :
   Validate YAML configuration files and data structures. Should test all project YAML files for syntax correctness.

**`bundle exec rake pr_test`** :
   Comprehensive test suite for pre-commit and pull request validation. Typically includes: RSpec tests, CLI tests, YAML validation.

**`bundle exec rake install_local`** :
   Build and install the project locally for testing.

Note that non-gem projects may have some or all of these tasks, as applicable.

