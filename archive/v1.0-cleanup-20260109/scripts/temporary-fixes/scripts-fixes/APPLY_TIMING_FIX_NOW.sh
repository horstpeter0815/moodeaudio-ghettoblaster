#!/bin/bash
################################################################################
# Apply Network Mode Manager Timing Fix - Non-interactive version
# This applies all fixes to fix the 127.0.1.1 issue
################################################################################

echo ""
echo "Applying network timing fix to SD card..."
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if SD card is mounted
if [ ! -d "/Volumes/rootfs" ] && [ ! -d "/Volumes/rootfs 1" ]; then
    echo "❌ SD card not found. Please mount SD card first."
    exit 1
fi

echo "SD card found. Applying fixes..."
echo ""
echo "NOTE: This requires sudo. You will be prompted for your password."
echo ""

# Run the timing fix script
sudo bash FIX_NETWORK_MODE_MANAGER_TIMING.sh

echo ""
echo "✅ Fix applied! Now verify:"
echo "   bash CHECK_TIMING_FIX_STATUS.sh"
echo ""



