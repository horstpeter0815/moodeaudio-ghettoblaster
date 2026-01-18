#!/bin/bash
# IMMEDIATE Audio Chain Fix - Run this NOW to fix audio
# Diagnoses and fixes all audio chain issues

set -euo pipefail

echo "=== IMMEDIATE AUDIO CHAIN FIX ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root (use sudo)"
    exit 1
fi

# Step 1: Check if AMP100 is detected
echo "Step 1: Checking AMP100 detection..."
if [ ! -d "/proc/asound" ]; then
    echo "❌ ALSA not available - not running on Pi?"
    exit 1
fi

AMP100_CARD=$(grep -E "sndrpihifiberry|HiFiBerry AMP100" /proc/asound/cards 2>/dev/null | head -1 | awk '{print $1}' || echo "")
if [ -z "$AMP100_CARD" ]; then
    echo "❌ AMP100 NOT DETECTED!"
    echo ""
    echo "Available cards:"
    cat /proc/asound/cards
    echo ""
    echo "Check:"
    echo "  1. dtoverlay=hifiberry-amp100 in /boot/firmware/config.txt"
    echo "  2. Reboot required after overlay changes"
    exit 1
fi

echo "✅ AMP100 detected as card $AMP100_CARD"
echo ""

# Step 2: Update moOde database
echo "Step 2: Updating moOde database..."
MOODE_DB="/var/local/www/db/moode-sqlite3.db"
if [ -f "$MOODE_DB" ]; then
    sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='$AMP100_CARD' WHERE param='cardnum';" 2>/dev/null || true
    sqlite3 "$MOODE_DB" "UPDATE cfg_mpd SET value='$AMP100_CARD' WHERE param='device';" 2>/dev/null || true
    sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='HiFiBerry AMP100' WHERE param='i2sdevice';" 2>/dev/null || true
    echo "✅ Database updated"
else
    echo "⚠️  moOde database not found"
fi
echo ""

# Step 3: Determine routing
echo "Step 3: Determining audio routing..."
CAMILLADSP_MODE="off"
PEPPY_DISPLAY="0"

if [ -f "$MOODE_DB" ]; then
    CAMILLADSP_MODE=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_system WHERE param='camilladsp';" 2>/dev/null || echo "off")
    PEPPY_DISPLAY=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_system WHERE param='peppy_display';" 2>/dev/null || echo "0")
fi

if [ "$CAMILLADSP_MODE" != "off" ] && [ -n "$CAMILLADSP_MODE" ]; then
    TARGET_DEVICE="camilladsp"
    echo "Routing: CamillaDSP → camilladsp"
elif [ "$PEPPY_DISPLAY" = "1" ]; then
    TARGET_DEVICE="peppy"
    echo "Routing: PeppyMeter → peppy"
else
    TARGET_DEVICE="plughw:$AMP100_CARD,0"
    echo "Routing: Direct → plughw:$AMP100_CARD,0"
fi
echo ""

# Step 4: Create/Update _audioout.conf
echo "Step 4: Creating/Updating _audioout.conf..."
AUDIOOUT_CONF="/etc/alsa/conf.d/_audioout.conf"
mkdir -p /etc/alsa/conf.d

cat > "$AUDIOOUT_CONF" <<EOF
#########################################
# This file is managed by fix-audio-chain.sh
#########################################
pcm._audioout {
type copy
slave.pcm "$TARGET_DEVICE"
}
EOF

echo "✅ Created _audioout.conf with routing to $TARGET_DEVICE"
echo ""

# Step 5: Create pcm.default
echo "Step 5: Creating pcm.default..."
DEFAULT_CONF="/etc/alsa/conf.d/99-default.conf"
cat > "$DEFAULT_CONF" <<EOF
#########################################
# ALSA default device - points to moOde _audioout
# This file is managed by fix-audio-chain.sh
#########################################
pcm.!default {
    type plug
    slave.pcm "_audioout"
}

ctl.!default {
    type hw
    card $AMP100_CARD
}
EOF

echo "✅ Created pcm.default → _audioout"
echo ""

# Step 6: Update _peppyout.conf if it exists
PEPPYOUT_CONF="/etc/alsa/conf.d/_peppyout.conf"
if [ -f "$PEPPYOUT_CONF" ]; then
    echo "Step 6: Updating _peppyout.conf..."
    sed -i "s|slave.pcm \".*\"|slave.pcm \"plughw:$AMP100_CARD,0\"|" "$PEPPYOUT_CONF"
    echo "✅ Updated _peppyout.conf"
    echo ""
fi

# Step 7: Unmute and set volume
echo "Step 7: Unmuting and setting volume..."
amixer -c "$AMP100_CARD" sset Master unmute >/dev/null 2>&1 || true
amixer -c "$AMP100_CARD" sset PCM unmute >/dev/null 2>&1 || true
amixer -c "$AMP100_CARD" sset Master 50% >/dev/null 2>&1 || true
amixer -c "$AMP100_CARD" sset PCM 50% >/dev/null 2>&1 || true
echo "✅ Volume unmuted and set to 50%"
echo ""

# Step 8: Regenerate MPD config
echo "Step 8: Regenerating MPD config..."
# Use moOde's utility to regenerate MPD config
if [ -f "/var/www/util/upd-mpdconf.php" ]; then
    php /var/www/util/upd-mpdconf.php 2>/dev/null && echo "✅ MPD config regenerated via moOde utility" || echo "⚠️  MPD config regeneration failed"
elif [ -f "/var/www/inc/mpd.php" ]; then
    php -r "require '/var/www/inc/mpd.php'; updMpdConf();" 2>/dev/null && echo "✅ MPD config regenerated" || echo "⚠️  MPD config regeneration failed"
else
    echo "⚠️  Cannot regenerate MPD config - moOde files not found"
    echo "   You may need to run: moOde Web UI → Audio Config → Apply"
fi

# Verify MPD config has _audioout
MPD_CONF="/etc/mpd.conf"
if [ -f "$MPD_CONF" ]; then
    if grep -q 'device "_audioout"' "$MPD_CONF" 2>/dev/null; then
        echo "✅ MPD config has device \"_audioout\""
    else
        echo "⚠️  MPD config doesn't have device \"_audioout\""
        echo "   Run moOde Audio Config → Apply to regenerate MPD config"
    fi
fi
echo ""

# Step 9: Restart MPD
echo "Step 9: Restarting MPD..."
systemctl restart mpd.service
sleep 3

# Wait for MPD to be ready
for i in {1..10}; do
    if systemctl is-active --quiet mpd.service 2>/dev/null && command -v mpc >/dev/null 2>&1 && mpc status >/dev/null 2>&1; then
        echo "✅ MPD restarted and ready"
        break
    fi
    sleep 1
done

# Set volume
if command -v mpc >/dev/null 2>&1; then
    mpc volume 50 >/dev/null 2>&1 || true
    echo "✅ MPD volume set to 50%"
fi
echo ""

# Step 10: Verify
echo "Step 10: Verification..."
echo "ALSA cards:"
cat /proc/asound/cards
echo ""
echo "ALSA devices:"
aplay -l 2>/dev/null | grep -A 2 "card $AMP100_CARD" || echo "⚠️  Card $AMP100_CARD not found in aplay -l"
echo ""
echo "MPD status:"
systemctl status mpd.service --no-pager -l | head -20 || true
echo ""
echo "MPD output devices:"
mpc outputs 2>/dev/null || echo "⚠️  mpc outputs failed"
echo ""

echo "=== FIX COMPLETE ==="
echo ""
echo "Try playing audio now. If it still doesn't work:"
echo "  1. Check: journalctl -u mpd -n 50"
echo "  2. Check: mpc status"
echo "  3. Test: speaker-test -c 2 -t sine -f 1000 -D plughw:$AMP100_CARD,0"
echo ""
