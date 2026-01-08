#!/bin/bash
# Final Fix: Correct the device in CamillaDSP config file
# This is the ONLY thing needed - fix the device string in the YAML file

CONFIG="/usr/share/camilladsp/configs/bose_wave_filters.yml"

# Get correct device from moOde settings
ALSA_MODE=$(sqlite3 /var/local/www/db/moode-sqlite3.db "SELECT value FROM cfg_system WHERE param='alsa_output_mode';" 2>/dev/null || echo "plughw")
CARDNUM=$(sqlite3 /var/local/www/db/moode-sqlite3.db "SELECT value FROM cfg_system WHERE param='cardnum';" 2>/dev/null || echo "0")

if [ "$ALSA_MODE" = "iec958" ]; then
    DEVICE="default:vc4hdmi"
else
    DEVICE="${ALSA_MODE}:${CARDNUM},0"
fi

echo "Fixing device in config: $DEVICE"

# Fix the YAML file - replace the device line in the playback section
sudo python3 << PYTHON
import re
import sys

config_file = "$CONFIG"
new_device = "$DEVICE"

try:
    with open(config_file, 'r') as f:
        content = f.read()
    
    # Replace device line in playback section
    pattern = r'(playback:\s+type: Alsa\s+channels: 2\s+device: )["\']?[^"\'\n]+["\']?'
    replacement = r'\1"' + new_device + '"'
    content = re.sub(pattern, replacement, content, flags=re.MULTILINE)
    
    # Also handle any standalone device: lines that might have peppy
    content = re.sub(r'device:\s*["\']?peppy["\']?', f'device: "{new_device}"', content, flags=re.IGNORECASE)
    content = re.sub(r'device:\s*hw:0,0', f'device: "{new_device}"', content)
    
    with open(config_file, 'w') as f:
        f.write(content)
    
    print(f"✓ Fixed device to: {new_device}")
    sys.exit(0)
except Exception as e:
    print(f"✗ Error: {e}")
    sys.exit(1)
PYTHON

if [ $? -eq 0 ]; then
    # Verify
    echo ""
    echo "Current playback device:"
    grep -A 3 "playback:" "$CONFIG" | grep "device:"
    
    # Recreate symlink
    sudo rm -f /usr/share/camilladsp/working_config.yml
    sudo ln -s "$CONFIG" /usr/share/camilladsp/working_config.yml
    
    echo ""
    echo "✓ Config fixed. Restarting MPD..."
    sudo systemctl restart mpd
    
    sleep 2
    echo ""
    echo "Test: Try playing audio with 'mpc play', then check: pgrep camilladsp"
fi

