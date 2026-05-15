# Running Tests in DocOps Lab Projects

This document is intended for AI agents operating within a DocOps Lab environment.

As an AI agent, you can help DocOps Lab developers run tests effectively using standard Rake tasks.

All Ruby gem projects with tests should implement these standard Rake tasks in their `Rakefile`:

<dl>
<dt class="hdlist1">`bundle exec rake rspec`</dt>
<dd>
Run RSpec test suite using the standard pattern matcher.
</dd>
<dt class="hdlist1">`bundle exec rake cli_test`</dt>
<dd>
Validate command-line interface functionality. May test basic CLI loading, help output, version information.
</dd>
<dt class="hdlist1">`bundle exec rake yaml_test`</dt>
<dd>
Validate YAML configuration files and data structures. Should test all project YAML files for syntax correctness.
</dd>
<dt class="hdlist1">`bundle exec rake pr_test`</dt>
<dd>
Comprehensive test suite for pre-commit and pull request validation. Typically includes: RSpec tests, CLI tests, YAML validation.
</dd>
<dt class="hdlist1">`bundle exec rake install_local`</dt>
<dd>
Build and install the project locally for testing.
</dd>
</dl>

Note that non-gem projects may have some or all of these tasks, as applicable.

