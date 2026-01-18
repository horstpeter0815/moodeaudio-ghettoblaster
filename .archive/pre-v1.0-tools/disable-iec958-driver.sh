#!/bin/bash
# Disable IEC958 in HiFiBerry driver (config.txt dtoverlay parameter)
# Run: sudo bash disable-iec958-driver.sh

echo "=== DISABLING IEC958 IN HIFIBERRY DRIVER ==="

CONFIG_FILE="/boot/firmware/config.txt"

# Check current dtoverlay line
echo "Current HiFiBerry overlay:"
grep "dtoverlay.*hifiberry" "$CONFIG_FILE" || echo "Not found"

echo ""
echo "Disabling IEC958 in driver..."

# Remove old HiFiBerry overlays
sed -i '/dtoverlay=hifiberry-amp100/d' "$CONFIG_FILE"
sed -i '/dtoverlay=hifiberry/d' "$CONFIG_FILE"

# Add new overlay WITH disable_iec958 parameter
# Find [all] section or add at end
if grep -q "^\[all\]" "$CONFIG_FILE"; then
    # Add after [all] section
    sed -i '/^\[all\]/a dtoverlay=hifiberry-amp100,disable_iec958' "$CONFIG_FILE"
else
    # Add at end
    echo "" >> "$CONFIG_FILE"
    echo "dtoverlay=hifiberry-amp100,disable_iec958" >> "$CONFIG_FILE"
fi

echo "✅ Added: dtoverlay=hifiberry-amp100,disable_iec958"

echo ""
echo "New HiFiBerry overlay:"
grep "dtoverlay.*hifiberry" "$CONFIG_FILE"

echo ""
echo "=== REBOOT REQUIRED ==="
echo "Run: sudo reboot"
echo ""
echo "After reboot, IEC958 device will NOT be created"
echo "Only the I2S HiFiBerry device will exist"
