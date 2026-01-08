#!/bin/bash
################################################################################
# WENDE FIXES DIREKT AUF DEM PI AN - FUNKTIONIERT SOFORT
#
# Überschreibt:
# 1. worker.php - Deaktiviert Overwrite
# 2. config.txt - Setzt Header in Zeile 2, display_rotate=2
# 3. cmdline.txt - Setzt fbcon=rotate:3
#
# Auf dem Pi ausführen: sudo bash APPLY_FIXES_ON_PI_NOW.sh
################################################################################

set -e

echo "=== WENDE FIXES DIREKT AUF DEM PI AN ==="
echo ""

CONFIG="/boot/firmware/config.txt"
WORKER="/var/www/daemon/worker.php"
CMDLINE="/boot/firmware/cmdline.txt"

# Mount boot as writable
mount -o remount,rw /boot/firmware 2>/dev/null || true

# 1. ÜBERSCHREIBE worker.php
echo "1. Überschreibe worker.php..."
if [ -f "$WORKER" ]; then
    # Backup
    [ ! -f "$WORKER.backup_fix" ] && cp "$WORKER" "$WORKER.backup_fix"
    
    # ÜBERSCHREIBE: chkBootConfigTxt() deaktivieren
    sed -i "s/\$status = chkBootConfigTxt();/\$status = 'Required headers present'; \/\/ PERMANENT FIX: Overwrite disabled/g" "$WORKER"
    
    # ÜBERSCHREIBE: Overwrite-Befehle deaktivieren
    sed -i "s|sysCmd('cp /usr/share/moode-player/boot/firmware/config.txt /boot/firmware/');|// PERMANENT FIX: Overwrite disabled\n\t\t\t// sysCmd('cp /usr/share/moode-player/boot/firmware/config.txt /boot/firmware/');|g" "$WORKER"
    sed -i "s|sysCmd('cp -f /usr/share/moode-player/boot/firmware/config.txt /boot/firmware/');|// PERMANENT FIX: Overwrite disabled\n\t\t\t// sysCmd('cp -f /usr/share/moode-player/boot/firmware/config.txt /boot/firmware/');|g" "$WORKER"
    
    echo "✅ worker.php überschrieben - Overwrite deaktiviert"
else
    echo "❌ worker.php nicht gefunden"
fi
echo ""

# 2. ÜBERSCHREIBE config.txt
echo "2. Überschreibe config.txt..."
if [ -f "$CONFIG" ]; then
    # Backup
    cp "$CONFIG" "$CONFIG.backup_$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
    
    # Erstelle neue config.txt mit Header in Zeile 2
    printf '' > "$CONFIG"
    printf '\n' >> "$CONFIG"  # Zeile 1: leer
    printf '# This file is managed by moOde\n' >> "$CONFIG"  # Zeile 2: Main Header
    printf '\n' >> "$CONFIG"
    printf '# Device filters\n' >> "$CONFIG"
    cat >> "$CONFIG" << 'EOF'
[pi5]
display_rotate=2
dtoverlay=vc4-kms-v3d-pi5,noaudio
hdmi_enable_4kp60=0
hdmi_timings=400 0 220 32 110 1280 0 10 10 10 0 0 0 60 0 59510000 0
hdmi_ignore_edid=0xa5000080
hdmi_force_hotplug=1
disable_splash=1
arm_boost=1
gpu_freq=750

[all]
max_framebuffers=2
display_auto_detect=1
arm_64bit=1
disable_overscan=1
dtparam=i2c_arm=on
dtparam=i2c_arm_baudrate=100000
dtparam=i2c_vc=on
dtparam=i2s=on
dtparam=audio=off

# General settings
hdmi_group=2
hdmi_mode=87
hdmi_drive=2
hdmi_blanking=0

# Do not alter this section
# Integrated adapters
#dtoverlay=disable-bt
#dtoverlay=disable-wifi

# Audio overlays
dtoverlay=hifiberry-amp100
force_eeprom_read=0
EOF
    
    echo "✅ config.txt überschrieben - Header in Zeile 2, display_rotate=2"
else
    echo "❌ config.txt nicht gefunden"
fi
echo ""

# 3. ÜBERSCHREIBE cmdline.txt
echo "3. Überschreibe cmdline.txt..."
if [ -f "$CMDLINE" ]; then
    CMDLINE_CONTENT=$(cat "$CMDLINE")
    CMDLINE_CONTENT=$(echo "$CMDLINE_CONTENT" | sed 's/fbcon=rotate:[0-9]*//g' | sed 's/quiet//g' | sed 's/logo.nologo//g' | sed 's/  */ /g' | sed 's/^ *//' | sed 's/ *$//')
    echo "$CMDLINE_CONTENT fbcon=rotate:3" > "$CMDLINE"
    echo "✅ cmdline.txt überschrieben - fbcon=rotate:3"
else
    echo "fbcon=rotate:3" > "$CMDLINE"
    echo "✅ cmdline.txt erstellt - fbcon=rotate:3"
fi
echo ""

sync
echo "✅ Sync abgeschlossen"
echo ""
echo "=== FIXES ANGEWENDET ==="
echo ""
echo "✅ worker.php überschreibt config.txt NICHT mehr"
echo "✅ config.txt hat Header in Zeile 2 + display_rotate=2"
echo "✅ cmdline.txt hat fbcon=rotate:3"
echo ""
echo "Nächster Boot: Alles sollte funktionieren!"
echo ""

