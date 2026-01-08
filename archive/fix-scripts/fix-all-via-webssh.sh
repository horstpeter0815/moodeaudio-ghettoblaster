#!/bin/bash
################################################################################
# FIX SSH AND DISPLAY VIA WEBSSH
# 
# Complete fix script that can be executed via WebSSH
# Fixes:
# 1. SSH permanently enabled
# 2. Display rotation (180°)
# 3. All Moode headers to prevent overwrite
#
# Usage: Copy and paste into WebSSH terminal
################################################################################

cat << 'FIX_SCRIPT'
#!/bin/bash
# Complete Fix Script for SSH and Display
# Execute this in WebSSH: http://<PI_IP>:4200

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 FIX SSH AND DISPLAY                                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

################################################################################
# FIX SSH
################################################################################

echo "=== FIX SSH ==="
sudo systemctl enable ssh
sudo systemctl start ssh
sudo touch /boot/firmware/ssh
sudo chmod 644 /boot/firmware/ssh
echo "✅ SSH enabled"
echo ""

################################################################################
# FIX DISPLAY
################################################################################

echo "=== FIX DISPLAY ==="
sudo mount -o remount,rw /boot/firmware

CONFIG_FILE="/boot/firmware/config.txt"
CMDLINE_FILE="/boot/firmware/cmdline.txt"

# Backup
sudo cp "$CONFIG_FILE" "${CONFIG_FILE}.backup_$(date +%Y%m%d_%H%M%S)"
sudo cp "$CMDLINE_FILE" "${CMDLINE_FILE}.backup_$(date +%Y%m%d_%H%M%S)"

# Ensure Moode header
if ! grep -q "^# This file is managed by moOde" "$CONFIG_FILE"; then
    sudo sed -i '1i# This file is managed by moOde' "$CONFIG_FILE"
fi

# Ensure all 5 Moode headers exist
HEADERS=(
    "# This file is managed by moOde"
    "# Device filters"
    "# General settings"
    "# Do not alter this section"
    "# Audio overlays"
)

for header in "${HEADERS[@]}"; do
    if ! grep -q "^$header" "$CONFIG_FILE"; then
        echo "⚠️  Header fehlt: $header"
    fi
done

# Fix display_rotate=2 in [pi5] section
if grep -q "^\[pi5\]" "$CONFIG_FILE"; then
    # Remove existing display_rotate from [pi5] section
    sudo sed -i '/^\[pi5\]/,/^\[/ {/^display_rotate=/d}' "$CONFIG_FILE"
    # Add display_rotate=2 after [pi5]
    sudo sed -i '/^\[pi5\]/a display_rotate=2' "$CONFIG_FILE"
    echo "✅ display_rotate=2 in [pi5] Section gesetzt"
else
    # Add [pi5] section after # Device filters
    sudo sed -i '/^# Device filters$/a\
[pi5]\
display_rotate=2\
dtoverlay=vc4-kms-v3d-pi5,noaudio\
hdmi_enable_4kp60=0\
hdmi_timings=400 0 220 32 110 1280 0 10 10 10 0 0 0 60 0 59510000 0\
hdmi_ignore_edid=0xa5000080\
hdmi_force_hotplug=1\
disable_splash=1
' "$CONFIG_FILE"
    echo "✅ [pi5] Section mit display_rotate=2 hinzugefügt"
fi

# Fix cmdline.txt - fbcon=rotate:3
sudo sed -i 's/ fbcon=rotate:[0-9]//g' "$CMDLINE_FILE"
sudo sed -i 's/$/ fbcon=rotate:3/' "$CMDLINE_FILE"
echo "✅ fbcon=rotate:3 in cmdline.txt gesetzt"

sync
echo "✅ Display fixed"
echo ""

################################################################################
# VERIFICATION
################################################################################

echo "=== VERIFICATION ==="
echo ""
echo "SSH Status:"
systemctl is-enabled ssh 2>/dev/null && echo "  ✅ SSH enabled" || echo "  ⚠️  SSH not enabled"
systemctl is-active ssh 2>/dev/null && echo "  ✅ SSH active" || echo "  ⚠️  SSH not active"
[ -f /boot/firmware/ssh ] && echo "  ✅ SSH flag exists" || echo "  ⚠️  SSH flag missing"
echo ""
echo "Display Settings:"
grep -E "^display_rotate=" "$CONFIG_FILE" && echo "  ✅ display_rotate gesetzt" || echo "  ⚠️  display_rotate nicht gefunden"
grep -E "fbcon=rotate:3" "$CMDLINE_FILE" && echo "  ✅ fbcon=rotate:3 gesetzt" || echo "  ⚠️  fbcon nicht gefunden"
echo ""

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ FIX ABGESCHLOSSEN                                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Nächste Schritte:"
echo "  1. SSH sollte jetzt funktionieren: ssh andre@$(hostname -I | awk '{print $1}')"
echo "  2. Reboot: sudo reboot"
echo "  3. Nach Reboot sollte Display korrekt sein (180° Rotation)"
echo ""
FIX_SCRIPT

echo ""
echo "=== ANLEITUNG ==="
echo ""
echo "1. Öffne WebSSH: http://192.168.1.101:4200"
echo ""
echo "2. Kopiere den kompletten Script-Inhalt oben"
echo ""
echo "3. Füge ihn in das WebSSH-Terminal ein und drücke Enter"
echo ""
echo "4. Das Script wird automatisch SSH und Display fixen"
echo ""

