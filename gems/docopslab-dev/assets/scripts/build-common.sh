#!/usr/bin/env bash
# Common build functions for DocOps Lab Ruby gem projects
# This library provides reusable functions for building gems and Docker images

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Project configuration - these should be set by the calling script
PROJECT_NAME="${PROJECT_NAME:-$(basename "$(pwd)")}"
DOCKER_ORG="${DOCKER_ORG:-docopslab}"
GEMSPEC_FILE="${GEMSPEC_FILE:-${PROJECT_NAME}.gemspec}"
CLI_EXECUTABLE="${CLI_EXECUTABLE:-exe/${PROJECT_NAME}}"
EXAMPLE_FILE="${EXAMPLE_FILE:-examples/minimal-example.yml}"
TEST_SPEC_PATH="${TEST_SPEC_PATH:-specs/tests/rspec/}"

# Common validation functions
check_project_root() {
    if [ ! -f "$GEMSPEC_FILE" ]; then
        echo -e "${RED}❌ Error: $GEMSPEC_FILE not found. Run this script from the project root.${NC}"
        exit 1
    fi
}

check_docker_available() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Error: Docker is not installed or not in PATH${NC}"
        exit 1
    fi
}

check_git_clean() {
    if [ -n "$(git status --porcelain)" ]; then
        echo -e "${RED}❌ Error: Working directory is not clean. Commit or stash changes first.${NC}"
        git status --short
        exit 1
    fi
}

check_main_branch() {
    current_branch=$(git branch --show-current)
    if [ "$current_branch" != "main" ]; then
        echo -e "${YELLOW}⚠️  Warning: Not on main branch (currently on: $current_branch)${NC}"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Aborted."
            exit 1
        fi
    fi
}

check_bundle_installed() {
    if [ ! -f "Gemfile" ]; then
        echo -e "${YELLOW}⚠️  Warning: No Gemfile found. Some operations may require dependencies.${NC}"
        return
    fi
    
    if ! bundle check > /dev/null 2>&1; then
        echo -e "${YELLOW}📦 Installing gem dependencies...${NC}"
        bundle install
    fi
}

# Get current version from README.adoc by parsing directly
get_current_version() {
    grep '^:this_prod_vrsn:' README.adoc | sed 's/^:this_prod_vrsn:[[:space:]]*//' | tr -d '\r'
}

# Get next version from README.adoc by parsing directly
get_next_version() {
    grep '^:next_prod_vrsn:' README.adoc | sed 's/^:next_prod_vrsn:[[:space:]]*//' | tr -d '\r'
}

# Docker build and test functions
build_docker_image() {
    local version=$1
    local docker_args="${2:-}"
    
    echo -e "${YELLOW}🐳 Building Docker image...${NC}"
    # shellcheck disable=SC2086
    docker build ${docker_args} -t "${DOCKER_ORG}/${PROJECT_NAME}:${version}" .
    docker tag "${DOCKER_ORG}/${PROJECT_NAME}:${version}" "${DOCKER_ORG}/${PROJECT_NAME}:latest"
}

test_docker_image() {
    local version=$1
    local image_name="${DOCKER_ORG}/${PROJECT_NAME}:${version}"
    
    echo -e "${YELLOW}🧪 Testing Docker image...${NC}"
    docker run --rm -v "$(pwd):/workdir" "${image_name}" --version
    
    if [ -f "$EXAMPLE_FILE" ]; then
        docker run --rm -v "$(pwd):/workdir" "${image_name}" "${EXAMPLE_FILE}" --dry
    fi
}

# Test functions
run_rspec_tests() {
    if [ -d "$TEST_SPEC_PATH" ]; then
        echo -e "${YELLOW}🧪 Running RSpec tests...${NC}"
        bundle exec rspec "$TEST_SPEC_PATH" --format documentation
    else
        echo -e "${YELLOW}⚠️  No RSpec tests found at $TEST_SPEC_PATH${NC}"
    fi
}

test_cli_functionality() {
    if [ -x "$CLI_EXECUTABLE" ]; then
        echo -e "${YELLOW}🧪 Testing CLI functionality...${NC}"
        $CLI_EXECUTABLE --version
        
        if [ -f "$EXAMPLE_FILE" ]; then
            $CLI_EXECUTABLE "$EXAMPLE_FILE" --dry
        fi
    else
        echo -e "${YELLOW}⚠️  CLI executable not found at $CLI_EXECUTABLE${NC}"
    fi
}

# Gem build functions
build_gem() {
    echo -e "${YELLOW}💎 Building gem...${NC}"
    bundle exec rake build
}

test_built_gem() {
    local current_version
    current_version=$(get_current_version)
    local gem_file="pkg/${PROJECT_NAME}-${current_version}.gem"
    
    if [ ! -f "$gem_file" ]; then
        echo -e "${RED}❌ Error: Expected gem file not found: $gem_file${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Built gem: $gem_file${NC}"
    echo "$gem_file"
}

# Success message functions
show_build_success() {
    local version=$1
    local gem_file=$2
    
    echo
    echo -e "${GREEN}🎉 Build completed successfully!${NC}"
    echo "=================================="
    echo -e "${GREEN}📋 Version: $version${NC}"
    echo -e "${GREEN}💎 Gem: $gem_file${NC}"
    echo -e "${GREEN}🐳 Docker: ${DOCKER_ORG}/${PROJECT_NAME}:$version${NC}"
    echo
}

show_docker_success() {
    local version=$1
    
    echo
    echo -e "${GREEN}🎉 Docker build completed successfully!${NC}"
    echo "=================================="
    echo -e "${GREEN}📋 Version: $version${NC}"
    echo -e "${GREEN}🐳 Images built:${NC}"
    echo "   ${DOCKER_ORG}/${PROJECT_NAME}:$version"
    echo "   ${DOCKER_ORG}/${PROJECT_NAME}:latest"
}

# Version bump functions
bump_version() {
    local current_version
    local next_version
    current_version=$(get_current_version)
    next_version=$(get_next_version)
    
    if [ "$current_version" = "$next_version" ]; then
        echo -e "${RED}❌ Error: Current and next versions are the same: $current_version${NC}"
        echo "Update :next_prod_vrsn: in README.adoc first"
        exit 1
    fi
    
    echo -e "${YELLOW}📝 Bumping version from $current_version to $next_version...${NC}"
    
    # Update the current version to match next version
    sed -i "s/^:this_prod_vrsn: $current_version/:this_prod_vrsn: $next_version/" README.adoc
    
    # Commit the version bump
    git add README.adoc
    git commit -m "Release v$next_version"
    git tag "v$next_version"
    
    echo -e "${GREEN}✅ Version bumped and tagged: v$next_version${NC}"
}