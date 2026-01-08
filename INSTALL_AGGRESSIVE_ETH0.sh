#!/bin/bash
# Install aggressive Ethernet-only service

cd /Users/andrevollmer/moodeaudio-cursor

echo "=== Installing Aggressive Ethernet-Only Service ==="
echo "This will:"
echo "  - Disable WiFi"
echo "  - Force Ethernet only"
echo "  - 5 retry attempts"
echo "  - Continuous watchdog"
echo ""

sudo cp AGGRESSIVE_ETH0_ONLY.service /Volumes/rootfs/lib/systemd/system/eth0-direct-static.service

echo "✅ Aggressive service installed!"
echo ""
echo "🎯 Reboot Pi - Ethernet will be forced!"

