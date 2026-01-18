#!/bin/bash
# Activate CamillaDSP using moOde's command API (same as Web UI)
# This is the CORRECT way - uses the exact same flow as the Web UI

CONFIG_NAME="bose_wave_filters.yml"
PHP_BASE="/var/www"

echo "=== Activating CamillaDSP (Using moOde Command API) ==="
echo ""

# Step 1: Update database
echo "1. Setting config in database..."
DB="/var/local/www/db/moode-sqlite3.db"
sudo sqlite3 "$DB" "UPDATE cfg_system SET value = '$CONFIG_NAME' WHERE param = 'camilladsp';"
echo "✓ Done"
echo ""

# Step 2: Use moOde's command API (same as Web UI)
echo "2. Activating via moOde Command API..."
sudo tee /tmp/activate_via_api.php > /dev/null << 'ENDPHP'
<?php
// Use moOde's command API exactly like the Web UI does
require_once '/var/www/inc/common.php';
require_once '/var/www/inc/session.php';
require_once '/var/www/inc/cdsp.php';

// Simulate POST request like Web UI
$_GET['cmd'] = 'cdsp_set_config';
$_POST['cdspconfig'] = 'bose_wave_filters.yml';

// Open session
phpSession('open');

// Get current mode from session
$currentMode = $_SESSION['camilladsp'] ?? 'off';

// Initialize CamillaDSP (same as command/camilla.php)
$cdsp = new CamillaDsp($_SESSION['camilladsp'], $_SESSION['cardnum'], $_SESSION['camilladsp_quickconv'] ?? ',,,');
$newMode = $_POST['cdspconfig'];

// Update session
phpSession('write', 'camilladsp', $newMode);
phpSession('close');

// Select config
$cdsp->selectConfig($newMode);

// Set playback device if needed
if ($_SESSION['cdsp_fix_playback'] == 'Yes') {
    $cdsp->setPlaybackDevice($_SESSION['cardnum'], $_SESSION['alsa_output_mode']);
}

// CRITICAL: Call updCDSPConfig - this handles mixer switch and worker job
$cdsp->updCDSPConfig($newMode, $currentMode, $cdsp);

unset($cdsp);

echo "OK: Activation complete\n";
echo "Worker will handle mixer switch and MPD restart\n";
?>
ENDPHP

sudo -u www-data php /tmp/activate_via_api.php

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ CamillaDSP activated via command API!"
    echo ""
    echo "The moOde worker will now:"
    echo "  - Switch mixer type to 'null' (CamillaDSP volume)"
    echo "  - Start mpd2cdspvolume service"
    echo "  - Restart MPD"
    echo "  - Restore volume level"
    echo ""
    echo "Wait 5-10 seconds, then check:"
    echo "  systemctl status mpd"
    echo "  systemctl status mpd2cdspvolume"
    echo "  pgrep camilladsp"
    echo "  mpc volume"
else
    echo ""
    echo "✗ Failed"
    exit 1
fi

sudo rm -f /tmp/activate_via_api.php

echo ""
echo "=== Complete ==="

