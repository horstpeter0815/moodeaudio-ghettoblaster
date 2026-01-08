#!/bin/bash
# Fix AMP100 I2C using GPIO (like HiFiBerry test script)
# AMP100 needs i2c-gpio overlay for proper I2C communication

echo "=== FIXING AMP100 I2C GPIO ==="
echo ""

PI5_ALIAS="pi2"

# Check if Pi 5 is online
if ! ssh -o ConnectTimeout=5 "$PI5_ALIAS" "echo 'Online'" >/dev/null 2>&1; then
    echo "❌ Pi 5 is not online."
    exit 1
fi

echo "✅ Pi 5 is online"
echo ""

# Backup
ssh "$PI5_ALIAS" "sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup-$(date +%Y%m%d_%H%M%S)"

# Add i2c-gpio overlay (like HiFiBerry test script for AMP100)
echo "1. Adding i2c-gpio overlay for AMP100..."
ssh "$PI5_ALIAS" "sudo sed -i '/^dtoverlay=i2c-gpio/d' /boot/firmware/config.txt"
ssh "$PI5_ALIAS" "sudo sed -i '/^dtparam=i2c_gpio_sda=/d' /boot/firmware/config.txt"
ssh "$PI5_ALIAS" "sudo sed -i '/^dtparam=i2c_gpio_scl=/d' /boot/firmware/config.txt"

# Add i2c-gpio configuration (from HiFiBerry AMP100 test script)
ssh "$PI5_ALIAS" "echo 'dtoverlay=i2c-gpio' | sudo tee -a /boot/firmware/config.txt > /dev/null"
ssh "$PI5_ALIAS" "echo 'dtparam=i2c_gpio_sda=0' | sudo tee -a /boot/firmware/config.txt > /dev/null"
ssh "$PI5_ALIAS" "echo 'dtparam=i2c_gpio_scl=1' | sudo tee -a /boot/firmware/config.txt > /dev/null"

echo "   ✅ i2c-gpio overlay added"
echo ""

# Verify configuration
echo "2. Configuration:"
ssh "$PI5_ALIAS" "grep -E 'i2c-gpio|i2c_gpio|hifiberry-amp100' /boot/firmware/config.txt" | tee -a "amp100-i2c-gpio-fix.log"
echo ""

# Reboot
echo "=========================================="
echo "⚠️  REBOOT REQUIRED"
echo "=========================================="
echo ""
echo "Rebooting to apply i2c-gpio configuration..."
ssh "$PI5_ALIAS" "sudo reboot"
echo ""
echo "Pi 5 rebooting. Wait 60 seconds, then test:"
echo "  ssh pi2 'aplay -l'"
echo "  ssh pi2 'cat /proc/asound/cards'"
echo ""

