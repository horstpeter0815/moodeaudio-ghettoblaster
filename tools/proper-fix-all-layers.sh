#!/bin/bash
# PROPER FIX - Based on Device Tree Understanding
# This applies fixes at the CORRECT layer (hardware vs software)
#
# Run on Pi: sudo bash proper-fix-all-layers.sh

set -e

echo "========================================="
echo " PROPER FIX - All Layers"
echo "========================================="
echo ""
echo "Based on device tree analysis:"
echo "- Hardware: config.txt dtoverlay"
echo "- Software: moOde database + ALSA + CamillaDSP"
echo ""

CONFIG_FILE="/boot/firmware/config.txt"
MOODE_DB="/var/local/www/db/moode-sqlite3.db"
AMP100_CARD=$(grep -E "sndrpihifiberry|HiFiBerry" /proc/asound/cards 2>/dev/null | head -1 | awk '{print $1}' || echo "1")

# ====================
# 1. HARDWARE LAYER (Device Tree)
# ====================
echo "1. Fixing hardware layer (config.txt)..."

# Ensure we have hifiberry-dacplus (NOT hifiberry-amp100 on Pi 5)
if ! grep -q "^dtoverlay=hifiberry-dacplus" "$CONFIG_FILE"; then
    # Remove old overlays
    sed -i '/^dtoverlay=hifiberry-amp100/d' "$CONFIG_FILE"
    sed -i '/^dtoverlay=hifiberry-dac/d' "$CONFIG_FILE"
    
    # Add correct overlay
    if grep -q "^\[all\]" "$CONFIG_FILE"; then
        sed -i '/^\[all\]/a dtoverlay=hifiberry-dacplus' "$CONFIG_FILE"
    else
        echo "dtoverlay=hifiberry-dacplus" >> "$CONFIG_FILE"
    fi
    echo "✅ Added dtoverlay=hifiberry-dacplus"
fi

# Add auto_mute parameter
if ! grep -q "^dtparam=auto_mute" "$CONFIG_FILE"; then
    sed -i '/^dtoverlay=hifiberry-dacplus/a dtparam=auto_mute' "$CONFIG_FILE"
    echo "✅ Added dtparam=auto_mute"
fi

# Ensure audio=off (disable onboard audio)
if ! grep -q "^dtparam=audio=off" "$CONFIG_FILE"; then
    sed -i '/^dtparam=audio=on/d' "$CONFIG_FILE"
    echo "dtparam=audio=off" >> "$CONFIG_FILE"
    echo "✅ Added dtparam=audio=off"
fi

echo ""

# ====================
# 2. SOFTWARE LAYER (moOde Database)
# ====================
echo "2. Fixing software layer (moOde database)..."

sqlite3 "$MOODE_DB" <<SQL
-- CRITICAL FIX: Use plughw NOT iec958 for I2S devices
UPDATE cfg_system SET value='plughw' WHERE param='alsa_output_mode';

-- Volume control
UPDATE cfg_system SET value='hardware' WHERE param='volume_type';

-- Audio routing
UPDATE cfg_mpd SET value='_audioout' WHERE param='device';

-- Device info
UPDATE cfg_system SET value='$AMP100_CARD' WHERE param='cardnum';
UPDATE cfg_system SET value='HiFiBerry AMP100' WHERE param='adevname';
UPDATE cfg_system SET value='HiFiBerry AMP100' WHERE param='i2sdevice';

-- CamillaDSP
UPDATE cfg_system SET value='on' WHERE param='camilladsp';
SQL

echo "✅ moOde database updated:"
echo "   - alsa_output_mode = plughw (NOT iec958)"
echo "   - volume_type = hardware"
echo "   - MPD device = _audioout"
echo ""

# ====================
# 3. ALSA LAYER
# ====================
echo "3. Fixing ALSA layer (_audioout.conf)..."

cat > /etc/alsa/conf.d/_audioout.conf <<'EOF'
pcm._audioout {
    type copy
    slave.pcm "camilladsp"
}
EOF

echo "✅ ALSA routing: MPD → _audioout → camilladsp"
echo ""

# ====================
# 4. CAMILLADSP LAYER
# ====================
echo "4. Checking CamillaDSP configuration..."

if [ -f "/usr/share/camilladsp/working_config.yml" ]; then
    # Ensure output is plughw, not iec958
    if grep -q "iec958" /usr/share/camilladsp/working_config.yml; then
        sed -i "s|device:.*iec958.*|device: \"plughw:$AMP100_CARD,0\"|" /usr/share/camilladsp/working_config.yml
        echo "✅ Removed iec958 from CamillaDSP config"
    fi
    
    # Ensure 96kHz sample rate
    if ! grep -q "samplerate: 96000" /usr/share/camilladsp/working_config.yml; then
        sed -i 's/samplerate: [0-9]*/samplerate: 96000/' /usr/share/camilladsp/working_config.yml
        echo "✅ Set CamillaDSP to 96kHz"
    fi
    
    echo "✅ CamillaDSP config verified"
else
    echo "⚠️  CamillaDSP config not found (will be created by moOde)"
fi
echo ""

# ====================
# 5. RESTART SERVICES
# ====================
echo "5. Restarting audio services..."

systemctl restart camilladsp.service 2>/dev/null || true
sleep 2
systemctl restart mpd.service 2>/dev/null || true
sleep 2

echo "✅ Services restarted"
echo ""

# ====================
# VERIFICATION
# ====================
echo "========================================="
echo " VERIFICATION"
echo "========================================="
echo ""

echo "Hardware (Device Tree):"
grep "^dtoverlay=hifiberry" "$CONFIG_FILE"
grep "^dtparam=auto_mute" "$CONFIG_FILE" || echo "  (auto_mute not in config.txt yet)"
echo ""

echo "Software (moOde Database):"
sqlite3 "$MOODE_DB" "SELECT param, value FROM cfg_system WHERE param IN ('alsa_output_mode', 'volume_type', 'cardnum', 'adevname');"
echo ""

echo "Services:"
systemctl is-active camilladsp.service && echo "  CamillaDSP: ✅ running" || echo "  CamillaDSP: ❌ not running"
systemctl is-active mpd.service && echo "  MPD: ✅ running" || echo "  MPD: ❌ not running"
echo ""

echo "========================================="
echo " REBOOT REQUIRED"
echo "========================================="
echo ""
echo "Hardware changes (config.txt) require reboot."
echo "After reboot:"
echo "  - Auto-mute will be active"
echo "  - IEC958 will NOT appear in Audio Info"
echo "  - Volume control will work"
echo "  - Bose Wave filters at 96kHz active"
echo ""
echo "Run: sudo reboot"
echo ""
