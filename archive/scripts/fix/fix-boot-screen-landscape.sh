#!/bin/bash
# Fix Boot Screen Landscape - Comprehensive Fix
# Ensures boot screen is always in landscape mode

echo "=== FIXING BOOT SCREEN LANDSCAPE ==="
echo ""

PI5_ALIAS="pi2"

# Check if Pi 5 is online
if ! ssh -o ConnectTimeout=5 "$PI5_ALIAS" "echo 'Online'" >/dev/null 2>&1; then
    echo "❌ Pi 5 is not online."
    exit 1
fi

echo "✅ Pi 5 is online"
echo ""

# Step 1: Fix config.txt
echo "1. Fixing /boot/firmware/config.txt..."
ssh "$PI5_ALIAS" "sudo sed -i '/^display_rotate=/d' /boot/firmware/config.txt"
ssh "$PI5_ALIAS" "sudo sed -i '/^hdmi_group=/d' /boot/firmware/config.txt"
ssh "$PI5_ALIAS" "echo 'display_rotate=3' | sudo tee -a /boot/firmware/config.txt > /dev/null"
ssh "$PI5_ALIAS" "echo 'hdmi_group=0' | sudo tee -a /boot/firmware/config.txt > /dev/null"
echo "   ✅ config.txt updated"
echo ""

# Step 2: Fix cmdline.txt for boot prompts
echo "2. Fixing /boot/firmware/cmdline.txt..."
ssh "$PI5_ALIAS" "sudo sed -i 's/ quiet//g' /boot/firmware/cmdline.txt"
ssh "$PI5_ALIAS" "grep -q 'systemd.show_status=yes' /boot/firmware/cmdline.txt || sudo sed -i 's/rootwait/rootwait systemd.show_status=yes/' /boot/firmware/cmdline.txt"
echo "   ✅ cmdline.txt updated"
echo ""

# Step 3: Ensure display-rotate-fix service is working
echo "3. Ensuring display-rotate-fix service..."
ssh "$PI5_ALIAS" "sudo systemctl enable display-rotate-fix.service"
ssh "$PI5_ALIAS" "sudo systemctl restart display-rotate-fix.service"
echo "   ✅ Service enabled and restarted"
echo ""

# Step 4: Verify
echo "4. Verification:"
ssh "$PI5_ALIAS" "echo 'config.txt:' && grep -E 'display_rotate|hdmi_group' /boot/firmware/config.txt"
ssh "$PI5_ALIAS" "echo 'cmdline.txt:' && cat /boot/firmware/cmdline.txt | grep -E 'systemd.show_status'"
echo ""

# Step 5: Reboot
echo "=========================================="
echo "⚠️  REBOOTING TO APPLY BOOT SCREEN FIX"
echo "=========================================="
echo ""
ssh "$PI5_ALIAS" "sudo reboot"
echo ""
echo "Pi 5 rebooting. Boot screen should now be landscape."
echo ""

