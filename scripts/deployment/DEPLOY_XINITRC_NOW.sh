#!/bin/bash
# Quick deployment script - run with: sudo ./DEPLOY_XINITRC_NOW.sh

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ROOTFS="/Volumes/rootfs"
XINITRC_SOURCE="$PROJECT_ROOT/moode-source/home/xinitrc.default"
XINITRC_TARGET="$ROOTFS/home/andre/.xinitrc"

if [ ! -d "$ROOTFS" ]; then
    echo "❌ SD card not mounted at $ROOTFS"
    exit 1
fi

if [ ! -f "$XINITRC_SOURCE" ]; then
    echo "❌ Source file not found: $XINITRC_SOURCE"
    exit 1
fi

echo "=== Deploying fixed .xinitrc ==="
echo "Source: $XINITRC_SOURCE"
echo "Target: $XINITRC_TARGET"
echo ""

# Backup existing
if [ -f "$XINITRC_TARGET" ]; then
    sudo cp "$XINITRC_TARGET" "${XINITRC_TARGET}.backup.$(date +%Y%m%d_%H%M%S)"
    echo "✅ Backed up existing .xinitrc"
fi

# Deploy new
sudo cp "$XINITRC_SOURCE" "$XINITRC_TARGET"
sudo chmod +x "$XINITRC_TARGET"
sudo chown 1000:1000 "$XINITRC_TARGET"

echo "✅ .xinitrc deployed successfully!"
echo ""
echo "Next steps:"
echo "  1. Eject SD card safely"
echo "  2. Boot Pi"
echo "  3. Set moOde database: sudo moodeutl -i \"UPDATE cfg_system SET value='portrait' WHERE param='hdmi_scn_orient';\""
echo "  4. Reboot: sudo reboot"
