#!/bin/bash
# Enable boot boost (arm_boost=1) for Pi 5 performance

set -e

BOOTFS="/Volumes/bootfs"

if [ ! -d "$BOOTFS" ]; then
    echo "❌ SD card boot partition not mounted"
    echo "   Please insert SD card and wait for it to mount"
    exit 1
fi

CONFIG="$BOOTFS/config.txt"

if [ ! -f "$CONFIG" ]; then
    echo "❌ config.txt not found at $CONFIG"
    exit 1
fi

echo "=== ENABLING BOOT BOOST (arm_boost=1) ==="
echo ""

# Backup
BACKUP="$CONFIG.backup.before-boot-boost-$(date +%Y%m%d_%H%M%S)"
cp "$CONFIG" "$BACKUP"
echo "📦 Backup: $BACKUP"
echo ""

# Check if already enabled
if grep -q "^arm_boost=1" "$CONFIG"; then
    echo "✅ arm_boost=1 is already enabled"
    exit 0
fi

# Remove any existing arm_boost lines
sed -i.bak '/^arm_boost=/d' "$CONFIG" 2>/dev/null || sed -i '' '/^arm_boost=/d' "$CONFIG" 2>/dev/null || {
    # Fallback for systems without sed -i
    grep -v "^arm_boost=" "$CONFIG" > "$CONFIG.tmp" && mv "$CONFIG.tmp" "$CONFIG"
}

# Find [all] section and add arm_boost=1
if grep -q "^\[all\]" "$CONFIG"; then
    # Add after [all] line
    awk '/^\[all\]/ {print; print "arm_boost=1"; next} {print}' "$CONFIG" > "$CONFIG.tmp" && mv "$CONFIG.tmp" "$CONFIG"
    echo "✅ Added arm_boost=1 to [all] section"
else
    # Add at the end of file
    echo "" >> "$CONFIG"
    echo "[all]" >> "$CONFIG"
    echo "arm_boost=1" >> "$CONFIG"
    echo "✅ Added [all] section with arm_boost=1"
fi

echo ""
echo "=== VERIFICATION ==="
if grep -q "^arm_boost=1" "$CONFIG"; then
    echo "✅ arm_boost=1 is now enabled"
    echo ""
    echo "Configuration:"
    grep -A 2 "^\[all\]" "$CONFIG" | head -5
else
    echo "❌ Failed to enable arm_boost=1"
    exit 1
fi

echo ""
echo "✅ Boot boost activated!"
echo ""
echo "This enables Pi 5 performance boost for faster boot and operation."
