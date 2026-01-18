#!/bin/bash
# Quick script to check audio card detection

echo "=== Checking Audio Cards ==="
echo ""

echo "1. Checking /proc/asound/cards:"
cat /proc/asound/cards 2>/dev/null || echo "  No cards found"

echo ""
echo "2. Checking aplay -l:"
aplay -l 2>&1 || echo "  aplay failed"

echo ""
echo "3. Checking dmesg for HiFiBerry:"
dmesg | grep -i "hifiberry\|amp100\|snd.*hifiberry" | tail -10

echo ""
echo "4. Checking device tree overlays:"
vcgencmd get_config dtoverlay 2>/dev/null || echo "  vcgencmd failed"

echo ""
echo "5. Checking /boot/firmware/config.txt for dtoverlay:"
grep -i "dtoverlay.*hifiberry\|dtoverlay.*amp" /boot/firmware/config.txt 2>/dev/null || echo "  No HiFiBerry overlay found"

echo ""
echo "6. Listing /proc/asound:"
ls -la /proc/asound/ 2>/dev/null || echo "  /proc/asound not found"
