#!/usr/bin/env bash
# Generic release build script for DocOps Lab projects
# Usage: Set PROJECT_NAME and DOCKER_ORG, then run this script

set -e

# Load common build functions from centrally managed location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Try to find build-common.sh in various locations
if [ -f "$SCRIPT_DIR/build-common.sh" ]; then
    # shellcheck source=build-common.sh
    source "$SCRIPT_DIR/build-common.sh"
elif [ -f "$SCRIPT_DIR/lib/build-common.sh" ]; then
    # shellcheck source=build-common.sh
    source "$SCRIPT_DIR/lib/build-common.sh"
elif [ -f "scripts/.vendor/docopslab/build-common.sh" ]; then
    # shellcheck source=build-common.sh
    source "scripts/.vendor/docopslab/build-common.sh"
else
    echo "❌ Error: build-common.sh not found. Run 'rake labdev:config:sync' to get centrally managed scripts."
    exit 1
fi

# Project configuration - override these in your calling script or environment  
PROJECT_NAME="${PROJECT_NAME:-$(basename "$(pwd)")}"
DOCKER_ORG="${DOCKER_ORG:-docopslab}"

echo -e "${GREEN}🚀 ${PROJECT_NAME} Release Build Script${NC}"
echo "=================================="

# Validation
check_project_root
check_git_clean  
check_main_branch
check_bundle_installed
check_docker_available

# Run tests
run_rspec_tests
test_cli_functionality

# Get current version
current_version=$(get_current_version)
echo -e "${GREEN}📋 Current version: $current_version${NC}"

# Build and test gem
build_gem
gem_file=$(test_built_gem)

# Build Docker image using the docker-specific script
echo -e "${YELLOW}🐳 Building Docker image...${NC}"
"$SCRIPT_DIR/build-docker.sh" 2>&1 | grep -E "(Building|Testing|successfully|Docker image:)" || true

# Show final success message
show_build_success "$current_version" "$gem_file"