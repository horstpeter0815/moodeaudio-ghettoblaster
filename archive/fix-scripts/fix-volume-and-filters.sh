#!/bin/bash
# Fix volume handling and filter issues
# Run this on the moOde system

DB="/var/local/www/db/moode-sqlite3.db"
CONFIG="/usr/share/camilladsp/configs/bose_wave_filters.yml"

echo "=== Fixing Volume & Filter Issues ==="
echo ""

# 1. Fix mixer type when CamillaDSP is off
echo "1. Fixing Mixer Type"
CURRENT_CDSP=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param = 'camilladsp';" 2>/dev/null)
MIXER_TYPE=$(sqlite3 "$DB" "SELECT value FROM cfg_mpd WHERE param = 'mixer_type';" 2>/dev/null)
ALSA_VOL=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param = 'alsavolume';" 2>/dev/null)

if [ "$CURRENT_CDSP" = "off" ] || [ -z "$CURRENT_CDSP" ]; then
    if [ "$MIXER_TYPE" = "none" ] || [ -z "$MIXER_TYPE" ]; then
        # Set correct mixer type based on ALSA volume
        if [ "$ALSA_VOL" != "none" ] && [ -n "$ALSA_VOL" ]; then
            CORRECT_MIXER="hardware"
        else
            CORRECT_MIXER="software"
        fi
        echo "Current mixer_type: '${MIXER_TYPE:-<none>}'"
        echo "Setting to: '$CORRECT_MIXER'"
        sudo sqlite3 "$DB" "UPDATE cfg_mpd SET value = '$CORRECT_MIXER' WHERE param = 'mixer_type';"
        echo "✓ Mixer type fixed"
    else
        echo "✓ Mixer type already correct: $MIXER_TYPE"
    fi
else
    echo "CamillaDSP is ON, mixer should be 'null'"
    if [ "$MIXER_TYPE" != "null" ]; then
        echo "⚠ Mixer type is '$MIXER_TYPE' but should be 'null'"
        echo "  Run the activation script to fix this"
    fi
fi
echo ""

# 2. Check and fix extreme filter gains
echo "2. Checking Filter Gains"
if [ -f "$CONFIG" ]; then
    # Find filters with extreme gains (>20dB or <-20dB)
    EXTREME_GAINS=$(grep "gain:" "$CONFIG" | grep -E "gain: (2[0-9]|[3-9][0-9])\.[0-9]|gain: -2[0-9]\.[0-9]|gain: -[3-9][0-9]\.[0-9]" | wc -l)
    
    if [ "$EXTREME_GAINS" -gt 0 ]; then
        echo "⚠ Found $EXTREME_GAINS filters with extreme gains (>20dB or <-20dB)"
        echo ""
        echo "Extreme gains found:"
        grep "gain:" "$CONFIG" | grep -E "gain: (2[0-9]|[3-9][0-9])\.[0-9]|gain: -2[0-9]\.[0-9]|gain: -[3-9][0-9]\.[0-9]" | head -5 | sed 's/^/  /'
        echo ""
        echo "⚠ WARNING: Extreme gains can cause clipping and distortion!"
        echo "  Consider reducing these gains or adding a master gain reduction"
        echo ""
        echo "Current master gain (peqgain):"
        grep -A 3 "^  peqgain:" "$CONFIG" | grep "gain:" | sed 's/^/  /'
        echo ""
        echo "Recommendation: Reduce master gain to compensate"
        echo "  Example: Set peqgain to -10dB to -15dB to prevent clipping"
    else
        echo "✓ No extreme gains found"
    fi
else
    echo "✗ Config file not found"
fi
echo ""

# 3. Check volume sync service
echo "3. Volume Sync Service"
if [ "$CURRENT_CDSP" != "off" ] && [ "$MIXER_TYPE" = "null" ]; then
    if ! systemctl is-active mpd2cdspvolume > /dev/null 2>&1; then
        echo "⚠ mpd2cdspvolume should be active"
        echo "  Starting service..."
        sudo systemctl start mpd2cdspvolume
        sleep 1
        if systemctl is-active mpd2cdspvolume > /dev/null 2>&1; then
            echo "✓ Service started"
        else
            echo "✗ Failed to start service"
        fi
    else
        echo "✓ Service is active"
    fi
else
    echo "Service not needed (CamillaDSP is off)"
fi
echo ""

# 4. Recommendations
echo "4. Recommendations"
echo "--------------------------------------------"
if [ "$CURRENT_CDSP" = "off" ]; then
    echo "With CamillaDSP OFF:"
    echo "  ✓ Mixer type should be 'hardware' or 'software'"
    echo "  ✓ Volume should work normally"
    echo ""
    echo "To activate filters properly:"
    echo "  Run: /tmp/activate_cdsp_correct.sh"
else
    echo "With CamillaDSP ON:"
    echo "  ✓ Mixer type should be 'null'"
    echo "  ✓ mpd2cdspvolume service should be active"
    echo ""
    if [ "$EXTREME_GAINS" -gt 0 ]; then
        echo "⚠ Filter gains are very high - consider:"
        echo "  1. Reducing master gain (peqgain) to prevent clipping"
        echo "  2. Or reducing individual filter gains"
    fi
fi
echo ""

echo "=== Fix Complete ==="

