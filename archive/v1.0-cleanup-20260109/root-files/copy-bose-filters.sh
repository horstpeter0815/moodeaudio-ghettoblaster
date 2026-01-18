#!/bin/bash
# Quick script to copy Bose Wave filters to moOde system
# Run this from the workspace root

SOURCE="moode-source/usr/share/camilladsp/configs/bose_wave_filters.yml"

if [ ! -f "$SOURCE" ]; then
    echo "Error: Source file not found: $SOURCE"
    exit 1
fi

echo "Bose Wave filters config file ready to copy:"
echo "  Source: $SOURCE"
echo ""
echo "To copy to your moOde system, run on the moOde system:"
echo ""
echo "  scp user@your-computer:$(pwd)/$SOURCE /tmp/bose_wave_filters.yml"
echo "  sudo mv /tmp/bose_wave_filters.yml /usr/share/camilladsp/configs/"
echo "  sudo chmod 644 /usr/share/camilladsp/configs/bose_wave_filters.yml"
echo ""
echo "Or if you have the source directory on the moOde system:"
echo "  sudo cp $SOURCE /usr/share/camilladsp/configs/"
echo "  sudo chmod 644 /usr/share/camilladsp/configs/bose_wave_filters.yml"
echo ""
echo "Current file size: $(wc -c < "$SOURCE") bytes"
echo "File exists: $(test -f "$SOURCE" && echo "Yes" || echo "No")"

