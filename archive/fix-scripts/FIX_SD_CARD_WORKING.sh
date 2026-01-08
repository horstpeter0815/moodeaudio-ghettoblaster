#!/bin/bash
# FIX SD CARD - WORKING VERSION
# sudo ./FIX_SD_CARD_WORKING.sh

set -e

SD_MOUNT="/Volumes/bootfs"
[ ! -d "$SD_MOUNT" ] && SD_MOUNT="/Volumes/boot"

if [ ! -d "$SD_MOUNT" ]; then
    echo "❌ SD-Karte nicht gefunden"
    exit 1
fi

CONFIG_FILE="$SD_MOUNT/config.txt"
CMDLINE_FILE="$SD_MOUNT/cmdline.txt"
SSH_FLAG="$SD_MOUNT/ssh"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 FIX SD CARD - WORKING VERSION                            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "SD-Karte: $SD_MOUNT"
echo ""

################################################################################
# STEP 1: SSH FLAG
################################################################################

echo "=== STEP 1: CREATE SSH FLAG ==="
sudo touch "$SSH_FLAG"
sudo chmod 644 "$SSH_FLAG"
sync
if [ -f "$SSH_FLAG" ]; then
    echo "✅ SSH-Flag erstellt"
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

# Backup
sudo cp "$CONFIG_FILE" "${CONFIG_FILE}.backup_$(date +%Y%m%d_%H%M%S)"

# Read current
CURRENT=$(cat "$CONFIG_FILE")

# Check if [pi5] exists
if echo "$CURRENT" | grep -q "^\[pi5\]"; then
    echo "✅ [pi5] Section vorhanden"
    # Remove existing display_rotate from [pi5] section
    sudo awk '
        /^\[pi5\]/ { in_pi5=1; print; next }
        /^\[/ && in_pi5 { in_pi5=0 }
        in_pi5 && /^display_rotate=/ { next }
        { print }
    ' "$CONFIG_FILE" > /tmp/config_fixed.txt
    
    # Add display_rotate=2 after [pi5]
    sudo awk '/^\[pi5\]/ {print; print "display_rotate=2"; next} {print}' /tmp/config_fixed.txt > /tmp/config_fixed2.txt
    sudo mv /tmp/config_fixed2.txt "$CONFIG_FILE"
    sudo rm /tmp/config_fixed.txt
    echo "✅ display_rotate=2 gesetzt"
else
    echo "⚠️  [pi5] Section fehlt - füge hinzu"
    # Add [pi5] section after # Device filters
    sudo awk '
        /^# Device filters$/ { 
            print; 
            print ""; 
            print "[pi5]"; 
            print "display_rotate=2"; 
            next 
        }
        { print }
    ' "$CONFIG_FILE" > /tmp/config_fixed.txt
    sudo mv /tmp/config_fixed.txt "$CONFIG_FILE"
    echo "✅ [pi5] Section mit display_rotate=2 hinzugefügt"
fi

sync
echo ""

################################################################################
# STEP 3: FIX CMDLINE.TXT
################################################################################

echo "=== STEP 3: FIX CMDLINE.TXT ==="

# Backup
sudo cp "$CMDLINE_FILE" "${CMDLINE_FILE}.backup_$(date +%Y%m%d_%H%M%S)"

# Read and fix
CMDLINE=$(cat "$CMDLINE_FILE")
CMDLINE=$(echo "$CMDLINE" | sed 's/ fbcon=rotate:[0-9]//g')
CMDLINE=$(echo "$CMDLINE" | sed 's/  / /g')

if ! echo "$CMDLINE" | grep -q "fbcon=rotate:3"; then
    CMDLINE="${CMDLINE} fbcon=rotate:3"
fi

echo "$CMDLINE" | sudo tee "$CMDLINE_FILE" > /dev/null
sync
echo "✅ fbcon=rotate:3 gesetzt"
echo ""

################################################################################
# VERIFICATION
################################################################################

echo "=== VERIFICATION ==="
echo ""

SSH_OK="❌"
DISPLAY_OK="❌"
FBCON_OK="❌"

if [ -f "$SSH_FLAG" ]; then
    SSH_OK="✅"
    echo "✅ SSH-Flag vorhanden"
else
    echo "❌ SSH-Flag fehlt"
fi

if grep -q "display_rotate=2" "$CONFIG_FILE"; then
    DISPLAY_OK="✅"
    echo "✅ display_rotate=2 gefunden"
    grep "display_rotate=2" "$CONFIG_FILE"
else
    echo "❌ display_rotate=2 nicht gefunden"
fi

if grep -q "fbcon=rotate:3" "$CMDLINE_FILE"; then
    FBCON_OK="✅"
    echo "✅ fbcon=rotate:3 gefunden"
else
    echo "❌ fbcon=rotate:3 nicht gefunden"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
if [ "$SSH_OK" = "✅" ] && [ "$DISPLAY_OK" = "✅" ] && [ "$FBCON_OK" = "✅" ]; then
    echo "║  ✅ ALLES KORREKT - SD-KARTE BEREIT                       ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    echo "Nächste Schritte:"
    echo "  1. SD-Karte sicher auswerfen"
    echo "  2. SD-Karte in Pi einstecken"
    echo "  3. Pi mit LAN-Kabel am Mac verbinden"
    echo "  4. Pi booten"
    echo "  5. SSH: ssh andre@<PI_IP>"
    echo "  6. Display sollte 180° Rotation haben"
    exit 0
else
    echo "║  ⚠️  ETWAS FEHLT NOCH                                     ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    exit 1
fi

