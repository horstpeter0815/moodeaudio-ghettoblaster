#!/bin/bash
################################################################################
#
# Fix Boot Screen Landscape Orientation
#
# Updates cmdline.txt to ensure boot screen (framebuffer/console) is in
# landscape mode for Waveshare 7.9" display.
#
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[FIX]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

CMDLINE_FILE="/boot/firmware/cmdline.txt"
BACKUP_FILE="${CMDLINE_FILE}.backup.$(date +%Y%m%d_%H%M%S)"

log "Fixing boot screen to landscape orientation..."

# Check if file exists
if [ ! -f "$CMDLINE_FILE" ]; then
    error "cmdline.txt not found at $CMDLINE_FILE"
    exit 1
fi

# Backup existing cmdline
log "Backing up existing cmdline.txt to $BACKUP_FILE"
sudo cp "$CMDLINE_FILE" "$BACKUP_FILE"

# Read current cmdline
CMDLINE="$(cat "$CMDLINE_FILE" | tr -d '\n' | xargs)"

# Remove any existing video=... token
CMDLINE="$(echo "$CMDLINE" | sed -E 's/(^| )video=[^ ]+//g' | xargs)"

# Remove any existing fbcon=rotate:... token
CMDLINE="$(echo "$CMDLINE" | sed -E 's/(^| )fbcon=rotate:[0-9]+//g' | xargs)"

# Add landscape rotation for framebuffer and console
# rotate=90: Rotates framebuffer 90° clockwise (400x1280 portrait → 1280x400 landscape)
# fbcon=rotate:1: Rotates console 90° clockwise (1=90°, 2=180°, 3=270°)
CMDLINE="$CMDLINE video=HDMI-A-1:400x1280M@60,rotate=90 fbcon=rotate:1"

# Write updated cmdline
echo "$CMDLINE" | sudo tee "$CMDLINE_FILE" > /dev/null

log "✅ Boot screen rotation updated"
info "Added: video=HDMI-A-1:400x1280M@60,rotate=90 fbcon=rotate:1"
echo ""
info "Changes will take effect after reboot:"
echo "  sudo reboot"
echo ""
info "To verify after reboot, check:"
echo "  cat /proc/cmdline | grep -o 'video=[^ ]*'"
echo "  cat /proc/cmdline | grep -o 'fbcon=rotate:[0-9]*'"
