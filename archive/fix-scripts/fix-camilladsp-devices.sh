#!/bin/bash
# Fix CamillaDSP device settings to match moOde configuration
# Run this on the moOde system

CONFIG_FILE="/usr/share/camilladsp/configs/bose_wave_filters.yml"
DB="/var/local/www/db/moode-sqlite3.db"

echo "=== Fixing CamillaDSP Device Settings ==="
echo ""

# Get moOde settings
CARD_NUM=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param = 'cardnum';" 2>/dev/null)
ALSA_MODE=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param = 'alsa_output_mode';" 2>/dev/null)
AUDIO_OUT=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param = 'audioout';" 2>/dev/null)
PEPPY=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param = 'peppy_display';" 2>/dev/null)
SAMPLERATE=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param = 'samplerate';" 2>/dev/null)

CARD_NUM=${CARD_NUM:-0}
ALSA_MODE=${ALSA_MODE:-plughw}
SAMPLERATE=${SAMPLERATE:-44100}

echo "moOde Settings:"
echo "  Card: $CARD_NUM"
echo "  ALSA mode: $ALSA_MODE"
echo "  Audio out: ${AUDIO_OUT:-<not set>}"
echo "  Peppy: ${PEPPY:-0}"
echo "  Samplerate: $SAMPLERATE"
echo ""

# Determine correct device (same logic as moOde's cdsp.php)
if [ "$PEPPY" = "1" ]; then
    ALSA_DEVICE="peppy"
elif [ "$AUDIO_OUT" = "Bluetooth" ]; then
    ALSA_DEVICE="btstream"
elif [ "$ALSA_MODE" = "iec958" ]; then
    ALSA_DEVICE="hw:$CARD_NUM,0"
else
    ALSA_DEVICE="$ALSA_MODE:$CARD_NUM,0"
fi

echo "Correct device: $ALSA_DEVICE"
echo ""

# Check current config
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file not found: $CONFIG_FILE"
    exit 1
fi

CURRENT_DEVICE=$(grep -A 5 "^  playback:" "$CONFIG_FILE" | grep "device:" | awk '{print $2}')
echo "Current device in config: $CURRENT_DEVICE"

if [ "$CURRENT_DEVICE" = "$ALSA_DEVICE" ]; then
    echo "✓ Device already correct"
else
    echo "⚠ Device mismatch - fixing..."
    
    # Create backup
    sudo cp "$CONFIG_FILE" "${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Use Python to fix the config
    sudo tee /tmp/fix_devices.py > /dev/null << ENDPYTHON
import yaml
import sys

config_file = '$CONFIG_FILE'
alsa_device = '$ALSA_DEVICE'
samplerate = $SAMPLERATE

try:
    with open(config_file, 'r') as f:
        config = yaml.safe_load(f)
    
    # Update playback device
    if 'devices' in config and 'playback' in config['devices']:
        config['devices']['playback']['device'] = alsa_device
        config['devices']['samplerate'] = samplerate
        
        # Detect format from ALSA if possible
        # For now, keep existing format or use S32LE as default
        if 'format' not in config['devices']['playback']:
            config['devices']['playback']['format'] = 'S32LE'
        if 'format' not in config['devices']['capture']:
            config['devices']['capture']['format'] = 'S32LE'
    
    # Write back
    with open(config_file, 'w') as f:
        yaml.dump(config, f, sort_keys=False, default_flow_style=False, allow_unicode=True)
    
    print(f"Updated device to: {alsa_device}")
    print(f"Updated samplerate to: {samplerate}")
    sys.exit(0)
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
ENDPYTHON

    sudo python3 /tmp/fix_devices.py
    
    if [ $? -eq 0 ]; then
        echo "✓ Device updated!"
    else
        echo "✗ Failed to update device"
        exit 1
    fi
    
    sudo rm -f /tmp/fix_devices.py
fi

echo ""
echo "Validating config..."
camilladsp -c "$CONFIG_FILE" 2>&1

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Config is valid!"
    echo ""
    echo "Updated settings:"
    echo "  Playback device: $ALSA_DEVICE"
    echo "  Samplerate: $SAMPLERATE"
    echo ""
    echo "You may need to restart CamillaDSP or play audio for changes to take effect."
else
    echo ""
    echo "✗ Config validation failed!"
    exit 1
fi

