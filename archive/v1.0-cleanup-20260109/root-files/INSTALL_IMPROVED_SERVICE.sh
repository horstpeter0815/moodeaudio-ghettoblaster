#!/bin/bash
# Install improved Ethernet service with retries

cd /Users/andrevollmer/moodeaudio-cursor

sudo cp IMPROVED_ETH0_SERVICE.service /Volumes/rootfs/lib/systemd/system/eth0-direct-static.service

echo "✅ Improved Ethernet service installed"
echo "This version has retries and verification"
echo ""
echo "Reboot Pi - Ethernet will work reliably!"

