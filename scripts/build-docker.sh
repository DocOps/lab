#!/usr/bin/env bash
# build-docker.sh; generic Docker build script for DocOps Lab projects.
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

printf '\n%s\n' "$(_bold "${PROJECT_NAME} Docker Build")"
_sep

_check_project_root
_check_docker_available

current_version=$(_get_current_version)
_info "Current version: $current_version"

gem_file="pkg/${PROJECT_NAME}-$current_version.gem"
if [[ ! -f "$gem_file" ]]; then
  _info "Gem not found in pkg/; building gem first..."
  _check_bundle_installed
  build_gem
  _tick "Gem built: $gem_file"
else
  _info "Using existing gem: $gem_file"
fi

build_docker_image "$current_version"
test_docker_image "$current_version"

show_docker_success "$current_version"

printf '\nTest the image with:\n'
_info "docker run --rm -v \$(pwd):/workdir ${DOCKER_ORG}/${PROJECT_NAME}:$current_version --version"
if [[ -f "$EXAMPLE_FILE" ]]; then
  _info "docker run --rm -v \$(pwd):/workdir ${DOCKER_ORG}/${PROJECT_NAME}:$current_version $EXAMPLE_FILE --dry"
fi