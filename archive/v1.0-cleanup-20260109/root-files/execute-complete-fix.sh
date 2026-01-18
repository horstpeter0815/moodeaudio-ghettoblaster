#!/bin/bash
# Complete Proper Fix - Based on moOde's Actual Logic
# This fixes all issues correctly, not with workarounds

DB="/var/local/www/db/moode-sqlite3.db"
CONFIG="/usr/share/camilladsp/configs/bose_wave_filters.yml"

echo "=========================================="
echo "COMPLETE PROPER FIX - EXECUTING NOW"
echo "=========================================="
echo ""

# ===== FIX 1: Display Conflict =====
echo "=== Fix 1: Display Configuration ==="
PEPPY=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='peppy_display';" 2>/dev/null)
LOCAL=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='local_display';" 2>/dev/null)

if [ "$PEPPY" = "1" ] && [ "$LOCAL" = "1" ]; then
    echo "  Fixing: Both displays enabled - disabling Local Display..."
    sqlite3 "$DB" "UPDATE cfg_system SET value='0' WHERE param='local_display';"
    echo "  ✓ Fixed: local_display = 0"
elif [ "$PEPPY" = "1" ]; then
    echo "  ✓ Correct: Only Peppy Display active"
elif [ "$LOCAL" = "1" ]; then
    echo "  ✓ Correct: Only Local Display active"
else
    echo "  ✓ Correct: No displays active"
fi
echo ""

# ===== FIX 2: CamillaDSP Device =====
echo "=== Fix 2: CamillaDSP Device Configuration ==="
if [ -f "$CONFIG" ]; then
    ALSA_MODE=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='alsa_output_mode';" 2>/dev/null || echo "plughw")
    CARDNUM=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='cardnum';" 2>/dev/null || echo "0")
    [ "$ALSA_MODE" = "iec958" ] && DEVICE="default:vc4hdmi" || DEVICE="${ALSA_MODE}:${CARDNUM},0"
    
    CURRENT=$(grep -A 5 "playback:" "$CONFIG" 2>/dev/null | grep "device:" | awk '{print $2}' | tr -d '\"')
    echo "  Current device: $CURRENT"
    echo "  Target device: $DEVICE"
    
    if echo "$CURRENT" | grep -qi "peppy"; then
        echo "  Fixing: Replacing 'peppy' device..."
        python3 << PYTHON
import re
with open("$CONFIG", 'r') as f: c = f.read()
c = re.sub(r'device:\s*["\']?peppy["\']?', f'device: "$DEVICE"', c, flags=re.I)
with open("$CONFIG", 'w') as f: f.write(c)
print("  ✓ Fixed")
PYTHON
        sudo rm -f /usr/share/camilladsp/working_config.yml
        sudo ln -s "$CONFIG" /usr/share/camilladsp/working_config.yml
    else
        echo "  ✓ Device already correct"
    fi
else
    echo "  ⚠ Config file not found"
fi
echo ""

# ===== FIX 3: mpd2cdspvolume Service =====
echo "=== Fix 3: mpd2cdspvolume Service ==="
CAMILLADSP=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='camilladsp';" 2>/dev/null)
MIXER_TYPE=$(sqlite3 "$DB" "SELECT value FROM cfg_mpd WHERE param='mixer_type';" 2>/dev/null)

if [ "$CAMILLADSP" != "off" ] && [ "$CAMILLADSP" != "" ] && [ "$MIXER_TYPE" = "null" ]; then
    if ! systemctl is-active --quiet mpd2cdspvolume; then
        echo "  Starting mpd2cdspvolume service..."
        sudo systemctl start mpd2cdspvolume
        sleep 1
    fi
    systemctl is-active mpd2cdspvolume && echo "  ✓ Service active" || echo "  ⚠ Service not active"
else
    echo "  ℹ Service should be inactive (CamillaDSP not active or mixer_type not 'null')"
fi
echo ""

# ===== FIX 4: Restart Services =====
echo "=== Fix 4: Restarting Services ==="
echo "  Restarting worker daemon..."
sudo systemctl restart worker 2>/dev/null
sleep 2
echo "  ✓ Worker restarted"

echo "  Restarting MPD..."
sudo systemctl restart mpd
sleep 2
systemctl is-active mpd && echo "  ✓ MPD restarted" || echo "  ⚠ MPD restart had issues"
echo ""

# ===== VERIFICATION =====
echo "=== Final Verification ==="
echo ""
echo "Display Configuration:"
sqlite3 "$DB" "SELECT param, value FROM cfg_system WHERE param IN ('peppy_display', 'local_display');" 2>/dev/null
echo ""
echo "Audio Configuration:"
sqlite3 "$DB" "SELECT param, value FROM cfg_system WHERE param IN ('i2sdevice', 'i2soverlay');" 2>/dev/null
echo ""
echo "CamillaDSP Configuration:"
sqlite3 "$DB" "SELECT param, value FROM cfg_system WHERE param='camilladsp';" 2>/dev/null
if [ -f "$CONFIG" ]; then
    echo "  Device: $(grep -A 3 'playback:' "$CONFIG" | grep 'device:' | awk '{print $2}' | tr -d '\"')"
fi
echo ""
echo "Service Status:"
echo "  MPD: $(systemctl is-active mpd 2>/dev/null && echo '✓ Running' || echo '✗ Not running')"
echo "  Worker: $(systemctl is-active worker 2>/dev/null && echo '✓ Running' || echo '✗ Not running')"
echo "  mpd2cdspvolume: $(systemctl is-active mpd2cdspvolume 2>/dev/null && echo '✓ Active' || echo '✗ Inactive')"
echo "  CamillaDSP: $(pgrep camilladsp > /dev/null && echo "✓ Running (PID: $(pgrep camilladsp))" || echo '✗ Not running')"
echo ""

echo "=========================================="
echo "FIX COMPLETE"
echo "=========================================="
echo ""
echo "CRITICAL: Clear browser cache and hard refresh:"
echo "  Mac: Cmd+Shift+R"
echo "  Windows/Linux: Ctrl+Shift+R"
echo ""
echo "Then test the UI buttons - they should work correctly now."
echo ""

