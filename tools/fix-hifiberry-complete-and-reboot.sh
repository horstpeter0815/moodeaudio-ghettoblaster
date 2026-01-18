#!/bin/bash
# Fix HiFiBerry driver with automute and disable_iec958, then reboot
# Run: sudo bash fix-hifiberry-complete-and-reboot.sh

CONFIG_FILE="/boot/firmware/config.txt"

echo "=== CONFIGURING HIFIBERRY DRIVER ==="

# Remove old HiFiBerry lines
sed -i '/dtoverlay=hifiberry-amp100/d' "$CONFIG_FILE"
sed -i '/dtoverlay=hifiberry/d' "$CONFIG_FILE"

# Add with BOTH parameters: automute + disable_iec958
if grep -q "^\[all\]" "$CONFIG_FILE"; then
    sed -i '/^\[all\]/a dtoverlay=hifiberry-amp100,automute,disable_iec958' "$CONFIG_FILE"
else
    echo "" >> "$CONFIG_FILE"
    echo "dtoverlay=hifiberry-amp100,automute,disable_iec958" >> "$CONFIG_FILE"
fi

echo "✅ HiFiBerry driver configured:"
echo "   - automute: enabled (mutes amp when no audio)"
echo "   - disable_iec958: enabled (no S/PDIF device created)"
echo ""
echo "New config.txt line:"
grep "dtoverlay.*hifiberry" "$CONFIG_FILE"
echo ""

# Also fix database while we're at it
MOODE_DB="/var/local/www/db/moode-sqlite3.db"
AMP100_CARD=$(grep -E "sndrpihifiberry|HiFiBerry" /proc/asound/cards 2>/dev/null | head -1 | awk '{print $1}' || echo "1")

sqlite3 "$MOODE_DB" <<SQL
UPDATE cfg_system SET value='plughw' WHERE param='alsa_output_mode';
UPDATE cfg_system SET value='$AMP100_CARD' WHERE param='cardnum';
UPDATE cfg_system SET value='HiFiBerry AMP100' WHERE param='adevname';
UPDATE cfg_system SET value='hardware' WHERE param='volume_type';
UPDATE cfg_mpd SET value='_audioout' WHERE param='device';
SQL

echo "✅ Database also fixed (alsa_output_mode=plughw)"
echo ""

# Sync and reboot
sync
sleep 1

echo "=== REBOOTING NOW ==="
reboot
