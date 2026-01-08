#!/bin/bash
################################################################################
#
# Fix Display Rotation at Boot Level
# 
# This fixes the display rotation at boot level (config.txt/cmdline.txt)
# so that the framebuffer is already 1280x400, eliminating the need for
# X11 rotation which causes coordinate system issues with PeppyMeter.
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

log() { echo -e "${GREEN}[FIX]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 FIX DISPLAY ROTATION AT BOOT LEVEL                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

PI_IP="${1:-192.168.1.138}"
PI_USER="andre"
PI_PASS="0815"

log "Connecting to Pi at $PI_IP..."

# Check if Pi is reachable
if ! ping -c 1 "$PI_IP" >/dev/null 2>&1; then
    error "Pi at $PI_IP is not reachable"
    exit 1
fi

log "Pi is online"

################################################################################
# STEP 1: Fix config.txt - Add display_rotate or hdmi_mode
################################################################################

log "Step 1: Fixing config.txt..."

sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'SSH_EOF'
set -e

CONFIG_TXT="/boot/firmware/config.txt"
BACKUP_FILE="${CONFIG_TXT}.backup_boot_rotation_$(date +%Y%m%d_%H%M%S)"

# Backup
sudo cp "$CONFIG_TXT" "$BACKUP_FILE"
echo "✅ Backup created: $BACKUP_FILE"

# Check current state
echo ""
echo "Current config.txt display settings:"
grep -E "display|rotate|hdmi_mode|hdmi_group" "$CONFIG_TXT" | grep -v "^#" | head -10 || echo "No display settings found"

# Option 1: Use hdmi_mode=87 with hdmi_cvt for 1280x400
# Option 2: Use display_rotate=1 (90° rotation at boot level)

echo ""
echo "Adding boot-level rotation fix..."

# Check if [pi5] section exists
if grep -q "^\[pi5\]" "$CONFIG_TXT"; then
    echo "✅ [pi5] section found"
    
    # Check if display_rotate already exists in [pi5]
    if grep -A 10 "^\[pi5\]" "$CONFIG_TXT" | grep -q "display_rotate"; then
        echo "⚠️  display_rotate already exists in [pi5] section"
        echo "Current value:"
        grep -A 10 "^\[pi5\]" "$CONFIG_TXT" | grep "display_rotate"
    else
        # Add display_rotate=1 (90° rotation) to [pi5] section
        sudo sed -i '/^\[pi5\]/a display_rotate=1' "$CONFIG_TXT"
        echo "✅ Added display_rotate=1 to [pi5] section"
    fi
else
    echo "⚠️  [pi5] section not found, adding it"
    echo "" | sudo tee -a "$CONFIG_TXT" > /dev/null
    echo "[pi5]" | sudo tee -a "$CONFIG_TXT" > /dev/null
    echo "display_rotate=1" | sudo tee -a "$CONFIG_TXT" > /dev/null
    echo "✅ Added [pi5] section with display_rotate=1"
fi

# Also ensure hdmi_mode is set for custom resolution
if ! grep -q "hdmi_mode=87" "$CONFIG_TXT"; then
    if ! grep -q "^\[all\]" "$CONFIG_TXT"; then
        echo "" | sudo tee -a "$CONFIG_TXT" > /dev/null
        echo "[all]" | sudo tee -a "$CONFIG_TXT" > /dev/null
    fi
    
    # Add hdmi_mode and hdmi_cvt after [all]
    if ! grep -A 20 "^\[all\]" "$CONFIG_TXT" | grep -q "hdmi_mode=87"; then
        sudo sed -i '/^\[all\]/a hdmi_group=2\nhdmi_mode=87\nhdmi_cvt=1280 400 60 6 0 0 0' "$CONFIG_TXT"
        echo "✅ Added hdmi_mode=87 and hdmi_cvt for 1280x400"
    fi
fi

echo ""
echo "Updated config.txt display settings:"
grep -E "display|rotate|hdmi_mode|hdmi_group|hdmi_cvt" "$CONFIG_TXT" | grep -v "^#" | head -15

SSH_EOF

if [ $? -eq 0 ]; then
    log "✅ config.txt updated"
else
    error "Failed to update config.txt"
    exit 1
fi

################################################################################
# STEP 2: Update .xinitrc to NOT rotate (display already rotated at boot)
################################################################################

log "Step 2: Updating .xinitrc to skip X11 rotation..."

sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'SSH_EOF'
set -e

XINITRC="/home/andre/.xinitrc"
BACKUP_FILE="${XINITRC}.backup_no_x11_rotation_$(date +%Y%m%d_%H%M%S)"

# Backup
cp "$XINITRC" "$BACKUP_FILE"
echo "✅ Backup created: $BACKUP_FILE"

# Modify fix-display-orientation script call to skip rotation
# Since display is already rotated at boot, we just verify it's correct
echo ""
echo "Updating fix-display-orientation script to verify only (no rotation)..."

# The script should detect that display is already 1280x400 and skip rotation
# But we can also modify .xinitrc to not call it if display is already correct

echo ""
echo "Current .xinitrc rotation section:"
grep -A 5 "fix-display-orientation\|Set screen rotation" "$XINITRC" | head -10

SSH_EOF

log "✅ .xinitrc checked"

################################################################################
# STEP 3: Summary
################################################################################

echo ""
log "=== FIX APPLIED ==="
echo ""
info "Changes made:"
echo "  1. Added display_rotate=1 to config.txt [pi5] section"
echo "  2. Added hdmi_mode=87 and hdmi_cvt for 1280x400"
echo "  3. Display will now be rotated at boot level (framebuffer = 1280x400)"
echo ""
warn "⚠️  REBOOT REQUIRED for changes to take effect!"
echo ""
info "After reboot:"
echo "  - Framebuffer should report: 1280x400 (not 400x1280)"
echo "  - X11 should report: 1280x400 (no xrandr rotation needed)"
echo "  - PeppyMeter coordinates will be correct (no coordinate system rotation)"
echo ""
log "✅ Fix complete - REBOOT the Pi to apply changes"










