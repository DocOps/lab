#!/usr/bin/env bash

# Script to copy slides and required assets from docs-as-code-school to slides/internal/
# This will overwrite any existing files

set -e  # Exit on any error

SOURCE_DIR="../docs-as-code-school/content/topics/internal"
DEST_DIR="./slides/internal"

echo "Copying slides and assets to ${DEST_DIR}..."

# Create destination directory structure
mkdir -p "${DEST_DIR}"
mkdir -p "${DEST_DIR}/revealjs/dist/theme"
mkdir -p "${DEST_DIR}/revealjs/plugin/zoom"
mkdir -p "${DEST_DIR}/revealjs/plugin/notes"
mkdir -p "${DEST_DIR}/revealjs/plugin/highlight"

# Copy slides.html
echo "Copying slides.html..."
cp "${SOURCE_DIR}/slides.html" "${DEST_DIR}/index.html"

# Copy images directory
echo "Copying images directory..."
cp -r "${SOURCE_DIR}/images" "${DEST_DIR}/"

# Copy required reveal.js CSS files
echo "Copying reveal.js CSS files..."
cp "${SOURCE_DIR}/revealjs/dist/reset.css" "${DEST_DIR}/revealjs/dist/"
cp "${SOURCE_DIR}/revealjs/dist/reveal.css" "${DEST_DIR}/revealjs/dist/"
cp "${SOURCE_DIR}/revealjs/dist/theme/black.css" "${DEST_DIR}/revealjs/dist/theme/"

# Copy reveal.js JavaScript
echo "Copying reveal.js JavaScript..."
cp "${SOURCE_DIR}/revealjs/dist/reveal.js" "${DEST_DIR}/revealjs/dist/"

# Copy required plugins
echo "Copying reveal.js plugins..."
cp "${SOURCE_DIR}/revealjs/plugin/zoom/zoom.js" "${DEST_DIR}/revealjs/plugin/zoom/"
cp "${SOURCE_DIR}/revealjs/plugin/notes/notes.js" "${DEST_DIR}/revealjs/plugin/notes/"
cp "${SOURCE_DIR}/revealjs/plugin/highlight/monokai.css" "${DEST_DIR}/revealjs/plugin/highlight/"

echo "✅ Copy completed successfully!"
echo "Files copied to: ${DEST_DIR}"
