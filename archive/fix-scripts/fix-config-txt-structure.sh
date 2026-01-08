#!/bin/bash
################################################################################
# FIX CONFIG.TXT STRUCTURE - CORRECT ORDER AND REMOVE CONFLICTS
# 
# Fixes:
# 1. Removes duplicate/conflicting settings (hdmi_group=2 AND hdmi_group=0)
# 2. Moves [pi5] section to correct position (under # Device filters)
# 3. Ensures all 5 headers are in correct order
# 4. Removes conflicting display settings
#
# Usage: ./fix-config-txt-structure.sh [SD_MOUNT_POINT]
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[FIX]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

SD_MOUNT="${1:-}"

if [ -z "$SD_MOUNT" ]; then
    if [ -d "/Volumes/bootfs" ]; then
        SD_MOUNT="/Volumes/bootfs"
    elif [ -d "/Volumes/boot" ]; then
        SD_MOUNT="/Volumes/boot"
    else
        error "SD-Karte nicht gefunden"
        exit 1
    fi
fi

CONFIG_FILE="$SD_MOUNT/config.txt"

if [ ! -f "$CONFIG_FILE" ]; then
    error "config.txt nicht gefunden: $CONFIG_FILE"
    exit 1
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 FIX CONFIG.TXT STRUCTURE                                  ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Backup
cp "$CONFIG_FILE" "${CONFIG_FILE}.backup_$(date +%Y%m%d_%H%M%S)"
log "✅ Backup erstellt"

# Create properly structured config.txt
cat > "${CONFIG_FILE}.new" << 'CONFIG_EOF'
# This file is managed by moOde

# Device filters
[cm4]
otg_mode=1

[pi4]
hdmi_force_hotplug:0=1
hdmi_force_hotplug:1=1
hdmi_enable_4kp60=0

[pi5]
display_rotate=0
dtoverlay=vc4-kms-v3d-pi5,noaudio
hdmi_enable_4kp60=0
hdmi_timings=400 0 220 32 110 1280 0 10 10 10 0 0 0 60 0 59510000 0
hdmi_ignore_edid=0xa5000080
hdmi_force_hotplug=1

# General settings
[all]
hdmi_group=2
hdmi_mode=87
hdmi_drive=2
hdmi_blanking=0
dtoverlay=vc4-kms-v3d
max_framebuffers=2
display_auto_detect=1
arm_64bit=1
arm_boost=1
disable_splash=0
disable_overscan=1
dtparam=i2c_arm=on
dtparam=i2c_arm_baudrate=100000
dtparam=i2c_vc=on
dtparam=i2s=on
dtparam=audio=off

# Do not alter this section
# Integrated adapters
#dtoverlay=disable-bt
#dtoverlay=disable-wifi
# PCI Express
#dtparam=pciex1
#dtparam=pciex1_gen=3
# Pi Touch1
#dtoverlay=vc4-kms-dsi-7inch,invx,invy
# Fan speed
#dtparam=fan_temp0=50000,fan_temp0_hyst=5000,fan_temp0_speed=75

# Audio overlays
dtoverlay=hifiberry-amp100
force_eeprom_read=0
CONFIG_EOF

# Replace config
mv "${CONFIG_FILE}.new" "$CONFIG_FILE"

log "✅ config.txt Struktur korrigiert"
echo ""

# Verify
info "Verifikation:"
echo "  Header 1: $(grep -q '^# This file is managed by moOde$' "$CONFIG_FILE" && echo '✅' || echo '❌')"
echo "  Header 2: $(grep -q '^# Device filters$' "$CONFIG_FILE" && echo '✅' || echo '❌')"
echo "  Header 3: $(grep -q '^# General settings$' "$CONFIG_FILE" && echo '✅' || echo '❌')"
echo "  Header 4: $(grep -q '^# Do not alter this section$' "$CONFIG_FILE" && echo '✅' || echo '❌')"
echo "  Header 5: $(grep -q '^# Audio overlays$' "$CONFIG_FILE" && echo '✅' || echo '❌')"
echo ""
echo "  [pi5] Section: $(grep -q '^\[pi5\]' "$CONFIG_FILE" && echo '✅' || echo '❌')"
echo "  display_rotate=0: $(grep -q '^display_rotate=0$' "$CONFIG_FILE" && echo '✅' || echo '❌')"
echo "  hdmi_group Konflikt: $(grep -c '^hdmi_group=' "$CONFIG_FILE" | xargs -I {} [ {} -eq 1 ] && echo '✅ (nur 1)' || echo '❌ (mehrere)')"
echo ""

sync
log "✅ Sync abgeschlossen"
echo ""
log "=== FIX ABGESCHLOSSEN ==="
echo ""
info "Änderungen:"
echo "  ✅ Alle 5 Header in korrekter Reihenfolge"
echo "  ✅ [pi5] Section unter # Device filters"
echo "  ✅ display_rotate=0 in [pi5] Section"
echo "  ✅ hdmi_group Konflikt entfernt (nur hdmi_group=2 in [all])"
echo "  ✅ Alle Einstellungen korrekt strukturiert"
echo ""

