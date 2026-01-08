#!/bin/bash
################################################################################
#
# UNIFIED TEST TOOL
# 
# Consolidates all test-related scripts into one unified tool
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WISSENSBASIS_HELPER="$SCRIPT_DIR/utils/wissensbasis.sh"
cd "$PROJECT_ROOT"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[TEST]${NC} $1"
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
# TEST FUNCTIONS
################################################################################

test_display() {
    log "Testing display..."
    
    local test_output=$(mktemp)
    local test_result="FAILED"
    
    if [ -f "$PROJECT_ROOT/test_display_resolution.sh" ]; then
        if bash "$PROJECT_ROOT/test_display_resolution.sh" > "$test_output" 2>&1; then
            test_result="SUCCESS"
        fi
    elif [ -f "$PROJECT_ROOT/TEST_DISPLAY_TIMINGS.sh" ]; then
        if bash "$PROJECT_ROOT/TEST_DISPLAY_TIMINGS.sh" > "$test_output" 2>&1; then
            test_result="SUCCESS"
        fi
    else
        error "Display test scripts not found"
        rm -f "$test_output"
        exit 1
    fi
    
    # Document in WISSENSBASIS
    if [ -f "$WISSENSBASIS_HELPER" ]; then
        local details=$(cat "$test_output" 2>/dev/null | head -20)
        "$WISSENSBASIS_HELPER" add-test "Display Test" "$test_result" "$details" 2>/dev/null || true
    fi
    
    cat "$test_output"
    rm -f "$test_output"
    
    if [ "$test_result" = "FAILED" ]; then
        exit 1
    fi
}

test_touchscreen() {
    log "Testing touchscreen..."
    
    local test_output=$(mktemp)
    local test_result="FAILED"
    
    if [ -f "$PROJECT_ROOT/test_touchscreen.sh" ]; then
        if bash "$PROJECT_ROOT/test_touchscreen.sh" > "$test_output" 2>&1; then
            test_result="SUCCESS"
        fi
    elif [ -f "$PROJECT_ROOT/verify_touchscreen.sh" ]; then
        if bash "$PROJECT_ROOT/verify_touchscreen.sh" > "$test_output" 2>&1; then
            test_result="SUCCESS"
        fi
    else
        error "Touchscreen test scripts not found"
        rm -f "$test_output"
        exit 1
    fi
    
    # Document in WISSENSBASIS
    if [ -f "$WISSENSBASIS_HELPER" ]; then
        local details=$(cat "$test_output" 2>/dev/null | head -20)
        "$WISSENSBASIS_HELPER" add-test "Touchscreen Test" "$test_result" "$details" 2>/dev/null || true
    fi
    
    cat "$test_output"
    rm -f "$test_output"
    
    if [ "$test_result" = "FAILED" ]; then
        exit 1
    fi
}

test_audio() {
    log "Testing audio system..."
    
    if [ -f "$PROJECT_ROOT/test-complete-audio-system.sh" ]; then
        bash "$PROJECT_ROOT/test-complete-audio-system.sh"
    elif [ -f "$PROJECT_ROOT/audio_video_test.sh" ]; then
        bash "$PROJECT_ROOT/audio_video_test.sh"
    else
        error "Audio test scripts not found"
        exit 1
    fi
}

test_peppy() {
    log "Testing PeppyMeter requirements..."
    
    if [ -f "$PROJECT_ROOT/test_peppy_requirements.sh" ]; then
        bash "$PROJECT_ROOT/test_peppy_requirements.sh"
    else
        error "PeppyMeter test script not found"
        exit 1
    fi
}

test_network() {
    log "Testing network configurations..."
    
    if [ -f "$PROJECT_ROOT/tools/test/network-simulation-tests.sh" ]; then
        bash "$PROJECT_ROOT/tools/test/network-simulation-tests.sh"
    else
        error "Network simulation test script not found"
        exit 1
    fi
}

test_all() {
    log "Running complete test suite..."
    
    if [ -f "$PROJECT_ROOT/complete_test_suite.sh" ]; then
        bash "$PROJECT_ROOT/complete_test_suite.sh"
    elif [ -f "$PROJECT_ROOT/comprehensive-system-test.sh" ]; then
        bash "$PROJECT_ROOT/comprehensive-system-test.sh"
    else
        warn "Complete test suite not found, running individual tests..."
        test_display
        test_touchscreen
        test_audio
    fi
}

test_docker_simulation() {
    log "Running Docker-based system simulation..."
    
    if [ -f "$PROJECT_ROOT/START_COMPLETE_SIMULATION.sh" ]; then
        bash "$PROJECT_ROOT/START_COMPLETE_SIMULATION.sh"
    elif [ -f "$PROJECT_ROOT/START_SYSTEM_SIMULATION_SIMPLE.sh" ]; then
        bash "$PROJECT_ROOT/START_SYSTEM_SIMULATION_SIMPLE.sh"
    else
        error "Docker simulation scripts not found"
        exit 1
    fi
}

test_image_in_docker() {
    log "Testing image in Docker container..."
    
    if [ -f "$PROJECT_ROOT/test-image-in-container.sh" ]; then
        bash "$PROJECT_ROOT/test-image-in-container.sh"
    else
        error "Image test script not found"
        exit 1
    fi
}

verify_all() {
    log "Verifying all systems..."
    
    if [ -f "$PROJECT_ROOT/verify_everything.sh" ]; then
        bash "$PROJECT_ROOT/verify_everything.sh"
    else
        error "Verification script not found"
        exit 1
    fi
}

################################################################################
# MAIN MENU
################################################################################

show_menu() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  🧪 TEST TOOL - Unified Test Management                      ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "1) Test display"
    echo "2) Test touchscreen"
    echo "3) Test audio system"
    echo "4) Test PeppyMeter"
    echo "5) Test network configurations"
    echo "6) Run complete test suite"
    echo "7) Verify all systems"
    echo "8) Docker system simulation"
    echo "9) Test image in Docker"
    echo "0) Exit"
    echo ""
    read -p "Select option: " choice
}

main() {
    if [ "$1" = "--display" ] || [ "$1" = "-d" ]; then
        test_display
    elif [ "$1" = "--touchscreen" ] || [ "$1" = "-t" ]; then
        test_touchscreen
    elif [ "$1" = "--audio" ] || [ "$1" = "-a" ]; then
        test_audio
    elif [ "$1" = "--peppy" ] || [ "$1" = "-p" ]; then
        test_peppy
    elif [ "$1" = "--network" ] || [ "$1" = "-n" ]; then
        test_network
    elif [ "$1" = "--all" ] || [ "$1" = "-A" ]; then
        test_all
    elif [ "$1" = "--verify" ] || [ "$1" = "-v" ]; then
        verify_all
    elif [ "$1" = "--docker" ] || [ "$1" = "-D" ]; then
        test_docker_simulation
    elif [ "$1" = "--image" ] || [ "$1" = "-i" ]; then
        test_image_in_docker
    elif [ -z "$1" ]; then
        # Interactive mode
        while true; do
            show_menu
            case $choice in
                1) test_display ;;
                2) test_touchscreen ;;
                3) test_audio ;;
                4) test_peppy ;;
                5) test_network ;;
                6) test_all ;;
                7) verify_all ;;
                8) test_docker_simulation ;;
                9) test_image_in_docker ;;
                0) exit 0 ;;
                *) error "Invalid option" ;;
            esac
            echo ""
            read -p "Press Enter to continue..."
        done
    else
        error "Unknown option: $1"
        echo "Usage: $0 [--display|--touchscreen|--audio|--peppy|--network|--all|--verify|--docker|--image]"
        exit 1
    fi
}

main "$@"

