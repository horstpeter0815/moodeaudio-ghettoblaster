#!/bin/bash
################################################################################
#
# Restore Working Touch Configuration
#
# Based on VERSION_1.0_GHETTOBLASTER.md working config
# Matrix: "0 -1 1 1 0 0 0 0 1" (90° CCW rotation)
#
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

log() { echo -e "\033[0;32m[RESTORE]\033[0m $1"; }

# Find SD card
BOOTFS=""
ROOTFS=""

for vol in /Volumes/*; do
    if [ -d "$vol" ] && [ "$vol" != "/Volumes/Macintosh HD" ]; then
        if [ -f "$vol/config.txt" ] || [ -f "$vol/cmdline.txt" ]; then
            BOOTFS="$vol"
        elif [ -d "$vol/etc" ] && [ -d "$vol/usr" ]; then
            ROOTFS="$vol"
        fi
    fi
done

if [ -z "$ROOTFS" ]; then
    echo "❌ SD card root partition not found!"
    exit 1
fi

log "Found root partition: $ROOTFS"

# Restore working touch config from VERSION_1.0_GHETTOBLASTER.md
TOUCH_CONF="$ROOTFS/etc/X11/xorg.conf.d/99-touch-calibration.conf"

log "Restoring working touch configuration..."
mkdir -p "$(dirname "$TOUCH_CONF")" 2>/dev/null || true

cat > "$TOUCH_CONF" << 'EOF'
Section "InputClass"
    Identifier "WaveShare Touchscreen"
    MatchProduct "WaveShare"
    Option "TransformationMatrix" "0 -1 1 1 0 0 0 0 1"
EndSection
EOF

log "✅ Restored working touch matrix: 0 -1 1 1 0 0 0 0 1"
log "   This is the 90° CCW rotation matrix from working config"
echo ""
log "After boot, touch should work correctly!"
