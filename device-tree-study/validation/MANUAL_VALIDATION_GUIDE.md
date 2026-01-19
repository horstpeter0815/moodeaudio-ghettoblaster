# Phase 4: Hardware Validation - Manual Guide

**Pi IP:** 192.168.2.1
**Date:** 2026-01-18
**Status:** Ready to run on Pi

## SSH Connection Issue

SSH from Mac has authentication issues. Instead, run validation **directly on the Pi**.

## Step 1: Login to Pi

```bash
# From Mac, if SSH works:
ssh pi@192.168.2.1

# OR login directly on Pi console
# OR use moOde web terminal (if available)
```

## Step 2: Download Validation Script

Copy this script directly on the Pi:

```bash
# On the Pi, create the script
cat > /tmp/validate-overlays.sh << 'EOF'
#!/bin/bash
# Device Tree Overlay Validation Tests

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

print_result() {
    local status=$1
    local message=$2
    
    if [ "$status" = "PASS" ]; then
        echo -e "${GREEN}✓ PASS${NC}: $message"
        ((PASS++))
    elif [ "$status" = "FAIL" ]; then
        echo -e "${RED}✗ FAIL${NC}: $message"
        ((FAIL++))
    elif [ "$status" = "WARN" ]; then
        echo -e "${YELLOW}⚠ WARN${NC}: $message"
        ((WARN++))
    fi
}

echo "================================"
echo "Device Tree Overlay Validation"
echo "================================"
echo ""

# Test 1: Check I2C enabled
echo "Test 1: I2C Bus Enabled"
if grep -q "dtparam=i2c_arm=on" /boot/firmware/config.txt; then
    print_result "PASS" "I2C enabled in config.txt"
else
    print_result "FAIL" "I2C not enabled in config.txt"
fi

# Test 2: Check I2S enabled
echo "Test 2: I2S Interface Enabled"
if grep -q "dtparam=i2s=on" /boot/firmware/config.txt; then
    print_result "PASS" "I2S enabled in config.txt"
else
    print_result "FAIL" "I2S not enabled in config.txt"
fi

# Test 3: Check onboard audio disabled
echo "Test 3: Onboard Audio Disabled"
if grep -q "dtparam=audio=off" /boot/firmware/config.txt; then
    print_result "PASS" "Onboard audio disabled"
else
    print_result "WARN" "Onboard audio not explicitly disabled"
fi

# Test 4: Check display overlay
echo "Test 4: Display Overlay"
vcgencmd get_config dtoverlay | grep -q "vc4-kms-v3d-pi5" && \
    print_result "PASS" "Display overlay loaded (vc4-kms-v3d-pi5)" || \
    print_result "FAIL" "Display overlay not loaded"

# Test 5: Check audio overlay
echo "Test 5: Audio Overlay"
if vcgencmd get_config dtoverlay | grep -q "hifiberry"; then
    OVERLAY=$(vcgencmd get_config dtoverlay | grep hifiberry)
    print_result "PASS" "Audio overlay: $OVERLAY"
else
    print_result "FAIL" "HiFiBerry overlay not loaded"
fi

# Test 6: Check I2C devices
echo "Test 6: I2C Device Detection"
if i2cdetect -y 1 2>/dev/null | grep -q "4d"; then
    print_result "PASS" "PCM5122 DAC detected at 0x4d"
else
    print_result "FAIL" "PCM5122 not detected"
fi

if i2cdetect -y 1 2>/dev/null | grep -q "38"; then
    print_result "PASS" "FT6236 touch detected at 0x38"
else
    print_result "WARN" "FT6236 not detected"
fi

# Test 7: Check sound card
echo "Test 7: ALSA Sound Card"
if cat /proc/asound/cards | grep -q "sndrpihifiberry"; then
    print_result "PASS" "HiFiBerry sound card created"
else
    print_result "FAIL" "HiFiBerry sound card not found"
fi

# Test 8: Check ALSA device
echo "Test 8: ALSA Playback Device"
if aplay -l 2>/dev/null | grep -q "HiFiBerry"; then
    print_result "PASS" "ALSA playback device available"
else
    print_result "FAIL" "ALSA playback device not available"
fi

# Test 9: Check DRM devices
echo "Test 9: DRM Display Devices"
if ls /dev/dri/card* &> /dev/null; then
    CARDS=$(ls /dev/dri/card* | wc -l)
    print_result "PASS" "DRM devices found ($CARDS card(s))"
else
    print_result "FAIL" "DRM devices not found"
fi

# Test 10: Check PCM5122 driver
echo "Test 10: PCM5122 Driver"
if lsmod | grep -q "snd_soc_pcm"; then
    print_result "PASS" "PCM5122 driver loaded"
else
    print_result "FAIL" "PCM5122 driver not loaded"
fi

# Test 11: Check HiFiBerry driver
echo "Test 11: HiFiBerry Driver"
if lsmod | grep -q "snd_rpi_hifiberry"; then
    print_result "PASS" "HiFiBerry driver loaded"
else
    print_result "FAIL" "HiFiBerry driver not loaded"
fi

# Test 12: Check VC4 driver
echo "Test 12: VC4 Display Driver"
if lsmod | grep -q "vc4"; then
    print_result "PASS" "VC4 display driver loaded"
else
    print_result "FAIL" "VC4 display driver not loaded"
fi

echo ""
echo "================================"
echo "Summary"
echo "================================"
echo -e "${GREEN}Passed:  $PASS${NC}"
echo -e "${YELLOW}Warnings: $WARN${NC}"
echo -e "${RED}Failed:  $FAIL${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✓ All critical tests passed!${NC}"
else
    echo -e "${RED}✗ Some tests failed. Check configuration.${NC}"
fi
EOF

# Make executable
chmod +x /tmp/validate-overlays.sh
```

## Step 3: Run Validation

```bash
# Run the validation script
/tmp/validate-overlays.sh
```

## Step 4: Collect Current Configuration

```bash
# Show current overlays
echo "=== Current Overlays ==="
vcgencmd get_config dtoverlay

echo ""
echo "=== I2C Devices ==="
i2cdetect -y 1

echo ""
echo "=== Sound Cards ==="
cat /proc/asound/cards

echo ""
echo "=== ALSA Devices ==="
aplay -l

echo ""
echo "=== Loaded Drivers ==="
lsmod | grep -E "pcm|hifiberry|vc4"

echo ""
echo "=== Config.txt (relevant lines) ==="
grep -E "dtoverlay|dtparam" /boot/firmware/config.txt
```

## Step 5: Save Results

```bash
# Save all results to file
{
    echo "=== Device Tree Validation Results ==="
    echo "Date: $(date)"
    echo ""
    /tmp/validate-overlays.sh
    echo ""
    echo "=== Current Configuration ==="
    vcgencmd get_config dtoverlay
    echo ""
    i2cdetect -y 1
    echo ""
    cat /proc/asound/cards
} > /tmp/dt-validation-results.txt

# Show the file
cat /tmp/dt-validation-results.txt
```

## Alternative: Check Specific Things

If you just want to quickly check the current state:

```bash
# Quick check - all in one command
echo "Overlays:" && vcgencmd get_config dtoverlay && \
echo -e "\nI2C Devices:" && i2cdetect -y 1 && \
echo -e "\nSound Card:" && cat /proc/asound/cards && \
echo -e "\nALSA:" && aplay -l
```

## What We're Looking For

**Expected Results:**

1. ✅ I2C enabled and devices detected:
   - 0x4d = PCM5122 DAC
   - 0x38 = FT6236 touch (optional)

2. ✅ Overlays loaded:
   - vc4-kms-v3d-pi5,noaudio
   - hifiberry-dacplus or hifiberry-amp100

3. ✅ Sound card:
   - Card 0: sndrpihifiberry

4. ✅ Drivers loaded:
   - snd_soc_pcm512x
   - snd_rpi_hifiberry_dacplus
   - vc4

## Next Steps After Validation

Once validation is complete, we'll:
1. Document actual hardware configuration
2. Test specific parameters (auto_mute, 24db_digital_gain)
3. Create recommendations based on real hardware
4. Update documentation with validated results

## If You Can Share Results

If you can run these commands and share the output, I can:
- Analyze the actual configuration
- Verify if everything is correct
- Make specific recommendations
- Continue with parameter testing

Just run the commands and share the output! 🚀
