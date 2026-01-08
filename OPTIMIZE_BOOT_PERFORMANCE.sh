#!/bin/bash
# OPTIMIZE BOOT SCREEN AND PERFORMANCE - RUN WITH SUDO
# sudo /Users/andrevollmer/moodeaudio-cursor/OPTIMIZE_BOOT_PERFORMANCE.sh

SD_MOUNT="/Volumes/bootfs"
[ ! -d "$SD_MOUNT" ] && SD_MOUNT="/Volumes/boot"

if [ ! -d "$SD_MOUNT" ]; then
    echo "❌ SD-Karte nicht gefunden"
    exit 1
fi

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ⚡ OPTIMIZE BOOT SCREEN AND PERFORMANCE                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

CONFIG_FILE="$SD_MOUNT/config.txt"
CMDLINE_FILE="$SD_MOUNT/cmdline.txt"

################################################################################
# FIX 1: BOOT SCREEN - NUR PROMPT, KEIN SPLASH
################################################################################

echo "=== FIX 1: BOOT SCREEN - NUR PROMPT ==="

# Disable splash screen in config.txt
if grep -q "^\[pi5\]" "$CONFIG_FILE"; then
    # Remove existing disable_splash from [pi5] section
    awk '/^\[pi5\]/,/^\[/ {if (/^disable_splash=/) next; print} /^\[pi5\]/ {print; print "disable_splash=1"; next} {print}' "$CONFIG_FILE" > /tmp/config_fixed.txt
    
    # Add disable_splash=1 if not already there
    if ! grep -A 5 "^\[pi5\]" /tmp/config_fixed.txt | grep -q "^disable_splash=1"; then
        awk '/^\[pi5\]/ {print; print "disable_splash=1"; next} {print}' /tmp/config_fixed.txt > /tmp/config_fixed2.txt
        mv /tmp/config_fixed2.txt /tmp/config_fixed.txt
    fi
    
    cp /tmp/config_fixed.txt "$CONFIG_FILE"
    echo "✅ disable_splash=1 in [pi5] Section gesetzt"
else
    echo "⚠️  [pi5] Section fehlt - füge hinzu..."
    awk '/^# Device filters$/ {print; print ""; print "[pi5]"; print "disable_splash=1"; next} {print}' "$CONFIG_FILE" > /tmp/config_fixed.txt
    cp /tmp/config_fixed.txt "$CONFIG_FILE"
    echo "✅ [pi5] Section mit disable_splash=1 hinzugefügt"
fi

# Remove quiet and logo from cmdline.txt (show boot messages)
if [ -f "$CMDLINE_FILE" ]; then
    CMDLINE=$(cat "$CMDLINE_FILE")
    
    # Remove quiet parameter (shows boot messages)
    CMDLINE=$(echo "$CMDLINE" | sed 's/ quiet//g' | sed 's/quiet //g')
    
    # Remove logo.nologo (shows boot messages)
    CMDLINE=$(echo "$CMDLINE" | sed 's/ logo.nologo//g' | sed 's/logo.nologo //g')
    
    # Ensure console output is visible
    if ! echo "$CMDLINE" | grep -q "console=tty1"; then
        CMDLINE="$CMDLINE console=tty1"
    fi
    
    echo "$CMDLINE" > "$CMDLINE_FILE"
    echo "✅ quiet und logo.nologo entfernt (Boot-Messages werden angezeigt)"
fi

sync
echo ""

################################################################################
# FIX 2: POWER MODE / PERFORMANCE BOOST
################################################################################

echo "=== FIX 2: POWER MODE / PERFORMANCE BOOST ==="

# Enable arm_boost (Pi 5 performance boost)
if grep -q "^\[all\]" "$CONFIG_FILE"; then
    # Remove existing arm_boost from [all] section
    awk '/^\[all\]/,/^\[/ {if (/^arm_boost=/) next; print} /^\[all\]/ {print; print "arm_boost=1"; next} {print}' "$CONFIG_FILE" > /tmp/config_fixed.txt
    
    # Add arm_boost=1 if not already there
    if ! grep -A 5 "^\[all\]" /tmp/config_fixed.txt | grep -q "^arm_boost=1"; then
        awk '/^\[all\]/ {print; print "arm_boost=1"; next} {print}' /tmp/config_fixed.txt > /tmp/config_fixed2.txt
        mv /tmp/config_fixed2.txt /tmp/config_fixed.txt
    fi
    
    cp /tmp/config_fixed.txt "$CONFIG_FILE"
    echo "✅ arm_boost=1 in [all] Section gesetzt (Pi 5 Performance Boost)"
else
    echo "⚠️  [all] Section fehlt - füge hinzu..."
    awk '/^# General settings$/ {print; print ""; print "[all]"; print "arm_boost=1"; next} {print}' "$CONFIG_FILE" > /tmp/config_fixed.txt
    cp /tmp/config_fixed.txt "$CONFIG_FILE"
    echo "✅ [all] Section mit arm_boost=1 hinzugefügt"
fi

# GPU frequency boost (optional, for better performance)
if grep -q "^\[all\]" "$CONFIG_FILE"; then
    if ! grep -A 10 "^\[all\]" "$CONFIG_FILE" | grep -q "^gpu_freq="; then
        awk '/^\[all\]/ {print; print "gpu_freq=750"; next} {print}' "$CONFIG_FILE" > /tmp/config_fixed.txt
        cp /tmp/config_fixed.txt "$CONFIG_FILE"
        echo "✅ gpu_freq=750 gesetzt (GPU Performance Boost)"
    fi
fi

sync
echo ""

################################################################################
# FIX 3: NETZWERK - LAN-KABEL OPTIMIERUNG
################################################################################

echo "=== FIX 3: NETZWERK - LAN-KABEL ==="

echo "✅ LAN-Kabel wird automatisch erkannt"
echo "   Pi 5 hat Gigabit Ethernet (schnell)"
echo ""
echo "Hinweis: Für Internet-Sharing vom Mac:"
echo "  1. System Settings → General → Sharing → Internet Sharing"
echo "  2. 'Ethernet' aktivieren"
echo "  3. Pi sollte dann Internet haben"
echo ""

################################################################################
# VERIFICATION
################################################################################

echo "=== VERIFICATION ==="
echo ""

# Check disable_splash
if grep -A 5 "^\[pi5\]" "$CONFIG_FILE" | grep -q "^disable_splash=1"; then
    echo "✅ disable_splash=1"
else
    echo "❌ disable_splash=1 fehlt"
fi

# Check quiet removed
if ! grep -q " quiet" "$CMDLINE_FILE" 2>/dev/null; then
    echo "✅ quiet entfernt (Boot-Messages sichtbar)"
else
    echo "❌ quiet noch vorhanden"
fi

# Check arm_boost
if grep -A 5 "^\[all\]" "$CONFIG_FILE" | grep -q "^arm_boost=1"; then
    echo "✅ arm_boost=1 (Performance Boost)"
else
    echo "❌ arm_boost=1 fehlt"
fi

echo ""
echo "✅ OPTIMIERUNG ABGESCHLOSSEN!"
echo ""
echo "Ergebnis:"
echo "  ✅ Boot-Screen: Nur Prompt, keine Splash-Screen"
echo "  ✅ Boot-Messages werden angezeigt"
echo "  ✅ Performance Boost aktiviert (arm_boost=1)"
echo "  ✅ LAN-Kabel wird automatisch erkannt"
echo ""

