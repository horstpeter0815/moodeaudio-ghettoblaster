#!/bin/bash
# Fix Audio Hardware Detection
# Ensures audio hardware is properly detected and configured

echo "=== FIXING AUDIO HARDWARE ==="
echo ""

# Check current status
echo "1. Checking current audio status..."
aplay -l 2>&1
echo ""

# Check ALSA modules
echo "2. Checking ALSA modules..."
lsmod | grep snd
echo ""

# Check device tree overlays
echo "3. Checking device tree overlays..."
grep -i 'dtoverlay\|dtparam' /boot/firmware/config.txt | grep -i audio
echo ""

# Check if HiFiBerry DAC is connected
echo "4. Checking for HiFiBerry DAC..."
dmesg | grep -i 'hifiberry\|pcm512x' | tail -5
echo ""

# Check HDMI audio
echo "5. Checking HDMI audio..."
dmesg | grep -i 'hdmi.*audio' | tail -5
echo ""

# Check ALSA devices
echo "6. Checking ALSA devices..."
ls -la /dev/snd/
cat /proc/asound/cards
echo ""

# Determine fix needed
echo "7. Determining fix..."
if [ -f "/boot/firmware/config.txt" ]; then
    if grep -q "dtoverlay=hifiberry-dacplus" /boot/firmware/config.txt; then
        echo "   HiFiBerry DAC overlay found"
    elif grep -q "dtoverlay=vc4-kms-v3d" /boot/firmware/config.txt; then
        echo "   VC4 KMS overlay found (HDMI audio should work)"
    else
        echo "   ⚠️  No audio overlay found - may need to add one"
    fi
fi

echo ""
echo "=== DIAGNOSIS COMPLETE ==="
echo "Review the output above to determine the fix needed"

