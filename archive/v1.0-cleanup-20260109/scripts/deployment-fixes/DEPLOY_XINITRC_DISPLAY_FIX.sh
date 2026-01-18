#!/bin/bash
################################################################################
#
# DEPLOY XINITRC DISPLAY FIX
# 
# Deploys the fixed .xinitrc.default with forum solution to the Pi
# Supports: SSH deployment and SD card deployment
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[DEPLOY]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# Configuration
PI_HOST="${PI_HOST:-192.168.10.2}"
PI_USER="${PI_USER:-andre}"
PI_PASS="${PI_PASS:-0815}"
ROOTFS_MOUNT="${ROOTFS_MOUNT:-/Volumes/rootfs}"

XINITRC_SOURCE="$PROJECT_ROOT/moode-source/home/xinitrc.default"
XINITRC_TARGET="/home/$PI_USER/.xinitrc"

# Check if source file exists
if [ ! -f "$XINITRC_SOURCE" ]; then
    error "Source file not found: $XINITRC_SOURCE"
    exit 1
fi

log "=== DEPLOYING XINITRC DISPLAY FIX ==="
log "Source: $XINITRC_SOURCE"
log ""

# Function: Deploy via SSH
deploy_via_ssh() {
    log "Deploying via SSH to $PI_USER@$PI_HOST..."
    
    # Check if host is reachable
    if ! ping -c 1 -W 1 "$PI_HOST" >/dev/null 2>&1; then
        error "Cannot reach $PI_HOST. Is the Pi powered on and connected?"
        return 1
    fi
    
    # Backup existing .xinitrc
    sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=accept-new "$PI_USER@$PI_HOST" \
        "if [ -f $XINITRC_TARGET ]; then cp $XINITRC_TARGET ${XINITRC_TARGET}.backup.\$(date +%Y%m%d_%H%M%S); fi" 2>/dev/null || true
    
    # Copy new .xinitrc
    sshpass -p "$PI_PASS" scp -o StrictHostKeyChecking=accept-new \
        "$XINITRC_SOURCE" "$PI_USER@$PI_HOST:$XINITRC_TARGET" || {
        error "Failed to copy .xinitrc via SSH"
        return 1
    }
    
    # Set permissions
    sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=accept-new "$PI_USER@$PI_HOST" \
        "chmod +x $XINITRC_TARGET && chown $PI_USER:$PI_USER $XINITRC_TARGET" || {
        error "Failed to set permissions"
        return 1
    }
    
    # Set moOde database setting
    log "Setting moOde database: hdmi_scn_orient='portrait'..."
    sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=accept-new "$PI_USER@$PI_HOST" \
        "sudo moodeutl -i \"UPDATE cfg_system SET value='portrait' WHERE param='hdmi_scn_orient';\" 2>/dev/null || true" || {
        warn "Could not set moOde database setting (may need manual setting)"
    }
    
    log "✅ Deployed via SSH successfully"
    return 0
}

# Function: Deploy to mounted SD card
deploy_to_sd() {
    log "Deploying to mounted SD card at $ROOTFS_MOUNT..."
    
    if [ ! -d "$ROOTFS_MOUNT" ]; then
        error "SD card not mounted at $ROOTFS_MOUNT"
        return 1
    fi
    
    # Create home directory if needed
    mkdir -p "$ROOTFS_MOUNT/home/$PI_USER"
    
    # Backup existing .xinitrc (requires sudo on macOS)
    if [ -f "$ROOTFS_MOUNT$XINITRC_TARGET" ]; then
        sudo cp "$ROOTFS_MOUNT$XINITRC_TARGET" \
           "$ROOTFS_MOUNT${XINITRC_TARGET}.backup.$(date +%Y%m%d_%H%M%S)" || {
            warn "Could not backup existing .xinitrc (may not exist)"
        }
        log "Backed up existing .xinitrc"
    fi
    
    # Copy new .xinitrc (requires sudo on macOS)
    sudo cp "$XINITRC_SOURCE" "$ROOTFS_MOUNT$XINITRC_TARGET" || {
        error "Failed to copy .xinitrc to SD card (may need sudo)"
        return 1
    }
    
    # Set permissions (requires sudo on macOS)
    sudo chmod +x "$ROOTFS_MOUNT$XINITRC_TARGET" || {
        error "Failed to set execute permission"
        return 1
    }
    sudo chown 1000:1000 "$ROOTFS_MOUNT$XINITRC_TARGET" || {
        error "Failed to set ownership"
        return 1
    }
    
    log "✅ Deployed to SD card successfully"
    warn "Note: moOde database setting must be set after boot (hdmi_scn_orient='portrait')"
    return 0
}

# Main deployment logic
main() {
    # Try SSH first (preferred for live systems)
    if ping -c 1 -W 1 "$PI_HOST" >/dev/null 2>&1; then
        info "Pi is reachable at $PI_HOST"
        if deploy_via_ssh; then
            log ""
            log "✅✅✅ DEPLOYMENT COMPLETE ✅✅✅"
            log ""
            log "Next steps:"
            log "  1. Reboot the Pi: ssh $PI_USER@$PI_HOST 'sudo reboot'"
            log "  2. Verify display shows 1280x400 landscape"
            log "  3. Check: DISPLAY=:0 xrandr --query"
            return 0
        else
            warn "SSH deployment failed, trying SD card..."
        fi
    else
        info "Pi not reachable, trying SD card deployment..."
    fi
    
    # Try SD card deployment
    if [ -d "$ROOTFS_MOUNT" ]; then
        if deploy_to_sd; then
            log ""
            log "✅✅✅ DEPLOYMENT COMPLETE ✅✅✅"
            log ""
            log "Next steps:"
            log "  1. Eject SD card safely"
            log "  2. Boot Pi with SD card"
            log "  3. After boot, set moOde database:"
            log "     sudo moodeutl -i \"UPDATE cfg_system SET value='portrait' WHERE param='hdmi_scn_orient';\""
            log "  4. Reboot: sudo reboot"
            return 0
        else
            error "SD card deployment failed"
        fi
    else
        error "Neither SSH nor SD card deployment available"
        error "Options:"
        error "  1. Ensure Pi is reachable at $PI_HOST"
        error "  2. Mount SD card at $ROOTFS_MOUNT"
        return 1
    fi
}

# Check for sshpass (needed for SSH deployment)
if ! command -v sshpass >/dev/null 2>&1; then
    warn "sshpass not found. Installing via Homebrew..."
    if command -v brew >/dev/null 2>&1; then
        brew install hudochenkov/sshpass/sshpass || {
            error "Failed to install sshpass. Install manually: brew install hudochenkov/sshpass/sshpass"
            exit 1
        }
    else
        error "Homebrew not found. Install sshpass manually or use SD card deployment"
        exit 1
    fi
fi

# Run main deployment
main
