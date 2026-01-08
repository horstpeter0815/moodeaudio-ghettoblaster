#!/bin/bash
# Fix CamillaDSP config device - replace peppy with correct device

CONFIG="/usr/share/camilladsp/configs/bose_wave_filters.yml"
DB="/var/local/www/db/moode-sqlite3.db"

echo "=== Fixing CamillaDSP Device ==="
echo ""

# Get correct device settings
ALSA_MODE=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='alsa_output_mode';" 2>/dev/null || echo "plughw")
CARDNUM=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param='cardnum';" 2>/dev/null || echo "0")

if [ "$ALSA_MODE" = "iec958" ]; then
    DEVICE="default:vc4hdmi"
else
    DEVICE="${ALSA_MODE}:${CARDNUM},0"
fi

echo "Current device in config:"
grep -A 3 "playback:" "$CONFIG" 2>/dev/null | grep "device:" || echo "Config file not found or no device line"

echo ""
echo "Setting device to: $DEVICE"
echo ""

# Fix using Python to handle YAML properly
sudo python3 << PYTHON
import re
import sys

config_file = "$CONFIG"
new_device = "$DEVICE"

try:
    with open(config_file, 'r') as f:
        content = f.read()
    
    # Replace device in playback section - handle various formats
    # Match: device: peppy, device: "peppy", device: peppy, device: hw:0,0, etc.
    patterns = [
        (r'device:\s*["\']?peppy["\']?', f'device: "{new_device}"'),  # peppy
        (r'device:\s*hw:\d+,\d+', f'device: "{new_device}"'),  # hw:X,Y
        (r'device:\s*plughw:\d+,\d+', f'device: "{new_device}"'),  # plughw:X,Y
    ]
    
    for pattern, replacement in patterns:
        content = re.sub(pattern, replacement, content, flags=re.IGNORECASE)
    
    with open(config_file, 'w') as f:
        f.write(content)
    
    print(f"✓ Fixed device to: {new_device}")
    sys.exit(0)
except Exception as e:
    print(f"✗ Error: {e}")
    sys.exit(1)
PYTHON

if [ $? -eq 0 ]; then
    echo ""
    echo "Updated device:"
    grep -A 3 "playback:" "$CONFIG" | grep "device:"
    echo ""
    echo "✓ Config file updated"
    echo ""
    echo "Note: Restart MPD or reload CamillaDSP for changes to take effect"
else
    echo "✗ Failed to update config"
    exit 1
fi

