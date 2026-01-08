#!/bin/bash
# Quick Start - Works from anywhere
# Usage: ~/moodeaudio-cursor/QUICK_START.sh [command]

PROJECT_DIR="$HOME/moodeaudio-cursor"
cd "$PROJECT_DIR"

case "$1" in
    build|b)
        echo "Starting Build 36..."
        echo "Note: Build requires sudo privileges"
        if [ "$EUID" -ne 0 ]; then
            echo "Please run with sudo:"
            echo "  sudo $0 build"
            exit 1
        fi
        ./START_BUILD_36.sh
        ;;
    monitor|m)
        echo "Monitoring build..."
        ./tools/build.sh --monitor
        ;;
    validate|v)
        echo "Validating build..."
        ./tools/build.sh --validate
        ;;
    deploy|d)
        echo "Deploying to SD card..."
        ./tools/build.sh --deploy
        ;;
    test|t)
        echo "Running tests..."
        ./tools/test.sh --docker
        ;;
    toolbox|tb)
        echo "Opening toolbox..."
        ./tools/toolbox.sh
        ;;
    *)
        echo "Usage: $0 [build|monitor|validate|deploy|test|toolbox]"
        echo ""
        echo "Commands:"
        echo "  build, b     - Start Build 36"
        echo "  monitor, m   - Monitor build progress"
        echo "  validate, v  - Validate build image"
        echo "  deploy, d    - Deploy to SD card"
        echo "  test, t      - Run Docker tests"
        echo "  toolbox, tb  - Open toolbox menu"
        ;;
esac
