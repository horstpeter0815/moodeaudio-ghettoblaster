#!/bin/bash
################################################################################
#
# UNIFIED FIX TOOL
# 
# Consolidates all fix-related scripts into one unified tool
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
    echo -e "${GREEN}[FIX]${NC} $1"
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
# FIX FUNCTIONS
################################################################################

fix_display() {
    log "Fixing display issues..."
    
    # Show relevant solutions from WISSENSBASIS
    if [ -f "$WISSENSBASIS_HELPER" ]; then
        info "Checking WISSENSBASIS for relevant solutions..."
        "$WISSENSBASIS_HELPER" solution display 2>/dev/null || true
        echo ""
    fi
    
    # Use the most comprehensive display fix
    if [ -f "$PROJECT_ROOT/fix_everything_improved.sh" ]; then
        bash "$PROJECT_ROOT/fix_everything_improved.sh"
    elif [ -f "$PROJECT_ROOT/fix_everything.sh" ]; then
        bash "$PROJECT_ROOT/fix_everything.sh"
    else
        error "Display fix scripts not found"
        exit 1
    fi
}

fix_touchscreen() {
    log "Fixing touchscreen..."
    
    # Show relevant solutions from WISSENSBASIS
    if [ -f "$WISSENSBASIS_HELPER" ]; then
        info "Checking WISSENSBASIS for relevant solutions..."
        "$WISSENSBASIS_HELPER" solution touchscreen 2>/dev/null || true
        echo ""
    fi
    
    if [ -f "$PROJECT_ROOT/fix_touchscreen_coordinates.sh" ]; then
        bash "$PROJECT_ROOT/fix_touchscreen_coordinates.sh"
    elif [ -f "$PROJECT_ROOT/FIX_TOUCHSCREEN_CLEAN.sh" ]; then
        bash "$PROJECT_ROOT/FIX_TOUCHSCREEN_CLEAN.sh"
    else
        error "Touchscreen fix scripts not found"
        exit 1
    fi
}

fix_audio() {
    log "Fixing audio hardware..."
    
    # Show relevant solutions from WISSENSBASIS
    if [ -f "$WISSENSBASIS_HELPER" ]; then
        info "Checking WISSENSBASIS for relevant solutions..."
        "$WISSENSBASIS_HELPER" solution audio 2>/dev/null || true
        echo ""
    fi
    
    if [ -f "$PROJECT_ROOT/FIX_AUDIO_HARDWARE.sh" ]; then
        bash "$PROJECT_ROOT/FIX_AUDIO_HARDWARE.sh"
    elif [ -f "$PROJECT_ROOT/fix-audio-hardware-pi5.sh" ]; then
        bash "$PROJECT_ROOT/fix-audio-hardware-pi5.sh"
    else
        error "Audio fix scripts not found"
        exit 1
    fi
}

fix_network() {
    log "Fixing network configuration..."
    
    if [ -f "$PROJECT_ROOT/FIX_ETHERNET_NOW.sh" ]; then
        bash "$PROJECT_ROOT/FIX_ETHERNET_NOW.sh"
    elif [ -f "$PROJECT_ROOT/NETWORK_FIX_20251207.sh" ]; then
        bash "$PROJECT_ROOT/NETWORK_FIX_20251207.sh"
    else
        error "Network fix scripts not found"
        exit 1
    fi
}

fix_ssh() {
    log "Fixing SSH configuration..."
    
    if [ -f "$PROJECT_ROOT/SSH_FIX_20251207.sh" ]; then
        bash "$PROJECT_ROOT/SSH_FIX_20251207.sh"
    elif [ -f "$PROJECT_ROOT/setup-all-ssh-permanent.sh" ]; then
        bash "$PROJECT_ROOT/setup-all-ssh-permanent.sh"
    else
        error "SSH fix scripts not found"
        exit 1
    fi
}

fix_amp100() {
    log "Fixing AMP100 hardware..."
    
    if [ -f "$PROJECT_ROOT/fix-amp100-hardware-reset.sh" ]; then
        bash "$PROJECT_ROOT/fix-amp100-hardware-reset.sh"
    elif [ -f "$PROJECT_ROOT/CONFIGURE_AMP100.sh" ]; then
        bash "$PROJECT_ROOT/CONFIGURE_AMP100.sh"
    else
        error "AMP100 fix scripts not found"
        exit 1
    fi
}

fix_all() {
    log "Fixing all systems..."
    
    if [ -f "$PROJECT_ROOT/COMPLETE_FIX_ALL_ISSUES.sh" ]; then
        bash "$PROJECT_ROOT/COMPLETE_FIX_ALL_ISSUES.sh"
    elif [ -f "$PROJECT_ROOT/MASTER_FIX_ALL.sh" ]; then
        bash "$PROJECT_ROOT/MASTER_FIX_ALL.sh"
    elif [ -f "$PROJECT_ROOT/fix-all-systems.sh" ]; then
        bash "$PROJECT_ROOT/fix-all-systems.sh"
    else
        warn "Comprehensive fix script not found, running individual fixes..."
        fix_display
        fix_touchscreen
        fix_audio
        fix_network
    fi
}

fix_sd() {
    log "Hardening SD card (bootfs/rootfs)..."
    if [ -f "$SCRIPT_DIR/fix/harden-sd.sh" ]; then
        sudo bash "$SCRIPT_DIR/fix/harden-sd.sh"
    else
        error "SD harden script not found: $SCRIPT_DIR/fix/harden-sd.sh"
        exit 1
    fi
}

fix_sd_macos() {
    log "macOS: Repair rootfs (ext4) + harden SD..."
    if [ -f "$SCRIPT_DIR/fix/sd-repair-and-harden-macos.sh" ]; then
        sudo bash "$SCRIPT_DIR/fix/sd-repair-and-harden-macos.sh"
    else
        error "Script not found: $SCRIPT_DIR/fix/sd-repair-and-harden-macos.sh"
        exit 1
    fi
}

fix_sd_macos_preflight() {
    log "macOS: SD repair preflight (no changes)..."
    if [ -f "$SCRIPT_DIR/fix/sd-repair-and-harden-macos.sh" ]; then
        sudo bash "$SCRIPT_DIR/fix/sd-repair-and-harden-macos.sh" --preflight
    else
        error "Script not found: $SCRIPT_DIR/fix/sd-repair-and-harden-macos.sh"
        exit 1
    fi
}

################################################################################
# MAIN MENU
################################################################################

show_menu() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  🔧 FIX TOOL - Unified Fix Management                        ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "1) Fix display issues"
    echo "2) Fix touchscreen"
    echo "3) Fix audio hardware"
    echo "4) Fix network configuration"
    echo "5) Fix SSH configuration"
    echo "6) Fix AMP100 hardware"
    echo "7) Fix all systems"
    echo "8) Harden SD card (bootfs/rootfs)"
    echo "9) macOS: Repair rootfs + harden SD (one-shot)"
    echo "10) macOS: SD repair preflight (no changes)"
    echo "0) Exit"
    echo ""
    read -p "Select option: " choice
}

main() {
    if [ "$1" = "--display" ] || [ "$1" = "-d" ]; then
        fix_display
    elif [ "$1" = "--touchscreen" ] || [ "$1" = "-t" ]; then
        fix_touchscreen
    elif [ "$1" = "--audio" ] || [ "$1" = "-a" ]; then
        fix_audio
    elif [ "$1" = "--network" ] || [ "$1" = "-n" ]; then
        fix_network
    elif [ "$1" = "--ssh" ] || [ "$1" = "-s" ]; then
        fix_ssh
    elif [ "$1" = "--amp100" ] || [ "$1" = "-A" ]; then
        fix_amp100
    elif [ "$1" = "--all" ] || [ "$1" = "-a" ]; then
        fix_all
    elif [ "$1" = "--sd" ] || [ "$1" = "--harden-sd" ]; then
        fix_sd
    elif [ "$1" = "--sd-macos" ] || [ "$1" = "--harden-sd-macos" ]; then
        fix_sd_macos
    elif [ "$1" = "--sd-macos-preflight" ]; then
        fix_sd_macos_preflight
    elif [ -z "$1" ]; then
        # Interactive mode
        while true; do
            show_menu
            case $choice in
                1) fix_display ;;
                2) fix_touchscreen ;;
                3) fix_audio ;;
                4) fix_network ;;
                5) fix_ssh ;;
                6) fix_amp100 ;;
                7) fix_all ;;
                8) fix_sd ;;
                9) fix_sd_macos ;;
                10) fix_sd_macos_preflight ;;
                0) exit 0 ;;
                *) error "Invalid option" ;;
            esac
            echo ""
            read -p "Press Enter to continue..."
        done
    else
        error "Unknown option: $1"
        echo "Usage: $0 [--display|--touchscreen|--audio|--network|--ssh|--amp100|--all|--sd|--sd-macos|--sd-macos-preflight]"
        exit 1
    fi
}

main "$@"

