#!/bin/bash
################################################################################
# Apply Simple Network Fix NOW
################################################################################

echo ""
echo "Applying SIMPLE network fix to SD card..."
echo ""
echo "This will:"
echo "  1. Disable NetworkManager (stops conflicts)"
echo "  2. Disable systemd-networkd (stops conflicts)"
echo "  3. Create ONE simple service that just works"
echo "  4. Set IP 192.168.10.2 directly"
echo ""

cd "$(dirname "$0")"

if [ ! -f "SIMPLE_NETWORK_FIX.sh" ]; then
    echo "❌ SIMPLE_NETWORK_FIX.sh not found!"
    exit 1
fi

echo "Running fix script (requires sudo password)..."
echo ""
sudo bash SIMPLE_NETWORK_FIX.sh

echo ""
echo "✅ Fix applied!"
echo ""
echo "Now:"
echo "  1. Eject SD card"
echo "  2. Boot Pi"
echo "  3. Wait 60 seconds"
echo "  4. Should get IP 192.168.10.2"
echo ""



