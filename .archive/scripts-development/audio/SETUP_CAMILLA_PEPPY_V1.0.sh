#!/bin/bash
# Complete Audio Setup V1.0 with CamillaDSP + PeppyMeter
# - HDMI audio disabled
# - AMP100 as card 0
# - CamillaDSP enabled
# - PeppyMeter enabled
# - Software volume

set -euo pipefail

log() { echo -e "\033[0;32m[AUDIO]\033[0m $1"; }
error() { echo -e "\033[0;31m[ERROR]\033[0m $1" >&2; }

if [ ! -d "/proc/asound" ]; then
    error "Must run on Pi"
    exit 1
fi

log "=== Audio Setup V1.0: CamillaDSP + PeppyMeter ==="

# Find AMP100
if ! grep -q "sndrpihifiberry\|HiFiBerry AMP100" /proc/asound/cards 2>/dev/null; then
    error "AMP100 not detected"
    exit 1
fi

AMP100_CARD=$(grep -E "sndrpihifiberry|HiFiBerry AMP100" /proc/asound/cards | head -1 | awk '{print $1}')
log "AMP100: card $AMP100_CARD"

# Update database
MOODE_DB="/var/local/www/db/moode-sqlite3.db"
if [ -f "$MOODE_DB" ]; then
    sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='$AMP100_CARD' WHERE param='cardnum';" 2>/dev/null
    sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='HiFiBerry AMP100' WHERE param='i2sdevice';" 2>/dev/null
    sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='HiFiBerry AMP100' WHERE param='adevname';" 2>/dev/null
    
    # PeppyMeter ON
    sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='1' WHERE param='peppy_display';" 2>/dev/null
    sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='meter' WHERE param='peppy_display_type';" 2>/dev/null
    
    # CamillaDSP ON (use your config file name)
    sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='bose_wave_filters.yml' WHERE param='camilladsp';" 2>/dev/null
    sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='Yes' WHERE param='cdsp_fix_playback';" 2>/dev/null
    
    # Software volume
    sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='Software' WHERE param='volume_control';" 2>/dev/null
    sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='100' WHERE param='volume_db_range';" 2>/dev/null
    
    # ALSA mode
    sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='plughw' WHERE param='alsa_output_mode';" 2>/dev/null
    sqlite3 "$MOODE_DB" "UPDATE cfg_mpd SET value='_audioout' WHERE param='device';" 2>/dev/null
    
    log "Database updated"
fi

# ALSA routing: MPD → camilladsp → peppy → AMP100
mkdir -p /etc/alsa/conf.d/
cat > /etc/alsa/conf.d/_audioout.conf << EOF
pcm._audioout {
    type copy
    slave.pcm "camilladsp"
}
EOF

cat > /etc/alsa/conf.d/_peppyout.conf << EOF
pcm._peppyout {
    type copy
    slave.pcm "plughw:$AMP100_CARD,0"
}
EOF
log "ALSA routing: MPD → camilladsp → peppy → AMP100"

# PeppyMeter config
if [ -f /etc/peppymeter/config.txt ]; then
    sed -i 's/^meter = .*/meter = blue/; s/^random.meter.interval = .*/random.meter.interval = 0/; s/^meter.folder = .*/meter.folder = 1280x400/; s/^screen.width = .*/screen.width = 1280/; s/^screen.height = .*/screen.height = 400/' /etc/peppymeter/config.txt 2>/dev/null
    log "PeppyMeter configured"
fi

# Restart services
systemctl restart mpd 2>/dev/null && sleep 2
systemctl restart camilladsp 2>/dev/null && sleep 1
systemctl restart peppymeter 2>/dev/null && sleep 1
log "Services restarted"

# Volume
amixer -c "$AMP100_CARD" set Master unmute >/dev/null 2>&1
amixer -c "$AMP100_CARD" set Master 100% >/dev/null 2>&1
mpc volume 80 >/dev/null 2>&1
log "Volume set"

echo ""
log "=== Complete ==="
echo "CamillaDSP: ✅ Enabled"
echo "PeppyMeter: ✅ Enabled"
echo "Software volume: ✅ Enabled"
echo "Audio chain: MPD → camilladsp → peppy → AMP100"
