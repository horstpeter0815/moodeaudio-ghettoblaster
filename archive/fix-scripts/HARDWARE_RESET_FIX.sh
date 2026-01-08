#!/bin/bash
# Hardware Reset Fix for HiFiBerry
# Attempts hardware reset via GPIO before loading driver

echo "=== HIFIBERRY HARDWARE RESET FIX ==="
echo ""

PI5_ALIAS="pi2"

# Check if Pi 5 is online
if ! ssh -o ConnectTimeout=5 "$PI5_ALIAS" "echo 'Online'" >/dev/null 2>&1; then
    echo "❌ Pi 5 is not online."
    exit 1
fi

echo "✅ Pi 5 is online"
echo ""

# HiFiBerry AMP100 uses GPIO17 for hardware reset
# We need to reset it before the driver tries to probe

echo "1. Attempting hardware reset via GPIO17..."
ssh "$PI5_ALIAS" << 'RESET_SCRIPT'
# Export GPIO17
echo 17 > /sys/class/gpio/export 2>/dev/null || true
echo out > /sys/class/gpio/gpio17/direction
echo 0 > /sys/class/gpio/gpio17/value
sleep 0.1
echo 1 > /sys/class/gpio/gpio17/value
sleep 0.5
echo "   GPIO17 reset sequence completed"
RESET_SCRIPT

echo ""
echo "2. Checking if we need to reload modules..."
ssh "$PI5_ALIAS" << 'RELOAD_SCRIPT'
# Unload and reload HiFiBerry modules
modprobe -r snd_soc_hifiberry_dacplus 2>/dev/null || true
modprobe -r snd_soc_pcm512x 2>/dev/null || true
modprobe -r snd_soc_pcm512x_i2c 2>/dev/null || true
sleep 1
modprobe snd_soc_pcm512x_i2c
modprobe snd_soc_pcm512x
modprobe snd_soc_hifiberry_dacplus
sleep 2
echo "   Modules reloaded"
RELOAD_SCRIPT

echo ""
echo "3. Testing audio hardware..."
ssh "$PI5_ALIAS" "aplay -l 2>&1"
echo ""

echo "4. Checking dmesg for errors..."
ssh "$PI5_ALIAS" "dmesg | tail -10 | grep -i 'pcm512x\|hifiberry\|i2c'"
echo ""

echo "=========================================="
echo "If still not working, may need:"
echo "1. Hardware connection check"
echo "2. Different overlay (hifiberry-amp100 vs dacplus)"
echo "3. Hardware replacement"
echo "=========================================="

