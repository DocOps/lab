#!/usr/bin/env bash
# build.sh; generic release build script for DocOps Lab projects.
# Usage: Set PROJECT_NAME and DOCKER_ORG, then run this script.

set -euo pipefail

# tag::universal-resolve-script-dir[]
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# end::universal-resolve-script-dir[]

# Source the shared build library.
if [[ -f "$SCRIPT_DIR/build-common.sh" ]]; then
  # shellcheck source=build-common.sh
  source "$SCRIPT_DIR/build-common.sh"
elif [[ -f "$SCRIPT_DIR/lib/build-common.sh" ]]; then
  # shellcheck source=build-common.sh
  source "$SCRIPT_DIR/lib/build-common.sh"
elif [[ -f "scripts/.vendor/docopslab/build-common.sh" ]]; then
  # shellcheck source=build-common.sh
  source "scripts/.vendor/docopslab/build-common.sh"
else
  printf 'Error: build-common.sh not found. Run rake labdev:config:sync to get centrally managed scripts.\n' >&2
  exit 1
fi

PROJECT_NAME="${PROJECT_NAME:-$(basename "$(pwd)")}"
DOCKER_ORG="${DOCKER_ORG:-docopslab}"

printf '\n%s\n' "$(_bold "${PROJECT_NAME} Release Build")"
_sep

_check_project_root
_check_git_clean
_check_main_branch
_check_bundle_installed
_check_docker_available

run_rspec_tests
test_cli_functionality

current_version=$(_get_current_version)
_info "Current version: $current_version"

build_gem
gem_file=$(_test_built_gem)

_info "Building Docker image..."
"$SCRIPT_DIR/build-docker.sh"

show_build_success "$current_version" "$gem_file"