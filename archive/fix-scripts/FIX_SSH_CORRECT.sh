#!/bin/bash
# FIX SSH CORRECTLY - BASED ON OFFICIAL MOODE METHOD
# sudo ./FIX_SSH_CORRECT.sh

SD_MOUNT="/Volumes/bootfs"
[ ! -d "$SD_MOUNT" ] && SD_MOUNT="/Volumes/boot"

if [ ! -d "$SD_MOUNT" ]; then
    echo "❌ SD-Karte nicht gefunden"
    exit 1
fi

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 FIX SSH - OFFICIAL MOODE METHOD                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "SD-Karte: $SD_MOUNT"
echo ""

################################################################################
# STEP 1: CREATE SSH FLAG (OFFICIAL METHOD)
################################################################################

echo "=== STEP 1: CREATE SSH FLAG ==="

# Remove existing if any
sudo rm -f "$SD_MOUNT/ssh" "$SD_MOUNT/firmware/ssh" 2>/dev/null

# Create empty file (Pi 5: /boot/firmware/ssh)
if [ -d "$SD_MOUNT/firmware" ]; then
    sudo touch "$SD_MOUNT/firmware/ssh"
    echo "✅ Created: $SD_MOUNT/firmware/ssh"
fi

# Also create in root (Pi 4 compatibility)
sudo touch "$SD_MOUNT/ssh"
echo "✅ Created: $SD_MOUNT/ssh"

# Verify - file must exist (empty is fine)
if [ -f "$SD_MOUNT/ssh" ]; then
    echo "✅ SSH-Flag erstellt"
    ls -lh "$SD_MOUNT/ssh"
else
    echo "❌ SSH-Flag konnte nicht erstellt werden"
    exit 1
fi

sync
echo ""

################################################################################
# STEP 2: FIX DISPLAY
################################################################################

echo "=== STEP 2: FIX DISPLAY ==="

CONFIG_FILE="$SD_MOUNT/config.txt"
CMDLINE_FILE="$SD_MOUNT/cmdline.txt"

# Backup
sudo cp "$CONFIG_FILE" "${CONFIG_FILE}.backup_$(date +%Y%m%d_%H%M%S)" 2>/dev/null

# Fix display_rotate=2
if grep -q "^\[pi5\]" "$CONFIG_FILE"; then
    # Remove existing display_rotate
    sudo awk '
        /^\[pi5\]/ { in_pi5=1; print; next }
        /^\[/ && in_pi5 { in_pi5=0 }
        in_pi5 && /^display_rotate=/ { next }
        { print }
    ' "$CONFIG_FILE" > /tmp/config_fixed.txt
    
    # Add display_rotate=2
    sudo awk '/^\[pi5\]/ {print; print "display_rotate=2"; next} {print}' /tmp/config_fixed.txt > /tmp/config_fixed2.txt
    sudo mv /tmp/config_fixed2.txt "$CONFIG_FILE"
    sudo rm /tmp/config_fixed.txt
    echo "✅ display_rotate=2 gesetzt"
else
    # Add [pi5] section
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

# Fix cmdline.txt
sudo cp "$CMDLINE_FILE" "${CMDLINE_FILE}.backup_$(date +%Y%m%d_%H%M%S)" 2>/dev/null
CMDLINE=$(cat "$CMDLINE_FILE")
CMDLINE=$(echo "$CMDLINE" | sed 's/ fbcon=rotate:[0-9]//g')
if ! echo "$CMDLINE" | grep -q "fbcon=rotate:3"; then
    CMDLINE="${CMDLINE} fbcon=rotate:3"
fi
echo "$CMDLINE" | sudo tee "$CMDLINE_FILE" > /dev/null
echo "✅ fbcon=rotate:3 gesetzt"

sync
echo ""

################################################################################
# VERIFICATION
################################################################################

echo "=== VERIFICATION ==="
echo ""

SSH_OK="❌"
DISPLAY_OK="❌"
FBCON_OK="❌"

# Check SSH flag (must exist)
if [ -f "$SD_MOUNT/ssh" ]; then
    SSH_OK="✅"
    echo "✅ SSH-Flag: vorhanden"
else
    echo "❌ SSH-Flag: fehlt"
fi

# Check display_rotate
if grep -q "display_rotate=2" "$CONFIG_FILE"; then
    DISPLAY_OK="✅"
    echo "✅ display_rotate=2: gefunden"
else
    echo "❌ display_rotate=2: nicht gefunden"
fi

# Check fbcon
if grep -q "fbcon=rotate:3" "$CMDLINE_FILE"; then
    FBCON_OK="✅"
    echo "✅ fbcon=rotate:3: gefunden"
else
    echo "❌ fbcon=rotate:3: nicht gefunden"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
if [ "$SSH_OK" = "✅" ] && [ "$DISPLAY_OK" = "✅" ] && [ "$FBCON_OK" = "✅" ]; then
    echo "║  ✅ ALLES KORREKT                                         ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    echo "WICHTIG: Moode Standard-Login:"
    echo "  Username: pi"
    echo "  Password: moodeaudio"
    echo ""
    echo "Nach Boot:"
    echo "  ssh pi@<PI_IP>"
    echo "  Password: moodeaudio"
    echo ""
    exit 0
else
    echo "║  ⚠️  ETWAS FEHLT                                          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    exit 1
fi

