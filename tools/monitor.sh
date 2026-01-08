#!/bin/bash
################################################################################
#
# UNIFIED MONITOR TOOL
# 
# Consolidates all monitoring scripts into one unified tool
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WISSENSBASIS_HELPER="$SCRIPT_DIR/utils/wissensbasis.sh"
WISSENSBASIS_HARDWARE="$PROJECT_ROOT/WISSENSBASIS/02_HARDWARE.md"
cd "$PROJECT_ROOT"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[MONITOR]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

################################################################################
# MONITOR FUNCTIONS
################################################################################

monitor_build() {
    log "Monitoring build progress..."
    
    if [ -f "$PROJECT_ROOT/BUILD_MONITOR_REAL.sh" ]; then
        bash "$PROJECT_ROOT/BUILD_MONITOR_REAL.sh"
    elif [ -f "$PROJECT_ROOT/MONITOR_BUILD_30.sh" ]; then
        bash "$PROJECT_ROOT/MONITOR_BUILD_30.sh"
    else
        # Fallback: tail build log
        LATEST_LOG=$(ls -t "$PROJECT_ROOT/imgbuild/deploy"/build-*.log 2>/dev/null | head -1)
        if [ -n "$LATEST_LOG" ]; then
            tail -f "$LATEST_LOG"
        else
            error "No build log found"
            exit 1
        fi
    fi
}

monitor_pi() {
    log "Monitoring Pi systems..."
    
    if [ -f "$PROJECT_ROOT/CHECK_PI_STATUS.sh" ]; then
        bash "$PROJECT_ROOT/CHECK_PI_STATUS.sh"
    elif [ -f "$PROJECT_ROOT/MONITOR_PI_BOOT.sh" ]; then
        bash "$PROJECT_ROOT/MONITOR_PI_BOOT.sh"
    else
        error "Pi monitoring scripts not found"
        exit 1
    fi
}

monitor_serial() {
    log "Monitoring serial console..."
    
    if [ -f "$PROJECT_ROOT/MONITOR_SERIAL_BOOT.sh" ]; then
        bash "$PROJECT_ROOT/MONITOR_SERIAL_BOOT.sh"
    elif [ -f "$PROJECT_ROOT/AUTO_MONITOR_SERIAL.sh" ]; then
        bash "$PROJECT_ROOT/AUTO_MONITOR_SERIAL.sh"
    else
        error "Serial monitoring scripts not found"
        exit 1
    fi
}

monitor_all() {
    log "Monitoring all systems..."
    
    if [ -f "$PROJECT_ROOT/monitor-all-systems.sh" ]; then
        bash "$PROJECT_ROOT/monitor-all-systems.sh"
    elif [ -f "$PROJECT_ROOT/SYSTEM_MONITOR.sh" ]; then
        bash "$PROJECT_ROOT/SYSTEM_MONITOR.sh"
    else
        warn "Comprehensive monitor not found, checking individual systems..."
        monitor_pi
    fi
}

check_status() {
    log "Checking system status..."
    
    # Show hardware info from WISSENSBASIS
    if [ -f "$WISSENSBASIS_HARDWARE" ]; then
        info "Hardware Configuration (from WISSENSBASIS):"
        grep -A 5 "Raspberry Pi\|IP-Adresse\|Display\|Touchscreen\|Audio" "$WISSENSBASIS_HARDWARE" 2>/dev/null | head -20 || true
        echo ""
    fi
    
    echo ""
    echo "=== Build Status ==="
    if [ -f "$PROJECT_ROOT/BUILD_COUNTER.txt" ]; then
        BUILD_NUM=$(cat "$PROJECT_ROOT/BUILD_COUNTER.txt")
        echo "Build Number: $BUILD_NUM"
    fi
    
    LATEST_IMAGE=$(ls -t "$PROJECT_ROOT/imgbuild/deploy"/*.img 2>/dev/null | head -1)
    if [ -n "$LATEST_IMAGE" ]; then
        SIZE=$(du -h "$LATEST_IMAGE" | cut -f1)
        echo "Latest Image: $(basename "$LATEST_IMAGE") ($SIZE)"
    fi
    
    echo ""
    echo "=== Docker Status ==="
    if docker info >/dev/null 2>&1; then
        echo "Docker: ✅ Running"
    else
        echo "Docker: ❌ Not running"
    fi
    
    echo ""
    echo "=== Pi Status ==="
    if [ -f "$PROJECT_ROOT/CHECK_PI_STATUS.sh" ]; then
        bash "$PROJECT_ROOT/CHECK_PI_STATUS.sh"
    else
        echo "Pi status check script not found"
    fi
}

################################################################################
# MAIN MENU
################################################################################

show_menu() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  📡 MONITOR TOOL - Unified Monitoring                        ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "1) Monitor build progress"
    echo "2) Monitor Pi systems"
    echo "3) Monitor serial console"
    echo "4) Monitor all systems"
    echo "5) Check system status"
    echo "0) Exit"
    echo ""
    read -p "Select option: " choice
}

main() {
    if [ "$1" = "--build" ] || [ "$1" = "-b" ]; then
        monitor_build
    elif [ "$1" = "--pi" ] || [ "$1" = "-p" ]; then
        monitor_pi
    elif [ "$1" = "--serial" ] || [ "$1" = "-s" ]; then
        monitor_serial
    elif [ "$1" = "--all" ] || [ "$1" = "-a" ]; then
        monitor_all
    elif [ "$1" = "--status" ] || [ "$1" = "-S" ]; then
        check_status
    elif [ -z "$1" ]; then
        # Interactive mode
        while true; do
            show_menu
            case $choice in
                1) monitor_build ;;
                2) monitor_pi ;;
                3) monitor_serial ;;
                4) monitor_all ;;
                5) check_status ;;
                0) exit 0 ;;
                *) error "Invalid option" ;;
            esac
            echo ""
            read -p "Press Enter to continue..."
        done
    else
        error "Unknown option: $1"
        echo "Usage: $0 [--build|--pi|--serial|--all|--status]"
        exit 1
    fi
}

main "$@"

