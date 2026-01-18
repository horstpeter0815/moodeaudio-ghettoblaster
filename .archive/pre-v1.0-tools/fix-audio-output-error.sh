#!/bin/bash
# Fix "failed to open audio output" error
# Run: sudo bash fix-audio-output-error.sh

set -e

AMP100_CARD=$(grep -E "sndrpihifiberry|HiFiBerry" /proc/asound/cards | head -1 | awk '{print $1}')

echo "=== FIXING 'failed to open audio output' ==="
echo ""

# Check CamillaDSP status first
echo "1. Checking CamillaDSP..."
if systemctl is-active --quiet camilladsp.service 2>/dev/null; then
    echo "✅ CamillaDSP is running"
else
    echo "❌ CamillaDSP is NOT running - this is the problem!"
    echo "CamillaDSP logs:"
    journalctl -u camilladsp.service -n 20 --no-pager | tail -10
    echo ""
fi

# Check if CamillaDSP config exists
echo "2. Checking CamillaDSP config..."
if [ -f "/usr/share/camilladsp/working_config.yml" ]; then
    echo "✅ Config exists"
    
    # Check for syntax errors
    if grep -q "channel:" /usr/share/camilladsp/working_config.yml && ! grep -q "channels:" /usr/share/camilladsp/working_config.yml; then
        echo "❌ Config error: 'channel:' should be 'channels:'"
        echo "FIXING..."
        sed -i 's/^\([[:space:]]*\)channel:\([[:space:]]*[0-9]\)/\1channels:\2/g' /usr/share/camilladsp/working_config.yml
        echo "✅ Fixed"
    fi
    
    # Check output device
    OUTPUT_DEV=$(grep "device:" /usr/share/camilladsp/working_config.yml | grep -v "^#" | tail -1 || echo "")
    echo "Output device config: $OUTPUT_DEV"
else
    echo "❌ CamillaDSP config missing!"
    echo "Creating basic config..."
    
    mkdir -p /usr/share/camilladsp
    cat > /usr/share/camilladsp/working_config.yml <<EOF
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
    device: "plughw:$AMP100_CARD,0"
    format: S32LE

mixers: {}

filters: {}

pipeline:
  - type: Mixer
    name: to_out
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
EOF
    echo "✅ Created basic config"
fi
echo ""

# Fix database and routing
echo "3. Fixing database and routing..."
MOODE_DB="/var/local/www/db/moode-sqlite3.db"
sqlite3 "$MOODE_DB" <<SQL
UPDATE cfg_system SET value='hardware' WHERE param='volume_type';
UPDATE cfg_system SET value='on' WHERE param='camilladsp';
UPDATE cfg_system SET value='$AMP100_CARD' WHERE param='cardnum';
UPDATE cfg_mpd SET value='_audioout' WHERE param='device';
UPDATE cfg_system SET value='HiFiBerry AMP100' WHERE param='adevname';
SQL

cat > /etc/alsa/conf.d/_audioout.conf <<EOF
pcm._audioout {
type copy
slave.pcm "camilladsp"
}
EOF
echo "✅ Database and routing fixed"
echo ""

# Set volume
echo "4. Setting volume..."
amixer -c "$AMP100_CARD" sset Master unmute >/dev/null 2>&1
amixer -c "$AMP100_CARD" sset PCM unmute >/dev/null 2>&1
amixer -c "$AMP100_CARD" sset Master 75% >/dev/null 2>&1
amixer -c "$AMP100_CARD" sset PCM 75% >/dev/null 2>&1
echo "✅ Volume set to 75%"
echo ""

# Restart services in correct order
echo "5. Restarting services..."
systemctl stop mpd.service 2>/dev/null || true
systemctl stop camilladsp.service 2>/dev/null || true
sleep 2

echo "Starting CamillaDSP..."
systemctl start camilladsp.service
sleep 3

if systemctl is-active --quiet camilladsp.service 2>/dev/null; then
    echo "✅ CamillaDSP started successfully"
else
    echo "❌ CamillaDSP failed to start!"
    echo "Logs:"
    journalctl -u camilladsp.service -n 15 --no-pager
    exit 1
fi

echo "Regenerating MPD config..."
php /var/www/util/upd-mpdconf.php >/dev/null 2>&1 || echo "Regen warning (OK)"

echo "Starting MPD..."
systemctl start mpd.service
sleep 3

if systemctl is-active --quiet mpd.service 2>/dev/null; then
    echo "✅ MPD started successfully"
else
    echo "❌ MPD failed to start!"
    echo "Logs:"
    journalctl -u mpd.service -n 15 --no-pager
    exit 1
fi
echo ""

# Test the audio chain
echo "6. Testing audio chain..."
if mpc outputs 2>/dev/null | grep -q "enabled"; then
    echo "✅ MPD output enabled"
else
    echo "❌ MPD output disabled - enabling..."
    mpc enable only 1 2>/dev/null || true
fi

echo ""
echo "=== FIX COMPLETE ==="
echo ""
echo "Audio chain: MPD → _audioout → camilladsp → HiFiBerry (card $AMP100_CARD)"
echo ""
systemctl status camilladsp.service --no-pager -l | head -5
systemctl status mpd.service --no-pager -l | head -5
echo ""
echo "Test by playing a track in moOde Web UI"
echo ""
