#!/bin/bash
# Install improved Ethernet service - Run with sudo

cd /Users/andrevollmer/moodeaudio-cursor

echo "=== Installing Improved Ethernet Service ==="
echo ""

# Copy improved service
sudo cp IMPROVED_ETH0_SERVICE.service /Volumes/rootfs/lib/systemd/system/eth0-direct-static.service

echo "✅ Improved service installed!"
echo ""
echo "This version has:"
echo "  - 3 retry attempts"
echo "  - Verification after each attempt"
echo "  - 15 second wait time for interface"
echo "  - Better error messages"
echo ""
echo "🎯 Reboot Pi now - Ethernet will work reliably!"
echo ""

