#!/bin/bash
# Read Build Log - Direct access to build output
# Usage: ~/moodeaudio-cursor/READ_BUILD_LOG.sh

PROJECT_DIR="$HOME/moodeaudio-cursor"
BUILD_DIR="$PROJECT_DIR/imgbuild/deploy"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  📖 READ BUILD LOG - DIRECT CONSOLE ACCESS                  ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Find latest build log
LATEST_LOG=$(ls -t "$BUILD_DIR"/build-*.log 2>/dev/null | head -1)

if [ -z "$LATEST_LOG" ]; then
    echo "⚠️  No build log found"
    echo ""
    echo "Build logs location: $BUILD_DIR"
    echo ""
    echo "If build is running, check:"
    echo "  docker-compose -f $PROJECT_DIR/docker-compose.build.yml logs -f moode-builder"
    exit 1
fi

echo "✅ Found build log:"
echo "   $(basename "$LATEST_LOG")"
echo "   Size: $(du -h "$LATEST_LOG" | cut -f1)"
echo ""

# Show options
echo "What do you want to do?"
echo ""
echo "  1) Show last 50 lines"
echo "  2) Show last 100 lines"
echo "  3) Show last 200 lines"
echo "  4) Follow log (real-time, like tail -f)"
echo "  5) Show entire log"
echo "  6) Search log for errors"
echo ""
read -p "Select option (1-6): " OPTION

case "$OPTION" in
    1)
        echo ""
        echo "=== LAST 50 LINES ==="
        tail -50 "$LATEST_LOG"
        ;;
    2)
        echo ""
        echo "=== LAST 100 LINES ==="
        tail -100 "$LATEST_LOG"
        ;;
    3)
        echo ""
        echo "=== LAST 200 LINES ==="
        tail -200 "$LATEST_LOG"
        ;;
    4)
        echo ""
        echo "=== FOLLOWING LOG (REAL-TIME) ==="
        echo "Press Ctrl+C to stop"
        echo ""
        tail -f "$LATEST_LOG"
        ;;
    5)
        echo ""
        echo "=== ENTIRE LOG ==="
        cat "$LATEST_LOG"
        ;;
    6)
        echo ""
        echo "=== SEARCHING FOR ERRORS ==="
        echo ""
        grep -i "error\|fail\|warning" "$LATEST_LOG" | tail -50
        ;;
    *)
        echo "Invalid option"
        exit 1
        ;;
esac

