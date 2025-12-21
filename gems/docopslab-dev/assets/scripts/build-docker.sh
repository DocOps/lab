#!/usr/bin/env bash
# Generic Docker build script for DocOps Lab projects
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

echo -e "${GREEN}🐳 ${PROJECT_NAME} Docker Build Script${NC}"
echo "=================================="

# Validation
check_project_root
check_docker_available

# Get current version
current_version=$(get_current_version)
echo -e "${GREEN}📋 Current version: $current_version${NC}"

# Check if gem exists in pkg/, if not build it
gem_file="pkg/${PROJECT_NAME}-$current_version.gem"
if [ ! -f "$gem_file" ]; then
    echo -e "${YELLOW}🔨 Gem not found in pkg/. Building gem first...${NC}"
    check_bundle_installed
    build_gem
    echo -e "${GREEN}✅ Gem built: $gem_file${NC}"
else
    echo -e "${GREEN}📋 Using existing gem: $gem_file${NC}"
fi

# Build and test Docker image
build_docker_image "$current_version"
test_docker_image "$current_version"

# Show success message
show_docker_success "$current_version"

echo
echo "Test the image with:"
echo "  docker run --rm -v \$(pwd):/workdir ${DOCKER_ORG}/${PROJECT_NAME}:$current_version --version"

if [ -f "$EXAMPLE_FILE" ]; then
    echo "  docker run --rm -v \$(pwd):/workdir ${DOCKER_ORG}/${PROJECT_NAME}:$current_version $EXAMPLE_FILE --dry"
fi