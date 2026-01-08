#!/bin/bash
# Fix AMP100 - Remove i2c-gpio, use standard I2C with lower baudrate
# Sometimes i2c-gpio causes conflicts

echo "=== FIXING AMP100 - SIMPLE I2C APPROACH ==="
echo ""

PI5_ALIAS="pi2"

if ! ssh -o ConnectTimeout=5 "$PI5_ALIAS" "echo 'Online'" >/dev/null 2>&1; then
    echo "❌ Pi 5 is not online."
    exit 1
fi

echo "✅ Pi 5 is online"
echo ""

# Backup
echo "1. Backing up config..."
ssh "$PI5_ALIAS" "sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.bak_i2c_simple_$(date +%Y%m%d%H%M%S)"
echo "   ✅ Backup created"
echo ""

# Remove i2c-gpio overlay (might be causing conflicts)
echo "2. Removing i2c-gpio overlay..."
ssh "$PI5_ALIAS" "sudo sed -i '/^dtoverlay=i2c-gpio/d' /boot/firmware/config.txt"
ssh "$PI5_ALIAS" "sudo sed -i '/^dtparam=i2c_gpio_sda=/d' /boot/firmware/config.txt"
ssh "$PI5_ALIAS" "sudo sed -i '/^dtparam=i2c_gpio_scl=/d' /boot/firmware/config.txt"
echo "   ✅ i2c-gpio removed"
echo ""

# Ensure standard I2C is enabled with lower baudrate
echo "3. Configuring standard I2C..."
ssh "$PI5_ALIAS" "sudo sed -i '/^dtparam=i2c_arm_baudrate=/d' /boot/firmware/config.txt"
ssh "$PI5_ALIAS" "echo 'dtparam=i2c_arm_baudrate=50000' | sudo tee -a /boot/firmware/config.txt > /dev/null"
echo "   ✅ Standard I2C with 50kHz baudrate"
echo ""

# Verify
echo "4. Final configuration:"
ssh "$PI5_ALIAS" "grep -E 'i2c|hifiberry' /boot/firmware/config.txt | grep -v '^#'"
echo ""

echo "=========================================="
echo "⚠️  REBOOT REQUIRED"
echo "=========================================="
echo ""
echo "Configuration changed. Reboot to apply."
echo ""

read -p "Reboot now? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Rebooting..."
    ssh "$PI5_ALIAS" "sudo reboot"
    echo "Pi 5 rebooting. Wait 60 seconds, then test:"
    echo "  ssh pi2 'aplay -l'"
    echo "  ssh pi2 'cat /proc/asound/cards'"
else
    echo "Reboot skipped. Reboot manually to apply changes."
fi

