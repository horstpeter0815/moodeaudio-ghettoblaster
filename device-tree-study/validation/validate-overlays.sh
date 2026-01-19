#!/bin/bash
# Device Tree Overlay Validation Tests
# Purpose: Validate device tree overlays are loaded and working correctly
# Usage: ./validate-overlays.sh

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASS=0
FAIL=0
WARN=0

# Function to print test result
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
    print_result "PASS" "Onboard audio disabled in config.txt"
else
    print_result "WARN" "Onboard audio not explicitly disabled (may conflict)"
fi

# Test 4: Check display overlay loaded
echo "Test 4: Display Overlay (vc4-kms-v3d-pi5)"
if vcgencmd get_config dtoverlay | grep -q "vc4-kms-v3d-pi5"; then
    print_result "PASS" "Display overlay loaded (vc4-kms-v3d-pi5)"
else
    print_result "FAIL" "Display overlay not loaded or wrong version"
fi

# Test 5: Check audio overlay loaded
echo "Test 5: Audio Overlay (hifiberry)"
if vcgencmd get_config dtoverlay | grep -q "hifiberry"; then
    OVERLAY=$(vcgencmd get_config dtoverlay | grep hifiberry)
    print_result "PASS" "Audio overlay loaded: $OVERLAY"
else
    print_result "FAIL" "HiFiBerry audio overlay not loaded"
fi

# Test 6: Check I2C devices detected
echo "Test 6: I2C Device Detection"
if command -v i2cdetect &> /dev/null; then
    # Check for PCM5122 at 0x4d
    if i2cdetect -y 1 | grep -q "4d"; then
        print_result "PASS" "PCM5122 DAC detected at I2C address 0x4d"
    else
        print_result "FAIL" "PCM5122 DAC not detected at I2C address 0x4d"
    fi
    
    # Check for FT6236 at 0x38
    if i2cdetect -y 1 | grep -q "38"; then
        print_result "PASS" "FT6236 touch controller detected at I2C address 0x38"
    else
        print_result "WARN" "FT6236 touch controller not detected at I2C address 0x38"
    fi
else
    print_result "WARN" "i2cdetect not available, cannot check I2C devices"
fi

# Test 7: Check sound card created
echo "Test 7: ALSA Sound Card"
if cat /proc/asound/cards | grep -q "sndrpihifiberry"; then
    print_result "PASS" "HiFiBerry sound card created (sndrpihifiberry)"
else
    print_result "FAIL" "HiFiBerry sound card not found"
fi

# Test 8: Check ALSA device
echo "Test 8: ALSA Playback Device"
if aplay -l | grep -q "HiFiBerry"; then
    print_result "PASS" "ALSA playback device available"
else
    print_result "FAIL" "ALSA playback device not available"
fi

# Test 9: Check DRM devices (display)
echo "Test 9: DRM Display Devices"
if ls /dev/dri/card* &> /dev/null; then
    CARDS=$(ls /dev/dri/card* | wc -l)
    print_result "PASS" "DRM display devices found ($CARDS card(s))"
else
    print_result "FAIL" "DRM display devices not found"
fi

# Test 10: Check framebuffer
echo "Test 10: Framebuffer Device"
if [ -e /dev/fb0 ]; then
    print_result "PASS" "Framebuffer device /dev/fb0 exists"
else
    print_result "WARN" "Framebuffer device /dev/fb0 not found (normal with KMS)"
fi

# Test 11: Check kernel messages for errors
echo "Test 11: Kernel Messages (Device Tree)"
DT_ERRORS=$(dmesg | grep -i "device tree" | grep -i "error" | wc -l)
if [ "$DT_ERRORS" -eq 0 ]; then
    print_result "PASS" "No device tree errors in kernel log"
else
    print_result "WARN" "$DT_ERRORS device tree error(s) in kernel log"
fi

# Test 12: Check kernel messages for I2C errors
echo "Test 12: Kernel Messages (I2C)"
I2C_ERRORS=$(dmesg | grep -i "i2c" | grep -i "error" | wc -l)
if [ "$I2C_ERRORS" -eq 0 ]; then
    print_result "PASS" "No I2C errors in kernel log"
else
    print_result "WARN" "$I2C_ERRORS I2C error(s) in kernel log"
fi

# Test 13: Check PCM5122 driver loaded
echo "Test 13: PCM5122 Driver"
if lsmod | grep -q "snd_soc_pcm5102a\|snd_soc_pcm512x"; then
    print_result "PASS" "PCM5122 driver loaded"
else
    print_result "FAIL" "PCM5122 driver not loaded"
fi

# Test 14: Check HiFiBerry driver loaded
echo "Test 14: HiFiBerry Driver"
if lsmod | grep -q "snd_rpi_hifiberry"; then
    print_result "PASS" "HiFiBerry driver loaded"
else
    print_result "FAIL" "HiFiBerry driver not loaded"
fi

# Test 15: Check VC4 display driver loaded
echo "Test 15: VC4 Display Driver"
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
    exit 0
else
    echo -e "${RED}✗ Some tests failed. Check configuration.${NC}"
    exit 1
fi
