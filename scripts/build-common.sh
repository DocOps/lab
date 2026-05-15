#!/usr/bin/env bash
# build-common.sh; shared build helpers for DocOps Lab Ruby gem projects.
# Sourced by build.sh and build-docker.sh; do not execute directly.
# Requires: git, docker, bundle

# tag::universal-style-helpers[]
_bold()     { printf '\033[1m%s\033[0m' "$*"; }
_green()    { printf '\033[32m%s\033[0m' "$*"; }
_yellow()   { printf '\033[33m%s\033[0m' "$*"; }
_red()      { printf '\033[31m%s\033[0m' "$*"; }
_tick()     { printf '%s %s\n' "$(_green '✓')" "$*"; }
_warn()     { printf '%s %s\n' "$(_yellow '⚠')" "$*"; }
_fail()     { printf '%s %s\n' "$(_red '✗')" "$*"; }
_info()     { printf '  %s\n' "$*"; }
_sep()      { printf '%s\n' "────────────────────────────────────────────────"; }
_run_echo() { printf '\n%s %s\n\n' "$(_bold '▶')" "$(_bold "$*")"; }
# end::universal-style-helpers[]

# CONFIGURATION
# Set by the calling script; defaults fall back to conventions.
PROJECT_NAME="${PROJECT_NAME:-$(basename "$(pwd)")}"
DOCKER_ORG="${DOCKER_ORG:-docopslab}"
GEMSPEC_FILE="${GEMSPEC_FILE:-${PROJECT_NAME}.gemspec}"
CLI_EXECUTABLE="${CLI_EXECUTABLE:-exe/${PROJECT_NAME}}"
EXAMPLE_FILE="${EXAMPLE_FILE:-examples/minimal-example.yml}"
TEST_SPEC_PATH="${TEST_SPEC_PATH:-specs/tests/rspec/}"

# VALIDATION HELPERS

_check_project_root() {
  if [[ ! -f "$GEMSPEC_FILE" ]]; then
    _fail "$GEMSPEC_FILE not found. Run this script from the project root."
    exit 1
  fi
}

_check_docker_available() {
  if ! command -v docker &>/dev/null; then
    _fail "Docker is not installed or not in PATH."
    exit 1
  fi
}

_check_git_clean() {
  if [[ -n "$(git status --porcelain)" ]]; then
    _fail "Working directory is not clean. Commit or stash changes first."
    git status --short
    exit 1
  fi
}

_check_main_branch() {
  local current_branch
  current_branch=$(git branch --show-current)
  if [[ "$current_branch" != "main" ]]; then
    _warn "Not on main branch (currently on: $current_branch)"
    printf '%s [y/N] ' "$(_yellow 'Continue anyway?')"
    read -r reply
    if [[ ! "$reply" =~ ^[Yy]$ ]]; then
      printf 'Aborted.\n'
      exit 1
    fi
  fi
}

_check_bundle_installed() {
  if [[ ! -f "Gemfile" ]]; then
    _warn "No Gemfile found. Some operations may require dependencies."
    return
  fi
  if ! bundle check >/dev/null 2>&1; then
    _info "Installing gem dependencies..."
    bundle install
  fi
}

# VERSION HELPERS

_get_current_version() {
  grep '^:this_prod_vrsn:' README.adoc | sed 's/^:this_prod_vrsn:[[:space:]]*//' | tr -d '\r'
}

_get_next_version() {
  grep '^:next_prod_vrsn:' README.adoc | sed 's/^:next_prod_vrsn:[[:space:]]*//' | tr -d '\r'
}

# OPERATIONS

build_docker_image() {
  local version="$1"
  local docker_args="${2:-}"
  _info "Building Docker image..."
  # shellcheck disable=SC2086 # intentional: $docker_args may contain multiple flags
  docker build ${docker_args} -t "${DOCKER_ORG}/${PROJECT_NAME}:${version}" .
  docker tag "${DOCKER_ORG}/${PROJECT_NAME}:${version}" "${DOCKER_ORG}/${PROJECT_NAME}:latest"
}

test_docker_image() {
  local version="$1"
  local image_name="${DOCKER_ORG}/${PROJECT_NAME}:${version}"
  _info "Testing Docker image..."
  docker run --rm -v "$(pwd):/workdir" "${image_name}" --version
  if [[ -f "$EXAMPLE_FILE" ]]; then
    docker run --rm -v "$(pwd):/workdir" "${image_name}" "${EXAMPLE_FILE}" --dry
  fi
}

run_rspec_tests() {
  if [[ -d "$TEST_SPEC_PATH" ]]; then
    _info "Running RSpec tests..."
    bundle exec rspec "$TEST_SPEC_PATH" --format documentation
  else
    _warn "No RSpec tests found at $TEST_SPEC_PATH"
  fi
}

test_cli_functionality() {
  if [[ -x "$CLI_EXECUTABLE" ]]; then
    _info "Testing CLI functionality..."
    "$CLI_EXECUTABLE" --version
    if [[ -f "$EXAMPLE_FILE" ]]; then
      "$CLI_EXECUTABLE" "$EXAMPLE_FILE" --dry
    fi
  else
    _warn "CLI executable not found at $CLI_EXECUTABLE"
  fi
}

build_gem() {
  _info "Building gem..."
  bundle exec rake build
}

_test_built_gem() {
  local current_version
  current_version=$(_get_current_version)
  local gem_file="pkg/${PROJECT_NAME}-${current_version}.gem"
  if [[ ! -f "$gem_file" ]]; then
    _fail "Expected gem file not found: $gem_file"
    exit 1
  fi
  _tick "Built gem: $gem_file"
  printf '%s\n' "$gem_file"
}

# OUTPUT

show_build_success() {
  local version="$1"
  local gem_file="$2"
  printf '\n'
  _tick "Build completed successfully!"
  _sep
  _info "Version: $version"
  _info "Gem:     $gem_file"
  _info "Docker:  ${DOCKER_ORG}/${PROJECT_NAME}:$version"
  printf '\n'
}

show_docker_success() {
  local version="$1"
  printf '\n'
  _tick "Docker build completed successfully!"
  _sep
  _info "Version: $version"
  _info "Images:"
  _info "  ${DOCKER_ORG}/${PROJECT_NAME}:$version"
  _info "  ${DOCKER_ORG}/${PROJECT_NAME}:latest"
}

# RELEASE

bump_version() {
  local current_version next_version
  current_version=$(_get_current_version)
  next_version=$(_get_next_version)
  if [[ "$current_version" == "$next_version" ]]; then
    _fail "Current and next versions are the same: $current_version"
    _info "Update :next_prod_vrsn: in README.adoc first."
    exit 1
  fi
  _info "Bumping version from $current_version to $next_version..."
  sed -i "s/^:this_prod_vrsn: $current_version/:this_prod_vrsn: $next_version/" README.adoc
  git add README.adoc
  git commit -m "Release v$next_version"
  git tag "v$next_version"
  _tick "Version bumped and tagged: v$next_version"
}
