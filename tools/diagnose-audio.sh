#!/bin/bash
# Quick Audio Diagnosis Script
# Run this on the Raspberry Pi to check audio status

echo "=== moOde Audio Diagnosis ==="
echo ""

# Check if running on Pi
if [ ! -d "/proc/asound" ]; then
    echo "❌ Not running on Pi - /proc/asound not found"
    echo "   This script must be run on the Raspberry Pi"
    exit 1
fi

echo "1. Checking HiFiBerry AMP100 detection..."
if grep -q "sndrpihifiberry\|HiFiBerry AMP100" /proc/asound/cards 2>/dev/null; then
    AMP100_CARD=$(grep -E "sndrpihifiberry|HiFiBerry AMP100" /proc/asound/cards | head -1 | awk '{print $1}' || echo "")
    echo "   ✅ AMP100 detected as card $AMP100_CARD"
    cat /proc/asound/cards | grep -E "sndrpihifiberry|HiFiBerry AMP100" | sed 's/^/   /'
else
    echo "   ❌ AMP100 NOT detected!"
    echo "   Check: dtoverlay=hifiberry-amp100 in /boot/firmware/config.txt"
    echo "   Reboot required after overlay changes"
fi

echo ""
echo "2. Checking ALSA configuration..."
AUDIOOUT_CONF="/etc/alsa/conf.d/_audioout.conf"
if [ -f "$AUDIOOUT_CONF" ]; then
    CURRENT_DEVICE=$(grep "slave.pcm" "$AUDIOOUT_CONF" | sed 's/.*"\(.*\)".*/\1/' || echo "")
    echo "   _audioout.conf: routes to '$CURRENT_DEVICE'"
    if [ "$CURRENT_DEVICE" = "plughw:0,0" ] || [ "$CURRENT_DEVICE" = "plughw:$AMP100_CARD,0" ]; then
        echo "   ⚠️  Direct routing (bypassing peppy/camilladsp)"
    elif [ "$CURRENT_DEVICE" = "peppy" ]; then
        echo "   ✅ Routing through PeppyMeter"
    elif [ "$CURRENT_DEVICE" = "camilladsp" ]; then
        echo "   ✅ Routing through CamillaDSP"
    fi
else
    echo "   ❌ _audioout.conf not found!"
fi

PEPPYOUT_CONF="/etc/alsa/conf.d/_peppyout.conf"
if [ -f "$PEPPYOUT_CONF" ]; then
    PEPPY_DEVICE=$(grep "slave.pcm" "$PEPPYOUT_CONF" | sed 's/.*"\(.*\)".*/\1/' || echo "")
    echo "   _peppyout.conf: routes to '$PEPPY_DEVICE'"
    if [ "$PEPPY_DEVICE" = "camilladsp" ]; then
        echo "   ✅ Routing through CamillaDSP"
    else
        echo "   ⚠️  Not routing through CamillaDSP (should be 'camilladsp')"
    fi
fi

echo ""
echo "3. Checking moOde database..."
MOODE_DB="/var/local/www/db/moode-sqlite3.db"
if [ -f "$MOODE_DB" ]; then
    DB_CARD=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_system WHERE param='cardnum';" 2>/dev/null || echo "")
    DB_I2S=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_system WHERE param='i2sdevice';" 2>/dev/null || echo "")
    MPD_DEVICE=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_mpd WHERE param='device';" 2>/dev/null || echo "")
    ADEVNAME=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_system WHERE param='adevname';" 2>/dev/null || echo "")
    
    echo "   cardnum: $DB_CARD"
    echo "   i2sdevice: $DB_I2S"
    echo "   MPD device: $MPD_DEVICE"
    echo "   adevname: $ADEVNAME"
    
    if [ "$MPD_DEVICE" != "_audioout" ]; then
        echo "   ⚠️  MPD device should be '_audioout', not '$MPD_DEVICE'"
    fi
    
    if [ "$ADEVNAME" != "HiFiBerry AMP100" ]; then
        echo "   ⚠️  adevname should be 'HiFiBerry AMP100', not '$ADEVNAME'"
    fi
else
    echo "   ❌ moOde database not found"
fi

echo ""
echo "4. Checking MPD status..."
if systemctl is-active --quiet mpd.service 2>/dev/null; then
    echo "   ✅ MPD is running"
    if command -v mpc >/dev/null 2>&1; then
        MPD_VOLUME=$(mpc volume 2>/dev/null | grep -oE "[0-9]+%" || echo "")
        echo "   MPD volume: $MPD_VOLUME"
        mpc outputs 2>/dev/null | head -3 | sed 's/^/   /'
    fi
else
    echo "   ❌ MPD is NOT running"
    echo "   Start with: sudo systemctl start mpd"
fi

echo ""
echo "5. Checking volume/mute state..."
if command -v amixer >/dev/null 2>&1 && [ -n "$AMP100_CARD" ]; then
    MASTER_MUTE=$(amixer -c "$AMP100_CARD" sget Master 2>/dev/null | grep -oE "\[off\]|\[on\]" | head -1 || echo "")
    PCM_MUTE=$(amixer -c "$AMP100_CARD" sget PCM 2>/dev/null | grep -oE "\[off\]|\[on\]" | head -1 || echo "")
    MASTER_VOL=$(amixer -c "$AMP100_CARD" sget Master 2>/dev/null | grep -oE "\[[0-9]+%\]" | head -1 || echo "")
    
    echo "   Master: $MASTER_MUTE $MASTER_VOL"
    echo "   PCM: $PCM_MUTE"
    
    if [ "$MASTER_MUTE" = "[off]" ] || [ "$PCM_MUTE" = "[off]" ]; then
        echo "   ⚠️  Audio is muted!"
    fi
fi

echo ""
echo "=== Diagnosis Complete ==="
echo ""
echo "To fix audio issues, run:"
echo "  sudo /usr/local/bin/fix-audio-chain.sh"
echo ""
echo "Or if that script doesn't exist:"
echo "  cd ~/moodeaudio-cursor && bash tools/fix-audio.sh"
echo ""
