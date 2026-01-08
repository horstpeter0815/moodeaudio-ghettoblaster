#!/bin/bash
# Complete Fix Script - Fixes all identified issues automatically

DB="/var/local/www/db/moode-sqlite3.db"
CONFIG="/usr/share/camilladsp/configs/bose_wave_filters.yml"

echo "=========================================="
echo "COMPLETE FIX - AUTOMATIC REPAIR"
echo "=========================================="
echo ""

# ===== 1. FIX DISPLAY CONFLICT =====
echo "=== 1. Fixing Display Conflict ==="
PEPPY=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='peppy_display';" 2>/dev/null)
LOCAL=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='local_display';" 2>/dev/null)

if [ "$PEPPY" = "1" ] && [ "$LOCAL" = "1" ]; then
    echo "  Fixing: Disabling Local Display (keeping Peppy)..."
    sqlite3 "$DB" "UPDATE cfg_system SET value='0' WHERE param='local_display';"
    echo "  ✓ Fixed: local_display = 0"
else
    echo "  ✓ No display conflict"
fi
echo ""

# ===== 2. FIX CAMILLADSP DEVICE =====
echo "=== 2. Fixing CamillaDSP Device ==="

if [ -f "$CONFIG" ]; then
    # Get correct device
    ALSA_MODE=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='alsa_output_mode';" 2>/dev/null || echo "plughw")
    CARDNUM=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='cardnum';" 2>/dev/null || echo "0")
    
    if [ "$ALSA_MODE" = "iec958" ]; then
        DEVICE="default:vc4hdmi"
    else
        DEVICE="${ALSA_MODE}:${CARDNUM},0"
    fi
    
    CURRENT_DEVICE=$(grep -A 5 "playback:" "$CONFIG" 2>/dev/null | grep "device:" | awk '{print $2}' | tr -d '\"')
    echo "  Current device: $CURRENT_DEVICE"
    echo "  Setting to: $DEVICE"
    
    # Fix using Python
    python3 << PYTHON
import re
import sys

config_file = "$CONFIG"
new_device = "$DEVICE"

try:
    with open(config_file, 'r') as f:
        content = f.read()
    
    # Replace any peppy device references
    content = re.sub(r'device:\s*["\']?peppy["\']?', f'device: "{new_device}"', content, flags=re.IGNORECASE)
    
    # Also replace hw:0,0 if it should be plughw
    if "$ALSA_MODE" == "plughw":
        content = re.sub(r'device:\s*"hw:\d+,\d+"', f'device: "{new_device}"', content)
        content = re.sub(r'device:\s*hw:\d+,\d+', f'device: "{new_device}"', content)
    
    with open(config_file, 'w') as f:
        f.write(content)
    
    print(f"  ✓ Fixed device to: {new_device}")
    sys.exit(0)
except Exception as e:
    print(f"  ✗ Error: {e}")
    sys.exit(1)
PYTHON
    
    if [ $? -eq 0 ]; then
        NEW_DEVICE=$(grep -A 5 "playback:" "$CONFIG" | grep "device:" | awk '{print $2}' | tr -d '\"')
        echo "  Verified: $NEW_DEVICE"
        
        # Update symlink
        sudo rm -f /usr/share/camilladsp/working_config.yml
        sudo ln -s "$CONFIG" /usr/share/camilladsp/working_config.yml
        echo "  ✓ Updated working_config.yml symlink"
    fi
else
    echo "  ⚠ Config file not found: $CONFIG"
fi
echo ""

# ===== 3. VERIFY CONFIGURATIONS =====
echo "=== 3. Verifying Configurations ==="
echo ""

echo "Display:"
sqlite3 "$DB" "SELECT param, value FROM cfg_system WHERE param IN ('peppy_display', 'local_display');" 2>/dev/null
echo ""

echo "Audio:"
sqlite3 "$DB" "SELECT param, value FROM cfg_system WHERE param IN ('i2sdevice', 'i2soverlay');" 2>/dev/null
echo ""

if [ -f "$CONFIG" ]; then
    echo "CamillaDSP Device:"
    grep -A 3 "playback:" "$CONFIG" | grep "device:" || echo "  Not found"
fi
echo ""

# ===== 4. RESTART SERVICES =====
echo "=== 4. Restarting Services ==="
echo ""

echo "Restarting MPD..."
sudo systemctl restart mpd
sleep 2

if systemctl is-active --quiet mpd; then
    echo "  ✓ MPD restarted successfully"
else
    echo "  ⚠ MPD restart had issues"
fi
echo ""

# ===== 5. FINAL STATUS =====
echo "=== 5. Final Status ==="
echo ""

echo "MPD Status:"
systemctl is-active mpd 2>/dev/null && echo "  ✓ Running" || echo "  ✗ Not running"
echo ""

echo "CamillaDSP Process:"
if pgrep camilladsp > /dev/null; then
    echo "  ✓ Running (PID: $(pgrep camilladsp))"
else
    echo "  ✗ Not running (will start when audio plays)"
fi
echo ""

echo "mpd2cdspvolume:"
systemctl is-active mpd2cdspvolume 2>/dev/null && echo "  ✓ Active" || echo "  ✗ Inactive"
echo ""

echo "=========================================="
echo "FIX COMPLETE"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Refresh your moOde Web UI (hard refresh: Cmd+Shift+R)"
echo "  2. Test audio playback"
echo "  3. Check that CamillaDSP starts when playing audio"
echo ""

