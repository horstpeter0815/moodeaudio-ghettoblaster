#!/bin/bash
################################################################################
# ENABLE SSH ON STANDARD MOODE DOWNLOAD
# 
# Problem: Standard moOde downloads have SSH DISABLED by default
# Solution: Create /boot/firmware/ssh file on SD card
#
# This script:
# 1. Finds mounted SD card
# 2. Creates /boot/firmware/ssh file
# 3. Applies config files
################################################################################

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[OK]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_TXT="$SCRIPT_DIR/MOODE_PI5_WAVESHARE_HDMI_CONFIG.txt"

################################################################################
# FIND SD CARD
################################################################################

find_sd_card() {
    info "Searching for mounted SD card..."
    
    # Check common macOS mount points
    for mount in /Volumes/boot /Volumes/BOOT /Volumes/firmware /Volumes/FIRMWARE; do
        if [ -d "$mount" ] && [ -f "$mount/config.txt" ]; then
            echo "$mount"
            return 0
        fi
    done
    
    # Check diskutil for mounted volumes
    while IFS= read -r line; do
        if echo "$line" | grep -qiE "boot|firmware|moode|raspberry"; then
            mount_point=$(echo "$line" | awk '{print $NF}')
            if [ -d "$mount_point" ] && [ -f "$mount_point/config.txt" ]; then
                echo "$mount_point"
                return 0
            fi
        fi
    done < <(mount | grep -i "disk\|boot" || true)
    
    return 1
}

################################################################################
# ENABLE SSH ON SD CARD
################################################################################

enable_ssh_on_sd() {
    local sd_mount="$1"
    
    if [ ! -d "$sd_mount" ]; then
        error "SD card mount point invalid: $sd_mount"
        return 1
    fi
    
    log "SD card found: $sd_mount"
    
    # CRITICAL: Create SSH flag file
    info "Creating SSH flag file..."
    
    # Try both locations (Pi 4 vs Pi 5)
    SSH_CREATED=0
    
    # Pi 5: /boot/firmware/ssh
    if [ -d "$sd_mount/firmware" ]; then
        touch "$sd_mount/firmware/ssh" 2>/dev/null && SSH_CREATED=1
        if [ -f "$sd_mount/firmware/ssh" ]; then
            log "✅ Created: $sd_mount/firmware/ssh"
        fi
    fi
    
    # Pi 4: /boot/ssh (root of boot partition)
    touch "$sd_mount/ssh" 2>/dev/null && SSH_CREATED=1
    if [ -f "$sd_mount/ssh" ]; then
        log "✅ Created: $sd_mount/ssh"
    fi
    
    if [ $SSH_CREATED -eq 0 ]; then
        error "Failed to create SSH flag file!"
        return 1
    fi
    
    # Verify file exists
    if [ -f "$sd_mount/ssh" ] || [ -f "$sd_mount/firmware/ssh" ]; then
        log "✅ SSH will be enabled on next boot!"
        return 0
    else
        error "SSH flag file not found after creation!"
        return 1
    fi
}

################################################################################
# APPLY CONFIG FILES
################################################################################

apply_config_files() {
    local sd_mount="$1"
    
    # Backup existing config
    if [ -f "$sd_mount/config.txt" ]; then
        cp "$sd_mount/config.txt" "$sd_mount/config.txt.backup_$(date +%Y%m%d_%H%M%S)"
        info "Backup created: config.txt.backup_*"
    fi
    
    # Apply config.txt
    if [ -f "$CONFIG_TXT" ]; then
        cp "$CONFIG_TXT" "$sd_mount/config.txt"
        log "✅ config.txt applied"
    else
        warn "Config file not found: $CONFIG_TXT"
    fi
    
    # Sync to ensure writes are complete
    sync
    log "✅ All files written and synced"
}

################################################################################
# MAIN
################################################################################

main() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  🔧 ENABLE SSH ON STANDARD MOODE DOWNLOAD                   ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    
    info "This script will:"
    info "  1. Find your SD card"
    info "  2. Create /boot/firmware/ssh file (enables SSH)"
    info "  3. Apply config files"
    echo ""
    
    # Find SD card
    SD_MOUNT=$(find_sd_card)
    
    if [ -z "$SD_MOUNT" ]; then
        error "SD card not found!"
        echo ""
        warn "Please:"
        warn "  1. Remove SD card from Pi"
        warn "  2. Insert SD card into Mac"
        warn "  3. Run this script again"
        echo ""
        info "Alternative: Use Web SSH (Shellinabox) on port 4200"
        info "  → Open: http://<PI_IP>:4200"
        return 1
    fi
    
    log "SD card found: $SD_MOUNT"
    echo ""
    
    # Enable SSH
    if ! enable_ssh_on_sd "$SD_MOUNT"; then
        error "Failed to enable SSH!"
        return 1
    fi
    
    echo ""
    
    # Apply config files
    apply_config_files "$SD_MOUNT"
    
    echo ""
    log "✅ Setup complete!"
    echo ""
    info "Next steps:"
    info "  1. Eject SD card safely"
    info "  2. Insert SD card into Pi"
    info "  3. Boot Pi"
    info "  4. SSH will be enabled!"
    echo ""
    info "SSH connection:"
    info "  ssh moode@<PI_IP>"
    info "  Password: moodeaudio"
    echo ""
}

main "$@"

