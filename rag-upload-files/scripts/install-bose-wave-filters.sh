#!/bin/bash
# Install Bose Wave filters to moOde system

SOURCE_CONFIG="moode-source/usr/share/camilladsp/configs/bose_wave_filters.yml"
TARGET_CONFIG="/usr/share/camilladsp/configs/bose_wave_filters.yml"

if [ ! -f "$SOURCE_CONFIG" ]; then
    echo "Error: Source config file not found: $SOURCE_CONFIG"
    echo "Please run this script from the workspace root"
    exit 1
fi

echo "Installing Bose Wave filters to moOde system..."
echo "Source: $SOURCE_CONFIG"
echo "Target: $TARGET_CONFIG"
echo ""

# Copy the config file (requires sudo on actual system)
if [ -w "$(dirname $TARGET_CONFIG)" ] 2>/dev/null; then
    cp "$SOURCE_CONFIG" "$TARGET_CONFIG"
    chmod 644 "$TARGET_CONFIG"
    echo "✅ Config file installed successfully!"
    echo ""
    echo "The filter should now appear in:"
    echo "  - Audio Config → CamillaDSP dropdown"
    echo "  - CamillaDSP Config → Signal processing dropdown"
    echo ""
    echo "Select 'bose_wave_filters' from the dropdown to use it."
else
    echo "⚠️  This script needs to be run on the moOde system with appropriate permissions."
    echo "On the moOde system, run:"
    echo "  sudo cp $SOURCE_CONFIG $TARGET_CONFIG"
    echo "  sudo chmod 644 $TARGET_CONFIG"
fi

