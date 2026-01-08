#!/bin/bash
# Install Bose Wave filters to running moOde system
# This script should be run ON THE MOODE SYSTEM (not in the source directory)

SOURCE_FILE="/path/to/moode-source/usr/share/camilladsp/configs/bose_wave_filters.yml"
TARGET_DIR="/usr/share/camilladsp/configs"
TARGET_FILE="$TARGET_DIR/bose_wave_filters.yml"

echo "Installing Bose Wave filters to moOde..."
echo ""

# Check if running on moOde system
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: This script must be run on the moOde system"
    echo "Target directory not found: $TARGET_DIR"
    exit 1
fi

# If source file path is provided as argument, use it
if [ -n "$1" ]; then
    SOURCE_FILE="$1"
fi

# Check if source file exists
if [ ! -f "$SOURCE_FILE" ]; then
    echo "Error: Source file not found: $SOURCE_FILE"
    echo ""
    echo "Usage:"
    echo "  $0 [path/to/bose_wave_filters.yml]"
    echo ""
    echo "Or copy manually:"
    echo "  sudo cp bose_wave_filters.yml $TARGET_FILE"
    echo "  sudo chmod 644 $TARGET_FILE"
    exit 1
fi

# Copy the file
echo "Copying $SOURCE_FILE to $TARGET_FILE..."
sudo cp "$SOURCE_FILE" "$TARGET_FILE"
sudo chmod 644 "$TARGET_FILE"

if [ -f "$TARGET_FILE" ]; then
    echo "✅ Successfully installed!"
    echo ""
    echo "The filter should now appear in:"
    echo "  - Audio Config → CamillaDSP → Signal processing dropdown"
    echo "  - CamillaDSP Config → Signal processing dropdown"
    echo ""
    echo "Look for: 'bose_wave_filters'"
    echo ""
    echo "To apply it:"
    echo "  1. Go to Audio Config or CamillaDSP Config"
    echo "  2. Select 'bose_wave_filters' from the dropdown"
    echo "  3. Click Apply/Save"
else
    echo "❌ Installation failed!"
    exit 1
fi

