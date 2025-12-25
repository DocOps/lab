#!/usr/bin/env bash
# DocOps Lab Dev Container entrypoint script
# Handles command routing, bundle management, and rake aliasing

set -euo pipefail

# Fast path: no args -> interactive shell
if [ "$#" -eq 0 ]; then
  exec bash
fi

# If running inside a project with a Gemfile, ensure per-project bundler config
# Only configure bundler if we're about to use it
if [ -f "Gemfile" ] && { [ "$1" = "rake" ] || [[ "$1" == labdev:* ]] || [ "$1" = "bundle" ]; }; then
  # Force per-project install path to .bundle/
  bundle config set --local path '.bundle' >/dev/null

  # Only install if needed
  if ! bundle check >/dev/null 2>&1; then
    # Fallback to jobs/retry env if provided
    : "${BUNDLE_JOBS:=4}"
    : "${BUNDLE_RETRY:=3}"
    echo 'Installing project dependencies into .bundle/ ...'
    bundle install --jobs "${BUNDLE_JOBS}" --retry "${BUNDLE_RETRY}"
  fi
fi

# Rake routing with bundle exec when a project exists
if [ "$1" = "rake" ]; then
  shift
  if [ -f "Gemfile" ]; then
    exec bundle exec rake "$@"
  else
    exec rake "$@"
  fi
fi

# labdev:* tasks -> rake tasks
if [[ "$1" == labdev:* ]]; then
  # Special handling for init tasks - create minimal Rakefile if needed
  if [[ "$1" == labdev:init:all ]] && [ ! -f "Rakefile" ]; then
    echo "# frozen_string_literal: true\n\nrequire 'docopslab/dev'" > Rakefile
    exec rake "$@"
  fi
  
  # Other labdev tasks need a project context
  if [ -f "Gemfile" ]; then
    exec bundle exec rake "$@"
  else
    exec rake -r docopslab/dev "$@"
  fi
fi

# Otherwise execute directly
exec "$@"