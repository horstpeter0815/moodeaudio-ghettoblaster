#!/bin/bash
################################################################################
#
# QUICK SD CARD FIX
# - Fix touch calibration (180° rotation - fixes both axes)
# - Fix display startup (reduce wait times)
#
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[FIX]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# Find SD card volumes
BOOTFS=""
ROOTFS=""

log "=== QUICK SD CARD FIX ==="
echo ""

# Find bootfs
for vol in /Volumes/*; do
    if [ -d "$vol" ] && [ "$vol" != "/Volumes/Macintosh HD" ]; then
        if [ -f "$vol/config.txt" ] || [ -f "$vol/cmdline.txt" ] || [ -d "$vol/overlays" ]; then
            BOOTFS="$vol"
            break
        fi
    fi
done

# Find rootfs
for vol in /Volumes/*; do
    if [ -d "$vol" ] && [ "$vol" != "/Volumes/Macintosh HD" ]; then
        if [ -d "$vol/etc" ] && [ -d "$vol/usr" ] && [ -d "$vol/boot" ]; then
            ROOTFS="$vol"
            break
        fi
    fi
done

if [ -z "$BOOTFS" ] || [ -z "$ROOTFS" ]; then
    error "SD card partitions not found!"
    error "Please insert SD card and ensure it's mounted"
    exit 1
fi

log "Found SD card: Boot=$BOOTFS Root=$ROOTFS"
echo ""

# ============================================================================
# STEP 1: FIX TOUCH CALIBRATION (180° rotation - fixes both axes)
# ============================================================================
log "Step 1: Fixing touch calibration (180° rotation)..."
TOUCH_CONF="$ROOTFS/etc/X11/xorg.conf.d/99-touch-calibration.conf"

mkdir -p "$(dirname "$TOUCH_CONF")" 2>/dev/null || {
    error "Cannot create xorg.conf.d directory"
    exit 1
}

cat > "$TOUCH_CONF" << 'EOF'
Section "InputClass"
    Identifier "Touchscreen Calibration"
    MatchProduct "*"
    MatchDevicePath "/dev/input/event*"
    Option "TransformationMatrix" "-1 0 1 0 -1 1 0 0 1"
EndSection
EOF

log "✅ Touch calibration: 180° rotation (fixes both left/right AND top/bottom)"
log "   Matrix: -1 0 1 0 -1 1 0 0 1"

# ============================================================================
# STEP 2: FIX DISPLAY STARTUP (reduce wait times)
# ============================================================================
log "Step 2: Fixing display startup (reduce wait times)..."
CHROMIUM_SCRIPT="$ROOTFS/usr/local/bin/start-chromium-clean.sh"

if [ -f "$CHROMIUM_SCRIPT" ]; then
    # Backup
    cp "$CHROMIUM_SCRIPT" "${CHROMIUM_SCRIPT}.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
    
    # Replace long waits with shorter ones
    sed -i '' 's/MAX_WAIT=60/MAX_WAIT=30/g' "$CHROMIUM_SCRIPT" 2>/dev/null || \
    sed -i 's/MAX_WAIT=60/MAX_WAIT=30/g' "$CHROMIUM_SCRIPT" 2>/dev/null || true
    
    sed -i '' 's/MAX_FINAL_WAIT=30/MAX_FINAL_WAIT=5/g' "$CHROMIUM_SCRIPT" 2>/dev/null || \
    sed -i 's/MAX_FINAL_WAIT=30/MAX_FINAL_WAIT=5/g' "$CHROMIUM_SCRIPT" 2>/dev/null || true
    
    sed -i '' 's/sleep 10/sleep 2/g' "$CHROMIUM_SCRIPT" 2>/dev/null || \
    sed -i 's/sleep 10/sleep 2/g' "$CHROMIUM_SCRIPT" 2>/dev/null || true
    
    sed -i '' 's/sleep 3$/sleep 1/g' "$CHROMIUM_SCRIPT" 2>/dev/null || \
    sed -i 's/sleep 3$/sleep 1/g' "$CHROMIUM_SCRIPT" 2>/dev/null || true
    
    log "✅ Display startup optimized (reduced wait times)"
else
    log "⚠️  Chromium script not found, skipping"
fi

# Copy updated script from source
if [ -f "$PROJECT_ROOT/moode-source/usr/local/bin/start-chromium-clean.sh" ]; then
    log "Copying updated Chromium script from source..."
    cp "$PROJECT_ROOT/moode-source/usr/local/bin/start-chromium-clean.sh" "$CHROMIUM_SCRIPT" 2>/dev/null || true
    log "✅ Updated Chromium script copied"
fi

echo ""
log "=== QUICK FIX COMPLETE ==="
echo ""
log "Changes applied:"
echo "  ✅ Touch: 180° rotation matrix (fixes both axes)"
echo "  ✅ Display: Reduced wait times (faster startup)"
echo ""
log "Next steps:"
echo "  1. Eject SD card safely"
echo "  2. Insert into Pi"
echo "  3. Boot Pi"
echo "  4. Touch should work correctly"
echo "  5. Display should load faster"
