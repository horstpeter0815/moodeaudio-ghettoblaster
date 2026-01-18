#!/bin/bash
################################################################################
# Comprehensive SD Card Configuration Verification
# 
# Compares SD card config against known working configurations
# For Raspberry Pi 5 + moOde Audio
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

BOOTFS="${1:-/Volumes/bootfs}"

if [ ! -d "$BOOTFS" ]; then
    echo "❌ ERROR: Boot partition not found at $BOOTFS"
    echo "   Please insert SD card or specify path: $0 /path/to/bootfs"
    exit 1
fi

CONFIG_TXT="$BOOTFS/cmdline.txt"
CONFIG_TXT_FILE="$BOOTFS/config.txt"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔍 COMPREHENSIVE SD CARD CONFIG VERIFICATION                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Boot partition: $BOOTFS"
echo ""

ERRORS=0
WARNINGS=0

# ============================================================================
# CRITICAL CHECKS - Must be correct for Pi 5 to boot
# ============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "CRITICAL CHECKS (Pi 5 Boot Requirements)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check 1: Pi 5 overlay MUST be present
echo "1. Pi 5 Overlay (REQUIRED):"
if grep -v "^#" "$CONFIG_TXT_FILE" | grep -q "dtoverlay=vc4-kms-v3d-pi5"; then
    echo "   ✅ Pi 5 overlay found"
    grep -v "^#" "$CONFIG_TXT_FILE" | grep "dtoverlay=vc4-kms-v3d-pi5" | head -1 | sed 's/^/      /'
else
    echo "   ❌ CRITICAL: Pi 5 overlay NOT found!"
    echo "      Pi 5 REQUIRES: dtoverlay=vc4-kms-v3d-pi5,noaudio"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check 2: Pi 4 overlay MUST NOT be present (conflicts with Pi 5)
echo "2. Pi 4 Overlay Check (MUST BE ABSENT):"
if grep -v "^#" "$CONFIG_TXT_FILE" | grep -q "dtoverlay=vc4-kms-v3d[^-]"; then
    echo "   ❌ CRITICAL: Pi 4 overlay found (conflicts with Pi 5!)"
    grep -v "^#" "$CONFIG_TXT_FILE" | grep "dtoverlay=vc4-kms-v3d[^-]" | sed 's/^/      /'
    echo "      This will prevent Pi 5 from booting!"
    ERRORS=$((ERRORS + 1))
else
    echo "   ✅ No Pi 4 overlay (correct)"
fi
echo ""

# Check 3: [pi5] section
echo "3. [pi5] Section:"
if grep -q "^\[pi5\]" "$CONFIG_TXT_FILE"; then
    echo "   ✅ [pi5] section found"
    echo "   Content:"
    awk '/^\[pi5\]/,/^\[/' "$CONFIG_TXT_FILE" | grep -v "^\[" | head -5 | sed 's/^/      /'
else
    echo "   ⚠️  No [pi5] section (may be OK if using [all])"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# ============================================================================
# DISPLAY CONFIGURATION CHECKS
# ============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "DISPLAY CONFIGURATION (Waveshare 7.9\" HDMI)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check cmdline.txt video parameter
echo "4. cmdline.txt Video Parameter:"
if grep -q "video=HDMI-A-1:400x1280M@60,rotate=90" "$CONFIG_TXT"; then
    echo "   ✅ Correct video parameter found"
    grep "video=HDMI-A-1:400x1280M@60,rotate=90" "$CONFIG_TXT" | sed 's/^/      /'
else
    echo "   ⚠️  Video parameter not found or different"
    grep "video=" "$CONFIG_TXT" | head -1 | sed 's/^/      Current: /' || echo "      (none found)"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# Check HDMI settings in config.txt
echo "5. HDMI Settings in config.txt:"
HDMI_GROUP=$(grep -v "^#" "$CONFIG_TXT_FILE" | grep "hdmi_group" | head -1)
HDMI_MODE=$(grep -v "^#" "$CONFIG_TXT_FILE" | grep "hdmi_mode" | head -1)
HDMI_CVT=$(grep -v "^#" "$CONFIG_TXT_FILE" | grep "hdmi_cvt" | head -1)

if [ -n "$HDMI_CVT" ]; then
    echo "   ✅ HDMI settings found"
    [ -n "$HDMI_GROUP" ] && echo "$HDMI_GROUP" | sed 's/^/      /'
    [ -n "$HDMI_MODE" ] && echo "$HDMI_MODE" | sed 's/^/      /'
    echo "$HDMI_CVT" | sed 's/^/      /'
else
    echo "   ⚠️  No hdmi_cvt found (may be OK if using video= parameter in cmdline.txt)"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# ============================================================================
# AUDIO CONFIGURATION
# ============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "AUDIO CONFIGURATION (HiFiBerry AMP100)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "6. HiFiBerry AMP100 Overlay:"
if grep -v "^#" "$CONFIG_TXT_FILE" | grep -q "hifiberry-amp100"; then
    echo "   ✅ HiFiBerry overlay found"
    grep -v "^#" "$CONFIG_TXT_FILE" | grep "hifiberry-amp100" | head -1 | sed 's/^/      /'
else
    echo "   ⚠️  HiFiBerry overlay not found"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# ============================================================================
# COMPARISON WITH KNOWN WORKING CONFIGS
# ============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "COMPARISON WITH TEMPLATE CONFIGURATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

TEMPLATE="$PROJECT_ROOT/custom-components/configs/config.txt.template"
if [ -f "$TEMPLATE" ]; then
    echo "7. Comparing with template: $TEMPLATE"
    echo ""
    
    # Check key settings match
    TEMPLATE_PI5=$(grep -v "^#" "$TEMPLATE" | grep "dtoverlay=vc4-kms-v3d-pi5")
    SD_PI5=$(grep -v "^#" "$CONFIG_TXT_FILE" | grep "dtoverlay=vc4-kms-v3d-pi5")
    
    if [ -n "$TEMPLATE_PI5" ] && [ -n "$SD_PI5" ]; then
        echo "   ✅ Both have Pi 5 overlay"
    else
        echo "   ⚠️  Mismatch in Pi 5 overlay"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "   ⚠️  Template not found for comparison"
fi
echo ""

# ============================================================================
# SUMMARY
# ============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "VERIFICATION SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "✅ ALL CHECKS PASSED - Configuration looks good!"
    echo ""
    echo "The SD card should boot on Pi 5."
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo "⚠️  Configuration has $WARNINGS warning(s) but should boot"
    echo ""
    echo "The SD card should boot, but some optional settings may be missing."
    exit 0
else
    echo "❌ Configuration has $ERRORS CRITICAL ERROR(S)"
    echo ""
    echo "The SD card will NOT boot properly with these errors!"
    echo ""
    echo "Fix the errors above before booting the Pi."
    exit 1
fi
