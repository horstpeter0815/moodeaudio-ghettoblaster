#!/bin/bash
# Fix IEC958 in audio chain - should NOT be there for I2S devices
# Run: sudo bash fix-iec958-removal.sh

echo "=== REMOVING IEC958 FROM AUDIO CHAIN ==="

AMP100_CARD=$(grep -E "sndrpihifiberry|HiFiBerry" /proc/asound/cards | head -1 | awk '{print $1}')
MOODE_DB="/var/local/www/db/moode-sqlite3.db"

# IEC958 is for S/PDIF digital output, NOT for I2S devices like HiFiBerry
# moOde keeps adding it incorrectly

echo "Current audio info:"
sqlite3 "$MOODE_DB" "SELECT param, value FROM cfg_mpd WHERE param IN ('device', 'mixer_type');"
sqlite3 "$MOODE_DB" "SELECT param, value FROM cfg_system WHERE param IN ('alsa_output_mode', 'adevname', 'cardnum');"

echo ""
echo "Fixing database..."

# CRITICAL: Set alsa_output_mode to 'plughw' NOT 'iec958'
sqlite3 "$MOODE_DB" <<SQL
UPDATE cfg_system SET value='plughw' WHERE param='alsa_output_mode';
UPDATE cfg_system SET value='$AMP100_CARD' WHERE param='cardnum';
UPDATE cfg_system SET value='HiFiBerry AMP100' WHERE param='adevname';
UPDATE cfg_system SET value='HiFiBerry AMP100' WHERE param='i2sdevice';
UPDATE cfg_mpd SET value='_audioout' WHERE param='device';
UPDATE cfg_system SET value='hardware' WHERE param='volume_type';
SQL

echo "✅ Database fixed - removed IEC958"

# Fix ALSA config
cat > /etc/alsa/conf.d/_audioout.conf <<EOF
#########################################
# This file is managed by moOde
#########################################
pcm._audioout {
type copy
slave.pcm "camilladsp"
}
EOF

echo "✅ ALSA routing: MPD → _audioout → camilladsp → plughw:$AMP100_CARD,0"

# Check CamillaDSP config output device
if [ -f "/usr/share/camilladsp/working_config.yml" ]; then
    CAMILLA_OUTPUT=$(grep "device:" /usr/share/camilladsp/working_config.yml | grep -v "^#" | tail -1)
    echo "CamillaDSP output: $CAMILLA_OUTPUT"
    
    # Should be plughw:X,0 NOT iec958 or anything else
    if echo "$CAMILLA_OUTPUT" | grep -q "iec958"; then
        echo "⚠️  CamillaDSP has IEC958 - fixing..."
        sed -i "s|device:.*iec958.*|device: \"plughw:$AMP100_CARD,0\"|g" /usr/share/camilladsp/working_config.yml
        echo "✅ Fixed CamillaDSP output device"
    fi
fi

# Regenerate MPD config
echo "Regenerating MPD config..."
php /var/www/util/upd-mpdconf.php >/dev/null 2>&1 || true

# Restart services
echo "Restarting services..."
systemctl restart camilladsp.service
sleep 2
systemctl restart mpd.service
sleep 3

echo ""
echo "=== VERIFICATION ==="
mpc outputs | head -5

echo ""
echo "Audio chain should be:"
echo "  MPD → _audioout → camilladsp → plughw:$AMP100_CARD,0 (HiFiBerry)"
echo ""
echo "Check in moOde: Audio Info should show:"
echo "  - Device: _audioout"
echo "  - NO IEC958 mentioned"
echo ""
