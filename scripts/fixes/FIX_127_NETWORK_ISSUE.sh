#!/bin/bash
################################################################################
#
# FIX 127.0.1.1 NETWORK ISSUE
#
# The Pi is showing 127.0.1.1 because network interfaces aren't configured.
# This applies the unified network manager fix.
#
################################################################################

set -e

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  FIXING 127.0.1.1 NETWORK ISSUE                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "The Pi showing 127.0.1.1 means network is not configured."
echo "Applying unified network manager fix..."
echo ""

# Run the unified network manager application script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ -f "scripts/network/APPLY_UNIFIED_NETWORK.sh" ]; then
    echo "Running unified network manager application..."
    sudo bash scripts/network/APPLY_UNIFIED_NETWORK.sh
else
    echo "❌ Application script not found!"
    exit 1
fi

echo ""
echo "✅ Fix applied!"
echo ""
echo "Next steps:"
echo "  1. Eject SD card"
echo "  2. Boot Pi with Ethernet cable connected to Mac"
echo "  3. Wait 30-60 seconds for boot"
echo "  4. Pi should get IP address (not 127.0.1.1)"
echo ""
echo "For Mac Internet Sharing (DHCP mode):"
echo "  - Enable Internet Sharing on Mac (Ethernet)"
echo "  - Create file on boot partition:"
echo "    echo 'ethernet-dhcp' > /Volumes/bootfs/network-mode"
echo ""



