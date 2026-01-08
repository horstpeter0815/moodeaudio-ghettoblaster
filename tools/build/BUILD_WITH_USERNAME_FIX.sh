#!/bin/bash
# Build image with comprehensive username persistence fixes
# Uses password from test-password.txt

set -e

PROJECT_DIR="$HOME/moodeaudio-cursor"
cd "$PROJECT_DIR"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔨 BUILD IMAGE - USERNAME PERSISTENCE FIXES                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check password file
if [ ! -f "test-password.txt" ]; then
    echo "❌ test-password.txt not found"
    exit 1
fi

PASSWORD=$(cat test-password.txt | tr -d '\n\r')
echo "✅ Using password from test-password.txt"
echo ""

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "Starting Docker..."
    open -a Docker
    echo "Waiting for Docker to start..."
    sleep 10
    while ! docker info >/dev/null 2>&1; do
        sleep 2
    done
    echo "✅ Docker is running"
fi

echo "Starting build with all username persistence fixes..."
echo "This will take 30-60 minutes..."
echo ""

# Run build with password
echo "$PASSWORD" | sudo -S "$PROJECT_DIR/START_BUILD_36.sh" 2>&1 | tee "build-username-fix-$(date +%Y%m%d_%H%M%S).log"

echo ""
echo "✅ Build complete!"
