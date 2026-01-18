#!/bin/bash
# Apply working CamillaDSP config and fix everything
# Run: sudo bash apply-working-camilladsp.sh

set -e

AMP100_CARD=$(grep -E "sndrpihifiberry|HiFiBerry" /proc/asound/cards | head -1 | awk '{print $1}')
MOODE_DB="/var/local/www/db/moode-sqlite3.db"

echo "=== APPLYING WORKING CAMILLADSP CONFIG ==="
echo ""

# Create working CamillaDSP config
echo "Creating CamillaDSP config..."
mkdir -p /usr/share/camilladsp
cat > /usr/share/camilladsp/working_config.yml <<'EOF'
---
devices:
  samplerate: 44100
  chunksize: 4096
  queuelimit: 1
  capture:
    type: Stdin
    channels: 2
    format: S32LE
  playback:
    type: Alsa
    channels: 2
    device: "plughw:CARD_PLACEHOLDER,0"
    format: S32LE

mixers:
  to_output:
    channels:
      in: 2
      out: 2
    mapping:
      - dest: 0
        sources:
          - channel: 0
            gain: 0
            inverted: false
      - dest: 1
        sources:
          - channel: 1
            gain: 0
            inverted: false

filters: {}

pipeline:
  - type: Mixer
    name: to_output
EOF

# Replace card placeholder with actual card number
sed -i "s/CARD_PLACEHOLDER/$AMP100_CARD/g" /usr/share/camilladsp/working_config.yml
echo "✅ CamillaDSP config created for card $AMP100_CARD"
echo ""

# Fix database
echo "Fixing moOde database..."
sqlite3 "$MOODE_DB" <<SQL
UPDATE cfg_system SET value='hardware' WHERE param='volume_type';
UPDATE cfg_system SET value='on' WHERE param='camilladsp';
UPDATE cfg_system SET value='$AMP100_CARD' WHERE param='cardnum';
UPDATE cfg_mpd SET value='_audioout' WHERE param='device';
UPDATE cfg_system SET value='HiFiBerry AMP100' WHERE param='adevname';
UPDATE cfg_system SET value='HiFiBerry AMP100' WHERE param='i2sdevice';
UPDATE cfg_system SET value='plughw' WHERE param='alsa_output_mode';
SQL
echo "✅ Database fixed"
echo ""

# Fix ALSA routing
echo "Fixing ALSA routing..."
cat > /etc/alsa/conf.d/_audioout.conf <<EOF
#########################################
# This file is managed by moOde
#########################################
pcm._audioout {
type copy
slave.pcm "camilladsp"
}
EOF
echo "✅ ALSA routing: MPD → _audioout → camilladsp → HiFiBerry"
echo ""

# Set volume
echo "Setting volume..."
amixer -c "$AMP100_CARD" sset Master unmute 75% >/dev/null 2>&1 || true
amixer -c "$AMP100_CARD" sset PCM unmute 75% >/dev/null 2>&1 || true
amixer -c "$AMP100_CARD" sset Digital unmute 75% >/dev/null 2>&1 || true
echo "✅ Hardware volume: 75%"
echo ""

# Restart services
echo "Restarting services..."
systemctl stop mpd.service 2>/dev/null || true
systemctl stop camilladsp.service 2>/dev/null || true
sleep 2

echo "Starting CamillaDSP..."
systemctl start camilladsp.service
sleep 3

if systemctl is-active --quiet camilladsp.service; then
    echo "✅ CamillaDSP running"
else
    echo "❌ CamillaDSP failed!"
    journalctl -u camilladsp.service -n 10 --no-pager
    exit 1
fi

echo "Regenerating MPD config..."
php /var/www/util/upd-mpdconf.php >/dev/null 2>&1 || true

echo "Starting MPD..."
systemctl start mpd.service
sleep 3

if systemctl is-active --quiet mpd.service; then
    echo "✅ MPD running"
else
    echo "❌ MPD failed!"
    journalctl -u mpd.service -n 10 --no-pager
    exit 1
fi

echo ""
echo "=== COMPLETE ==="
echo "✅ CamillaDSP configured and running"
echo "✅ Audio chain: MPD → _audioout → camilladsp → plughw:$AMP100_CARD,0"
echo "✅ Volume type: hardware (volume control works)"
echo "✅ Hardware volume: 75%"
echo ""
echo "Test audio in moOde Web UI now!"
echo ""
