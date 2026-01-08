#!/bin/bash
# Apply Bose Wave filters from Room EQ file

FILTER_FILE="${1:-/var/lib/camilladsp/filters/bose_wave_filters.txt}"
PRESET_NAME="${2:-bose_wave_filters}"
SAMPLERATE="${3:-44100}"
CARDNUM="${4:-0}"

if [ ! -f "$FILTER_FILE" ]; then
    echo "Error: Filter file not found: $FILTER_FILE" >&2
    exit 1
fi

IMPORT_SCRIPT="/usr/local/bin/import-roon-eq-filter.py"
CONFIG_FILE="/usr/share/camilladsp/configs/${PRESET_NAME}.yml"

if [ ! -f "$IMPORT_SCRIPT" ]; then
    echo "Error: Import script not found: $IMPORT_SCRIPT" >&2
    exit 1
fi

echo "Importing Room EQ filters from: $FILTER_FILE"
python3 "$IMPORT_SCRIPT" "$FILTER_FILE" "$CONFIG_FILE" "$SAMPLERATE" "$CARDNUM"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Failed to generate config file" >&2
    exit 1
fi

echo "Config file generated: $CONFIG_FILE"
echo ""
echo "To apply this config in moOde, you can:"
echo "1. Use the web interface: Room Correction Wizard -> Import Room EQ"
echo "2. Or manually via CamillaDSP config selection"
echo ""
echo "Config file: $CONFIG_FILE"

