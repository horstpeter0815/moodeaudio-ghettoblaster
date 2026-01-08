#!/bin/bash
# Activate CamillaDSP using EXACT moOde flow - researched from source code
# This script follows the exact same path as the Web UI

PHP_BASE="/var/www"
CONFIG_NAME="bose_wave_filters.yml"
DB="/var/local/www/db/moode-sqlite3.db"

echo "=== Activating CamillaDSP (Researched Implementation) ==="
echo ""

# Step 1: Use moOde's EXACT flow from snd-config.php
echo "1. Activating using moOde's exact Web UI flow..."
sudo tee /tmp/activate_researched.php > /dev/null << 'ENDPHP'
<?php
// Exact implementation based on snd-config.php lines 464-475
require_once '/var/www/inc/common.php';
require_once '/var/www/inc/session.php';
require_once '/var/www/inc/cdsp.php';
require_once '/var/www/inc/audio.php';

// Get session ID from database (same as worker daemon)
$sessionId = phpSession('get_sessionid');
if (!empty($sessionId)) {
    session_id($sessionId);
}

// Open session with correct ID
phpSession('open');

// Load system config into session (CRITICAL - same as worker does)
phpSession('load_system');

// Get current mode
$currentMode = $_SESSION['camilladsp'] ?? 'off';
$newMode = 'bose_wave_filters.yml';

// Update database first
$dbh = sqlConnect();
sqlUpdate('cfg_system', $dbh, 'camilladsp', $newMode);

// Initialize CamillaDSP (same as snd-config.php)
$cardnum = $_SESSION['cardnum'] ?? 0;
$cdsp = new CamillaDsp($currentMode, $cardnum, $_SESSION['camilladsp_quickconv'] ?? ',,,');

// Update session
phpSession('write', 'camilladsp', $newMode);

// Select config
$cdsp->selectConfig($newMode);

// Set playback device if needed
if ($_SESSION['cdsp_fix_playback'] == 'Yes') {
    $cdsp->setPlaybackDevice($_SESSION['cardnum'], $_SESSION['alsa_output_mode']);
}

// CRITICAL: This handles mixer switch and submits job to worker
$cdsp->updCDSPConfig($newMode, $currentMode, $cdsp);

// Close session so worker can read it
phpSession('close');

echo "OK: Activation complete\n";
echo "Job submitted to worker daemon\n";
?>
ENDPHP

sudo -u www-data php /tmp/activate_researched.php

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Activation complete!"
    echo ""
    echo "The worker daemon will process the job and:"
    echo "  - Switch mixer_type to 'null' (CamillaDSP volume)"
    echo "  - Start mpd2cdspvolume service"
    echo "  - Restart MPD"
    echo "  - Restore volume"
    echo ""
    echo "This takes 5-10 seconds. Check status:"
    echo "  tail -f /var/log/moode.log"
    echo "  systemctl status mpd"
    echo "  pgrep camilladsp"
else
    echo ""
    echo "✗ Failed"
    exit 1
fi

sudo rm -f /tmp/activate_researched.php
echo ""
echo "=== Complete ==="

