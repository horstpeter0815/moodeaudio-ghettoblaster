#!/bin/bash
# Complete Boot Screen Landscape Fix
# Sets both display_rotate and fbcon=rotate

echo "=== COMPLETE BOOT SCREEN FIX ==="
echo ""

PI5_ALIAS="pi2"

if ! ssh -o ConnectTimeout=5 "$PI5_ALIAS" "echo 'Online'" >/dev/null 2>&1; then
    echo "❌ Pi 5 is not online."
    exit 1
fi

echo "✅ Pi 5 is online"
echo ""

# Fix config.txt
echo "1. Fixing config.txt..."
ssh "$PI5_ALIAS" "sudo sed -i '/^display_rotate=/d' /boot/firmware/config.txt"
ssh "$PI5_ALIAS" "echo 'display_rotate=3' | sudo tee -a /boot/firmware/config.txt > /dev/null"
ssh "$PI5_ALIAS" "sudo sed -i '/^hdmi_group=/d' /boot/firmware/config.txt"
ssh "$PI5_ALIAS" "echo 'hdmi_group=0' | sudo tee -a /boot/firmware/config.txt > /dev/null"
echo "   ✅ config.txt: display_rotate=3, hdmi_group=0"
echo ""

# Fix cmdline.txt - add fbcon=rotate:3
echo "2. Fixing cmdline.txt..."
ssh "$PI5_ALIAS" "sudo sed -i 's/ fbcon=rotate:[0-9]*//g' /boot/firmware/cmdline.txt"
ssh "$PI5_ALIAS" "sudo sed -i 's/$/ fbcon=rotate:3/' /boot/firmware/cmdline.txt"
echo "   ✅ cmdline.txt: fbcon=rotate:3 added"
echo ""

# Verify
echo "3. Verification:"
ssh "$PI5_ALIAS" "echo 'config.txt:' && grep -E 'display_rotate|hdmi_group' /boot/firmware/config.txt"
ssh "$PI5_ALIAS" "echo 'cmdline.txt:' && cat /boot/firmware/cmdline.txt | grep fbcon"
echo ""

# Restart service
echo "4. Restarting display-rotate-fix service..."
ssh "$PI5_ALIAS" "sudo systemctl restart display-rotate-fix.service"
echo "   ✅ Service restarted"
echo ""

echo "=========================================="
echo "✅ BOOT SCREEN FIX COMPLETE"
echo "=========================================="
echo ""
echo "Both settings applied:"
echo "  - display_rotate=3 (config.txt)"
echo "  - fbcon=rotate:3 (cmdline.txt)"
echo ""
echo "Reboot to see landscape boot screen."
echo ""

