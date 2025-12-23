#!/usr/bin/env bash

# Local build.sh - overrides DocOps Lab managed script
# This is a project-specific build script that takes precedence over scripts/.vendor/docopslab/build.sh

echo "ℹ️  Using local build.sh (overrides managed script)"
echo "📁 Project: DocOps Lab main repository" 
echo "� Build type: Custom Jekyll site with gem management"
echo ""
echo "Available managed build script: scripts/.vendor/docopslab/build.sh"
echo "To use managed script: bundle exec rake labdev:run build"

echo "Argument 1 is: $1"
echo "Argument 2 is: $2" 