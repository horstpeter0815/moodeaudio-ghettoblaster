#!/bin/bash
################################################################################
# FINAL FIX ON SD CARD - SSH + DISPLAY
# 
# Works directly on SD card - NO INTERNET NEEDED
# After boot: Pi will be reachable via LAN cable
#
# Usage: sudo ./FIX_SD_CARD_FINAL.sh
################################################################################

set -e

SD_MOUNT=""
if [ -d "/Volumes/bootfs" ]; then
    SD_MOUNT="/Volumes/bootfs"
elif [ -d "/Volumes/boot" ]; then
    SD_MOUNT="/Volumes/boot"
else
    echo "❌ SD-Karte nicht gefunden"
    echo "Bitte SD-Karte einstecken"
    exit 1
fi

CONFIG_FILE="$SD_MOUNT/config.txt"
CMDLINE_FILE="$SD_MOUNT/cmdline.txt"
SSH_FLAG="$SD_MOUNT/ssh"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 FINAL FIX ON SD CARD - SSH + DISPLAY                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "SD-Karte: $SD_MOUNT"
echo ""

# Check if we can write
if ! touch "$SD_MOUNT/.test_write" 2>/dev/null; then
    echo "❌ Keine Schreibrechte auf SD-Karte"
    echo "Bitte mit sudo ausführen: sudo ./FIX_SD_CARD_FINAL.sh"
    exit 1
fi
rm "$SD_MOUNT/.test_write" 2>/dev/null

################################################################################
# STEP 1: SSH FLAG
################################################################################

echo "=== STEP 1: CREATE SSH FLAG ==="
touch "$SSH_FLAG"
chmod 644 "$SSH_FLAG"
if [ -f "$SSH_FLAG" ]; then
    echo "✅ SSH-Flag erstellt: $SSH_FLAG"
    ls -lh "$SSH_FLAG"
else
    echo "❌ SSH-Flag konnte nicht erstellt werden"
    exit 1
fi
echo ""

################################################################################
# STEP 2: FIX CONFIG.TXT
################################################################################

echo "=== STEP 2: FIX CONFIG.TXT ==="

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ config.txt nicht gefunden"
    exit 1
fi

# Backup
cp "$CONFIG_FILE" "${CONFIG_FILE}.backup_$(date +%Y%m%d_%H%M%S)"
echo "✅ Backup erstellt"

# Read current
CURRENT=$(cat "$CONFIG_FILE")

# Check headers
HAS_MAIN=$(echo "$CURRENT" | grep -q "^# This file is managed by moOde" && echo "yes" || echo "no")
HAS_DEVICE=$(echo "$CURRENT" | grep -q "^# Device filters" && echo "yes" || echo "no")
HAS_GENERAL=$(echo "$CURRENT" | grep -q "^# General settings" && echo "yes" || echo "no")
HAS_DO_NOT=$(echo "$CURRENT" | grep -q "^# Do not alter this section" && echo "yes" || echo "no")
HAS_AUDIO=$(echo "$CURRENT" | grep -q "^# Audio overlays" && echo "yes" || echo "no")

echo "Header Status:"
echo "  Main: $HAS_MAIN"
echo "  Device filters: $HAS_DEVICE"
echo "  General: $HAS_GENERAL"
echo "  Do not alter: $HAS_DO_NOT"
echo "  Audio: $HAS_AUDIO"
echo ""

# If headers missing, create complete structure
if [ "$HAS_MAIN" = "no" ] || [ "$HAS_DEVICE" = "no" ] || [ "$HAS_GENERAL" = "no" ] || [ "$HAS_DO_NOT" = "no" ] || [ "$HAS_AUDIO" = "no" ]; then
    echo "⚠️  Headers fehlen - erstelle vollständige Struktur..."
    
    cat > "$CONFIG_FILE" << 'CONFIG_EOF'
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
    
    echo "✅ config.txt mit allen Headers neu erstellt"
else
    echo "✅ Alle Headers vorhanden"
    
    # Fix display_rotate=2 in [pi5] section
    if echo "$CURRENT" | grep -q "^\[pi5\]"; then
        # Remove existing display_rotate
        awk '
            /^\[pi5\]/ { in_pi5=1; print; next }
            /^\[/ && in_pi5 { in_pi5=0 }
            in_pi5 && /^display_rotate=/ { next }
            { print }
        ' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"
        mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
        
        # Add display_rotate=2
        awk '/^\[pi5\]/ {print; print "display_rotate=2"; next} {print}' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"
        mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
        
        echo "✅ display_rotate=2 in [pi5] Section gesetzt"
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
        
        echo "✅ [pi5] Section mit display_rotate=2 hinzugefügt"
    fi
fi
echo ""

################################################################################
# STEP 3: FIX CMDLINE.TXT
################################################################################

echo "=== STEP 3: FIX CMDLINE.TXT ==="

if [ ! -f "$CMDLINE_FILE" ]; then
    echo "❌ cmdline.txt nicht gefunden"
    exit 1
fi

# Backup
cp "$CMDLINE_FILE" "${CMDLINE_FILE}.backup_$(date +%Y%m%d_%H%M%S)"
echo "✅ Backup erstellt"

# Read and fix
CMDLINE=$(cat "$CMDLINE_FILE")
CMDLINE=$(echo "$CMDLINE" | sed 's/ fbcon=rotate:[0-9]//g')
CMDLINE=$(echo "$CMDLINE" | sed 's/  / /g')

if ! echo "$CMDLINE" | grep -q "fbcon=rotate:3"; then
    CMDLINE="${CMDLINE} fbcon=rotate:3"
fi

echo "$CMDLINE" > "$CMDLINE_FILE"
echo "✅ fbcon=rotate:3 gesetzt"
echo ""

################################################################################
# VERIFICATION
################################################################################

echo "=== VERIFICATION ==="
echo ""
[ -f "$SSH_FLAG" ] && echo "✅ SSH-Flag vorhanden" || echo "❌ SSH-Flag fehlt"
grep -q "^display_rotate=2" "$CONFIG_FILE" && echo "✅ display_rotate=2 gesetzt" || echo "❌ display_rotate=2 fehlt"
grep -q "fbcon=rotate:3" "$CMDLINE_FILE" && echo "✅ fbcon=rotate:3 gesetzt" || echo "❌ fbcon=rotate:3 fehlt"
HEADER_COUNT=$(grep -cE 'managed by moOde|Device filters|General settings|Do not alter|Audio overlays' "$CONFIG_FILE" || echo "0")
[ "$HEADER_COUNT" -eq 5 ] && echo "✅ Alle 5 Moode Headers vorhanden" || echo "⚠️  Headers: $HEADER_COUNT/5"
echo ""

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ FIX ABGESCHLOSSEN                                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Nächste Schritte:"
echo "  1. SD-Karte sicher auswerfen"
echo "  2. SD-Karte in Pi einstecken"
echo "  3. Pi mit LAN-Kabel am Mac verbinden"
echo "  4. Pi booten"
echo "  5. SSH sollte funktionieren: ssh andre@<PI_IP>"
echo "  6. Display sollte korrekt sein (180° Rotation)"
echo ""

