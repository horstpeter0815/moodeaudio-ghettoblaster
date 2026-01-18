#!/bin/bash
# PI 5 TRY display_rotate=1
# Test 90° rotation instead of 270°

set -e

echo "=========================================="
echo "PI 5 TRY display_rotate=1 (90° ROTATION)"
echo "=========================================="
echo ""

ssh pi2 << 'ROTATION1'
export DISPLAY=:0

# Find config.txt
if [ -f "/boot/firmware/config.txt" ]; then
    CONFIG_FILE="/boot/firmware/config.txt"
else
    CONFIG_FILE="/boot/config.txt"
fi

echo "=== SETTING display_rotate=1 ==="
# Remove old rotation
sudo sed -i '/^display_rotate=/d' "$CONFIG_FILE"
sudo sed -i '/display_rotate=/d' "$CONFIG_FILE"

# Set to 1 (90° rotation)
echo "display_rotate=1" | sudo tee -a "$CONFIG_FILE" > /dev/null
echo "hdmi_group=0" | sudo tee -a "$CONFIG_FILE" > /dev/null

echo "✅ Config updated:"
sudo grep -E "display_rotate|hdmi_group" "$CONFIG_FILE" | grep -v "^#"

echo ""
echo "=== REBOOTING ==="
sudo reboot
ROTATION1

echo ""
echo "Pi 5 rebooting with display_rotate=1 (90° rotation)"
echo "This should rotate Portrait to Landscape!"


