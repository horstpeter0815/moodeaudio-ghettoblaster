#!/bin/bash
# Script to automatically activate Bose Wave filters on moOde
# Run this on the moOde system

echo "Activating Bose Wave filters via moOde command interface..."

# Use curl to call moOde's CamillaDSP command endpoint
# This requires a session, so we'll use a simpler approach: direct database update + config reload

CONFIG_NAME="bose_wave_filters.yml"
MOODE_DB="/var/local/www/db/moode-sqlite3.db"

# Check if config exists
if [ ! -f "/usr/share/camilladsp/configs/$CONFIG_NAME" ]; then
    echo "ERROR: Config file not found: /usr/share/camilladsp/configs/$CONFIG_NAME"
    exit 1
fi

# Get cardnum
CARD_NUM=$(sqlite3 "$MOODE_DB" "SELECT value FROM cfg_system WHERE param = 'cardnum';" 2>/dev/null)
CARD_NUM=${CARD_NUM:-0}

# Update database
echo "Updating database..."
sudo sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value = '$CONFIG_NAME' WHERE param = 'camilladsp';"

# Create PHP script to properly activate the config
sudo tee /tmp/activate_cdsp.php > /dev/null << 'ENDPHP'
<?php
require_once '/var/www/html/inc/common.php';
require_once '/var/www/html/inc/session.php';
require_once '/var/www/html/inc/cdsp.php';

// Get config from database
$dbh = sqlConnect();
$result = sqlQuery("SELECT value FROM cfg_system WHERE param = 'camilladsp'", $dbh);
$config = $result[0]['value'] ?? 'off';

if ($config == 'off' || empty($config)) {
    echo "ERROR: Config not set in database\n";
    exit(1);
}

// Get other settings
$cardnum_result = sqlQuery("SELECT value FROM cfg_system WHERE param = 'cardnum'", $dbh);
$cardnum = $cardnum_result[0]['value'] ?? 0;

$alsa_mode_result = sqlQuery("SELECT value FROM cfg_system WHERE param = 'alsa_output_mode'", $dbh);
$alsa_mode = $alsa_mode_result[0]['value'] ?? 'plughw';

// Initialize CamillaDSP
$cdsp = new CamillaDsp($config, $cardnum, ',,,');

// Select config
$cdsp->selectConfig($config);

// Set playback device
$cdsp->setPlaybackDevice($cardnum, $alsa_mode);

// Update config (handles mixer type switch)
$cdsp->updCDSPConfig($config, 'off', $cdsp);

echo "OK: CamillaDSP activated with $config\n";
?>
ENDPHP

# Run PHP script as www-data
echo "Activating CamillaDSP..."
sudo -u www-data php /tmp/activate_cdsp.php

if [ $? -eq 0 ]; then
    echo "✓ Bose Wave filters activated!"
    sleep 2
    if pgrep camilladsp > /dev/null; then
        echo "✓ CamillaDSP is running"
    else
        echo "⚠ CamillaDSP starting... (may take a moment)"
    fi
else
    echo "ERROR: Failed to activate filters"
    exit 1
fi

# Cleanup
sudo rm -f /tmp/activate_cdsp.php

echo "Done!"