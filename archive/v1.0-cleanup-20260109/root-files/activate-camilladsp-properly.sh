#!/bin/bash
# Properly activate CamillaDSP following moOde's exact flow
# This ensures volume/mixer handling is correct

CONFIG_NAME="bose_wave_filters.yml"
CONFIG_FILE="/usr/share/camilladsp/configs/$CONFIG_NAME"
DB="/var/local/www/db/moode-sqlite3.db"

echo "=== Properly Activating CamillaDSP ==="
echo ""

# Check if config exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file not found: $CONFIG_FILE"
    exit 1
fi

# Get settings
CARD_NUM=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param = 'cardnum';" 2>/dev/null)
ALSA_MODE=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param = 'alsa_output_mode';" 2>/dev/null)
ALSA_VOLUME=$(sqlite3 "$DB" "SELECT value FROM cfg_system WHERE param = 'alsavolume';" 2>/dev/null)

CARD_NUM=${CARD_NUM:-0}
ALSA_MODE=${ALSA_MODE:-plughw}

echo "Settings:"
echo "  Card: $CARD_NUM"
echo "  ALSA mode: $ALSA_MODE"
echo "  ALSA volume: ${ALSA_VOLUME:-<none>}"
echo ""

# Step 1: Update database with config name
echo "1. Updating database..."
sudo sqlite3 "$DB" "UPDATE cfg_system SET value = '$CONFIG_NAME' WHERE param = 'camilladsp';"
echo "✓ Config set in database"
echo ""

# Step 2: Use PHP to properly configure CamillaDSP (follows moOde's flow)
echo "2. Configuring CamillaDSP via moOde's PHP interface..."
sudo tee /tmp/activate_cdsp_proper.php > /dev/null << 'ENDPHP'
<?php
require_once '/var/www/html/inc/common.php';
require_once '/var/www/html/inc/session.php';
require_once '/var/www/html/inc/cdsp.php';
require_once '/var/www/html/inc/mpd.php';

// Open session
phpSession('open');

// Get config name
$dbh = sqlConnect();
$result = sqlQuery("SELECT value FROM cfg_system WHERE param = 'camilladsp'", $dbh);
$configName = $result[0]['value'] ?? 'off';

if ($configName == 'off' || empty($configName)) {
    echo "ERROR: Config not set in database\n";
    exit(1);
}

// Get settings
$cardnum_result = sqlQuery("SELECT value FROM cfg_system WHERE param = 'cardnum'", $dbh);
$cardnum = $cardnum_result[0]['value'] ?? 0;

$alsa_mode_result = sqlQuery("SELECT value FROM cfg_system WHERE param = 'alsa_output_mode'", $dbh);
$alsa_mode = $alsa_mode_result[0]['value'] ?? 'plughw';

// Initialize CamillaDSP
$cdsp = new CamillaDsp($configName, $cardnum, ',,,');

// Select config
$cdsp->selectConfig($configName);

// Set playback device (this updates the config file with correct device)
$cdsp->setPlaybackDevice($cardnum, $alsa_mode);

// Update session
phpSession('write', 'camilladsp', $configName);

// IMPORTANT: Call updCDSPConfig to properly handle mixer switch
// This is what we were missing!
$currentMode = 'off'; // We're switching from 'off'
$cdsp->updCDSPConfig($configName, $currentMode, $cdsp);

phpSession('close');

echo "OK: CamillaDSP properly configured\n";
echo "Mixer will be switched to CamillaDSP volume\n";
?>
ENDPHP

sudo -u www-data php /tmp/activate_cdsp_proper.php

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ CamillaDSP configured properly!"
    echo ""
    echo "The worker will now:"
    echo "  1. Switch mixer type to 'null' (CamillaDSP volume)"
    echo "  2. Start mpd2cdspvolume service"
    echo "  3. Restart MPD"
    echo "  4. Restore volume level"
    echo ""
    echo "This may take a few seconds. Check status with:"
    echo "  systemctl status mpd"
    echo "  systemctl status mpd2cdspvolume"
    echo "  pgrep camilladsp"
else
    echo ""
    echo "✗ Failed to configure"
    exit 1
fi

sudo rm -f /tmp/activate_cdsp_proper.php

echo ""
echo "=== Activation Complete ==="
echo "Audio should work correctly now with proper volume handling!"

