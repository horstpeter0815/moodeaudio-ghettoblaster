#!/bin/bash
################################################################################
# FIX DISPLAY ON SD CARD (180° ROTATION)
# 
# Fixes display settings directly on SD card when mounted on Mac:
# 1. Ensures all 5 Moode headers are present (prevents worker.php overwrite)
# 2. Sets display_rotate=2 (180° rotation)
# 3. Sets fbcon=rotate:3 in cmdline.txt (180° console rotation)
# 4. Ensures [pi5] section is correctly placed
#
# Usage: ./fix-display-on-sd-card.sh [SD_MOUNT_POINT]
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

# Find SD card mount point
if [ -z "$SD_MOUNT" ]; then
    if [ -d "/Volumes/bootfs" ]; then
        SD_MOUNT="/Volumes/bootfs"
    elif [ -d "/Volumes/boot" ]; then
        SD_MOUNT="/Volumes/boot"
    else
        error "SD-Karte nicht gefunden. Bitte Mount-Point angeben: $0 [SD_MOUNT_POINT]"
        exit 1
    fi
fi

CONFIG_FILE="$SD_MOUNT/config.txt"
CMDLINE_FILE="$SD_MOUNT/cmdline.txt"

if [ ! -f "$CONFIG_FILE" ]; then
    error "config.txt nicht gefunden: $CONFIG_FILE"
    exit 1
fi

if [ ! -f "$CMDLINE_FILE" ]; then
    error "cmdline.txt nicht gefunden: $CMDLINE_FILE"
    exit 1
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 FIX DISPLAY ON SD CARD (180° ROTATION)                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
info "SD-Karte: $SD_MOUNT"
echo ""

################################################################################
# STEP 1: CHECK CURRENT STATE
################################################################################

log "=== STEP 1: CHECK CURRENT STATE ==="
echo ""

echo "=== config.txt ==="
echo "display_rotate:"
grep -E '^display_rotate=' "$CONFIG_FILE" || echo "  Nicht gefunden"
echo ""
echo "Moode Headers:"
head -30 "$CONFIG_FILE" | grep -E 'managed by moOde|Device filters|General settings|Do not alter|Audio overlays' || echo "  Headers fehlen!"
echo ""
echo "[pi5] Section:"
grep -A 5 '^\[pi5\]' "$CONFIG_FILE" | head -10 || echo "  [pi5] Section nicht gefunden"
echo ""
echo "=== cmdline.txt ==="
echo "fbcon:"
grep -E 'fbcon|video' "$CMDLINE_FILE" || echo "  Kein fbcon/video gefunden"
echo ""

################################################################################
# STEP 2: FIX CONFIG.TXT
################################################################################

log "=== STEP 2: FIX CONFIG.TXT ==="
echo ""

# Backup
cp "$CONFIG_FILE" "${CONFIG_FILE}.backup_$(date +%Y%m%d_%H%M%S)"
log "✅ Backup erstellt"

# Read current config
CURRENT_CONFIG=$(cat "$CONFIG_FILE")

# Check if all 5 headers are present
HAS_MAIN_HEADER=$(echo "$CURRENT_CONFIG" | grep -q "^# This file is managed by moOde" && echo "yes" || echo "no")
HAS_DEVICE_FILTERS=$(echo "$CURRENT_CONFIG" | grep -q "^# Device filters" && echo "yes" || echo "no")
HAS_GENERAL_SETTINGS=$(echo "$CURRENT_CONFIG" | grep -q "^# General settings" && echo "yes" || echo "no")
HAS_DO_NOT_ALTER=$(echo "$CURRENT_CONFIG" | grep -q "^# Do not alter this section" && echo "yes" || echo "no")
HAS_AUDIO_OVERLAYS=$(echo "$CURRENT_CONFIG" | grep -q "^# Audio overlays" && echo "yes" || echo "no")

info "Header Status:"
echo "  Main header: $HAS_MAIN_HEADER"
echo "  Device filters: $HAS_DEVICE_FILTERS"
echo "  General settings: $HAS_GENERAL_SETTINGS"
echo "  Do not alter: $HAS_DO_NOT_ALTER"
echo "  Audio overlays: $HAS_AUDIO_OVERLAYS"
echo ""

# If headers are missing, create complete structure
if [ "$HAS_MAIN_HEADER" = "no" ] || [ "$HAS_DEVICE_FILTERS" = "no" ] || [ "$HAS_GENERAL_SETTINGS" = "no" ] || [ "$HAS_DO_NOT_ALTER" = "no" ] || [ "$HAS_AUDIO_OVERLAYS" = "no" ]; then
    warn "Headers fehlen - erstelle vollständige config.txt Struktur..."
    
    # Create properly structured config.txt with all headers
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
display_rotate=2
dtoverlay=vc4-kms-v3d-pi5,noaudio
hdmi_enable_4kp60=0
hdmi_timings=400 0 220 32 110 1280 0 10 10 10 0 0 0 60 0 59510000 0
hdmi_ignore_edid=0xa5000080
hdmi_force_hotplug=1
disable_splash=1

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
    
    mv "${CONFIG_FILE}.new" "$CONFIG_FILE"
    log "✅ config.txt mit allen Headers neu erstellt"
else
    log "✅ Alle Headers vorhanden"
    
    # Fix display_rotate=2 in [pi5] section
    if grep -q "^\[pi5\]" "$CONFIG_FILE"; then
        # Remove existing display_rotate from [pi5] section (macOS-compatible)
        awk '
            /^\[pi5\]/ { in_pi5=1; print; next }
            /^\[/ && in_pi5 { in_pi5=0 }
            in_pi5 && /^display_rotate=/ { next }
            { print }
        ' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"
        mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
        
        # Add display_rotate=2 after [pi5] (macOS-compatible)
        awk '/^\[pi5\]/ {print; print "display_rotate=2"; next} {print}' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"
        mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
        
        log "✅ display_rotate=2 in [pi5] Section gesetzt"
    else
        # Add [pi5] section after # Device filters
        awk '
            /^# Device filters$/ { 
                print; 
                print ""; 
                print "[pi5]"; 
                print "display_rotate=2"; 
                print "dtoverlay=vc4-kms-v3d-pi5,noaudio"; 
                print "hdmi_enable_4kp60=0"; 
                print "hdmi_timings=400 0 220 32 110 1280 0 10 10 10 0 0 0 60 0 59510000 0"; 
                print "hdmi_ignore_edid=0xa5000080"; 
                print "hdmi_force_hotplug=1"; 
                print "disable_splash=1"; 
                next 
            }
            { print }
        ' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"
        mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
        
        log "✅ [pi5] Section mit display_rotate=2 hinzugefügt"
    fi
    
    # Ensure disable_splash=1 in [pi5] section
    if grep -q "^\[pi5\]" "$CONFIG_FILE"; then
        if ! grep -A 10 "^\[pi5\]" "$CONFIG_FILE" | grep -q "^disable_splash=1"; then
            awk '/^\[pi5\]/ {print; print "disable_splash=1"; next} {print}' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"
            mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
            log "✅ disable_splash=1 hinzugefügt"
        fi
    fi
fi

echo ""

################################################################################
# STEP 3: FIX CMDLINE.TXT
################################################################################

log "=== STEP 3: FIX CMDLINE.TXT ==="
echo ""

# Backup
cp "$CMDLINE_FILE" "${CMDLINE_FILE}.backup_$(date +%Y%m%d_%H%M%S)"
log "✅ Backup erstellt"

# Read cmdline.txt
CMDLINE_CONTENT=$(cat "$CMDLINE_FILE")

# Remove existing fbcon=rotate parameter
CMDLINE_CONTENT=$(echo "$CMDLINE_CONTENT" | sed 's/ fbcon=rotate:[0-9]//g' | sed 's/ fbcon=rotate//g')

# Remove conflicting video= rotate parameter
CMDLINE_CONTENT=$(echo "$CMDLINE_CONTENT" | sed 's/ video=[^ ]*rotate[^ ]*//g')

# Clean up double spaces
CMDLINE_CONTENT=$(echo "$CMDLINE_CONTENT" | sed 's/  / /g')

# Add fbcon=rotate:3 at the end (for 180° console rotation)
if ! echo "$CMDLINE_CONTENT" | grep -q "fbcon=rotate:3"; then
    CMDLINE_CONTENT="${CMDLINE_CONTENT} fbcon=rotate:3"
    log "✅ fbcon=rotate:3 hinzugefügt"
else
    log "✅ fbcon=rotate:3 bereits vorhanden"
fi

# Write back
echo "$CMDLINE_CONTENT" > "$CMDLINE_FILE"

echo ""

################################################################################
# STEP 4: VERIFICATION
################################################################################

log "=== STEP 4: VERIFICATION ==="
echo ""

info "Finale Einstellungen:"
echo ""
echo "1. config.txt display_rotate:"
grep -E '^display_rotate=' "$CONFIG_FILE" || echo "  ❌ Nicht gefunden"
echo ""
echo "2. config.txt Moode Headers:"
HEADER_COUNT=$(head -30 "$CONFIG_FILE" | grep -cE 'managed by moOde|Device filters|General settings|Do not alter|Audio overlays' || echo "0")
echo "  Gefundene Headers: $HEADER_COUNT/5"
if [ "$HEADER_COUNT" -eq 5 ]; then
    echo "  ✅ Alle Headers vorhanden"
else
    echo "  ⚠️  Headers fehlen!"
fi
echo ""
echo "3. config.txt [pi5] Section:"
grep -A 5 '^\[pi5\]' "$CONFIG_FILE" | head -10 || echo "  ❌ [pi5] Section nicht gefunden"
echo ""
echo "4. cmdline.txt fbcon:"
grep -E 'fbcon=rotate:3' "$CMDLINE_FILE" && echo "  ✅ fbcon=rotate:3 vorhanden" || echo "  ❌ fbcon=rotate:3 fehlt"
echo ""

################################################################################
# SUMMARY
################################################################################

log "=== FIX ABGESCHLOSSEN ==="
echo ""
info "Änderungen:"
echo "  ✅ Alle 5 Moode Headers sichergestellt (verhindert worker.php Überschreibung)"
echo "  ✅ display_rotate=2 in [pi5] Section (180° Rotation)"
echo "  ✅ fbcon=rotate:3 in cmdline.txt (180° Console-Rotation)"
echo "  ✅ disable_splash=1 (kein Splash-Screen)"
echo ""
warn "⚠️  SD-Karte kann jetzt ausgeworfen werden. Nach dem Boot sollte das Display korrekt sein!"
echo ""

