#!/bin/bash
cd /Users/andrevollmer/moodeaudio-cursor

# Copy wizard-functions.js
cp test-wizard/wizard-functions.js /Volumes/bootfs/moode_deploy/test-wizard/ && echo "✓ wizard-functions.js copied"

# Copy snd-config.html
cp test-wizard/snd-config.html /Volumes/bootfs/moode_deploy/test-wizard/ && echo "✓ snd-config.html copied"

# Create command directory and copy room-correction-wizard.php
mkdir -p /Volumes/bootfs/moode_deploy/command
cp moode-source/www/command/room-correction-wizard.php /Volumes/bootfs/moode_deploy/command/ && echo "✓ room-correction-wizard.php copied"

# List all files
echo ""
echo "=== Files on SD card ==="
find /Volumes/bootfs/moode_deploy -type f | sort

