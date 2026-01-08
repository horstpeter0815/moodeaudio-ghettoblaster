#!/bin/bash
# Monitor Build Output - Multiple ways to see what's happening
# Usage: ~/moodeaudio-cursor/MONITOR_BUILD_OUTPUT.sh [option]

PROJECT_DIR="$HOME/moodeaudio-cursor"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  📊 MONITOR BUILD OUTPUT                                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

case "$1" in
    live|l)
        echo "=== LIVE CONTAINER OUTPUT ==="
        echo ""
        if docker ps | grep -q moode-builder; then
            echo "Following container logs (real-time)..."
            echo "Press Ctrl+C to stop"
            echo ""
            docker-compose -f "$PROJECT_DIR/docker-compose.build.yml" logs -f moode-builder
        else
            echo "Container not running. Checking recent logs..."
            docker-compose -f "$PROJECT_DIR/docker-compose.build.yml" logs --tail=100 moode-builder
        fi
        ;;
    
    logs|log)
        echo "=== RECENT BUILD LOGS ==="
        echo ""
        docker-compose -f "$PROJECT_DIR/docker-compose.build.yml" logs --tail=200 moode-builder
        ;;
    
    exec|e)
        echo "=== EXEC INTO CONTAINER ==="
        echo ""
        if docker ps | grep -q moode-builder; then
            echo "Entering container..."
            echo "Type 'exit' to leave"
            echo ""
            docker exec -it moode-builder bash
        else
            echo "Container not running"
        fi
        ;;
    
    status|s)
        echo "=== BUILD STATUS ==="
        echo ""
        if docker ps | grep -q moode-builder; then
            echo "✅ Container is running"
            echo ""
            echo "Container info:"
            docker ps | grep moode-builder
            echo ""
            echo "Recent output (last 20 lines):"
            docker-compose -f "$PROJECT_DIR/docker-compose.build.yml" logs --tail=20 moode-builder
        else
            echo "⚠️  Container not running"
            echo ""
            echo "Check if build completed:"
            ls -lh "$PROJECT_DIR/imgbuild/deploy"/*.img 2>/dev/null | tail -1
        fi
        ;;
    
    *)
        echo "Usage: $0 [live|logs|exec|status]"
        echo ""
        echo "Options:"
        echo "  live, l    - Follow container logs in real-time"
        echo "  logs, log  - Show recent build logs (last 200 lines)"
        echo "  exec, e    - Enter container interactively"
        echo "  status, s  - Show build status and recent output"
        echo ""
        echo "Examples:"
        echo "  ~/moodeaudio-cursor/MONITOR_BUILD_OUTPUT.sh live"
        echo "  ~/moodeaudio-cursor/MONITOR_BUILD_OUTPUT.sh logs"
        echo "  ~/moodeaudio-cursor/MONITOR_BUILD_OUTPUT.sh exec"
        echo "  ~/moodeaudio-cursor/MONITOR_BUILD_OUTPUT.sh status"
        ;;
esac

