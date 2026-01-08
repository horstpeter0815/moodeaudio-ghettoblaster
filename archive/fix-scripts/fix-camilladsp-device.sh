#!/bin/bash
# Fix CamillaDSP config to use correct ALSA device instead of non-existent 'peppy'

echo "=== Fixing CamillaDSP Device Configuration ==="
echo ""

CONFIG_FILE="/usr/share/camilladsp/configs/bose_wave_filters.yml"
WORKING_CONFIG="/usr/share/camilladsp/working_config.yml"

# Get the correct ALSA output mode from database
ALSA_OUTPUT_MODE=$(sqlite3 /var/local/www/db/moode-sqlite3.db "SELECT value FROM cfg_system WHERE param='alsa_output_mode';" 2>/dev/null || echo "plughw")
CARDNUM=$(sqlite3 /var/local/www/db/moode-sqlite3.db "SELECT value FROM cfg_system WHERE param='cardnum';" 2>/dev/null || echo "0")

# Determine correct device string
if [ "$ALSA_OUTPUT_MODE" = "iec958" ]; then
    ALSA_DEVICE="default:vc4hdmi"
else
    ALSA_DEVICE="${ALSA_OUTPUT_MODE}:${CARDNUM},0"
fi

echo "Detected ALSA output mode: $ALSA_OUTPUT_MODE"
echo "Card number: $CARDNUM"
echo "Setting device to: $ALSA_DEVICE"
echo ""

# Fix the config file
if [ -f "$CONFIG_FILE" ]; then
    echo "Fixing $CONFIG_FILE..."
    
    # Replace any peppy device references
    sudo sed -i "s/device:.*peppy.*/device: \"$ALSA_DEVICE\"/g" "$CONFIG_FILE"
    sudo sed -i "s/device: peppy/device: \"$ALSA_DEVICE\"/g" "$CONFIG_FILE"
    
    # Also fix if it's using hw:0,0 but should use plughw (more compatible)
    if [ "$ALSA_OUTPUT_MODE" = "plughw" ]; then
        sudo sed -i "s/device: hw:0,0/device: \"plughw:0,0\"/g" "$CONFIG_FILE"
        sudo sed -i "s/device: \"hw:0,0\"/device: \"plughw:0,0\"/g" "$CONFIG_FILE"
    fi
    
    # Verify the fix
    echo ""
    echo "Current playback device in config:"
    grep -A 3 "playback:" "$CONFIG_FILE" | grep "device:"
    
    # Update working_config.yml if it's not a symlink, or recreate symlink
    if [ -L "$WORKING_CONFIG" ]; then
        echo ""
        echo "working_config.yml is a symlink - will point to updated config"
        sudo rm -f "$WORKING_CONFIG"
        sudo ln -s "$CONFIG_FILE" "$WORKING_CONFIG"
    elif [ -f "$WORKING_CONFIG" ]; then
        echo ""
        echo "Fixing $WORKING_CONFIG..."
        sudo sed -i "s/device:.*peppy.*/device: \"$ALSA_DEVICE\"/g" "$WORKING_CONFIG"
        sudo sed -i "s/device: peppy/device: \"$ALSA_DEVICE\"/g" "$WORKING_CONFIG"
        if [ "$ALSA_OUTPUT_MODE" = "plughw" ]; then
            sudo sed -i "s/device: hw:0,0/device: \"plughw:0,0\"/g" "$WORKING_CONFIG"
            sudo sed -i "s/device: \"hw:0,0\"/device: \"plughw:0,0\"/g" "$WORKING_CONFIG"
        fi
    fi
    
    echo ""
    echo "✓ Config file fixed!"
    echo ""
    echo "Restarting MPD to apply changes..."
    sudo systemctl restart mpd
    
    sleep 3
    
    echo ""
    echo "Checking if CamillaDSP starts..."
    if pgrep camilladsp > /dev/null; then
        echo "✓ CamillaDSP is running! (PID: $(pgrep camilladsp))"
    else
        echo "⚠ CamillaDSP not running yet. Try playing audio:"
        echo "  mpc play"
        echo ""
        echo "Then check: pgrep camilladsp"
    fi
else
    echo "✗ Config file not found: $CONFIG_FILE"
    exit 1
fi

echo ""
echo "=== Fix Complete ==="

