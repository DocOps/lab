#!/usr/bin/env bash
# Build script for DocOps Lab Dev Docker image

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

IMAGE_NAME="docopslab/dev"

echo "🐳 Building DocOps Lab Dev Docker image..."
echo "   Image: $IMAGE_NAME:$VERSION"
echo "   Latest: $IMAGE_NAME:latest"

# Build the image
docker build -t "$IMAGE_NAME:$VERSION" -t "$IMAGE_NAME:latest" .

echo ""
echo "✅ Build complete!"
echo ""
echo "Setup alias (add to your shell profile):"
echo "  alias lab-dev='docker run -it --rm -v \"\$(pwd):/workspace\" $IMAGE_NAME'"
echo ""
echo "Usage workflow:"
echo "  # First time in a DocOps Lab project:"
echo "  lab-dev rake labdev:sync:all"
echo ""
echo "  # Then regular development:"
echo "  lab-dev rake labdev:lint:all"
echo "  lab-dev rake labdev:heal"
echo "  lab-dev bundle exec htmlproofer --check-external-hash"
echo "  lab-dev ripgrep TODO"
echo ""
echo "  # Interactive shell:"
echo "  lab-dev"