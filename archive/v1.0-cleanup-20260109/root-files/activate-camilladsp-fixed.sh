#!/bin/bash
# Activate CamillaDSP - FIXED VERSION that ensures _audioout.conf is updated

echo "=== Activating CamillaDSP (Fixed) ==="
echo ""

sudo tee /tmp/activate_fixed.php > /dev/null << 'ENDPHP'
<?php
require_once '/var/www/inc/common.php';
require_once '/var/www/inc/session.php';
require_once '/var/www/inc/cdsp.php';
require_once '/var/www/inc/audio.php';

// Get session ID from database
$sessionId = phpSession('get_sessionid');
if (!empty($sessionId)) {
    session_id($sessionId);
}

// Open session
phpSession('open');
phpSession('load_system');

// Get current mode
$currentMode = $_SESSION['camilladsp'] ?? 'off';
$newMode = 'bose_wave_filters.yml';

// Update database
$dbh = sqlConnect();
sqlUpdate('cfg_system', $dbh, 'camilladsp', $newMode);

// Initialize CamillaDSP
$cardnum = $_SESSION['cardnum'] ?? 0;
$cdsp = new CamillaDsp($currentMode, $cardnum, $_SESSION['camilladsp_quickconv'] ?? ',,,');

// Update session (CRITICAL - must be done before updAudioOutAndBtOutConfs)
phpSession('write', 'camilladsp', $newMode);

// Select config
$cdsp->selectConfig($newMode);

// Set playback device if needed
if ($_SESSION['cdsp_fix_playback'] == 'Yes') {
    $cdsp->setPlaybackDevice($_SESSION['cardnum'], $_SESSION['alsa_output_mode']);
}

// CRITICAL FIX: Manually update _audioout.conf BEFORE submitting job
// This ensures the ALSA config is correct even if worker session load has timing issues
updAudioOutAndBtOutConfs($_SESSION['cardnum'], $_SESSION['alsa_output_mode']);
updDspAndBtInConfs($_SESSION['cardnum'], $_SESSION['alsa_output_mode']);

// Now call updCDSPConfig which submits the job to worker
$cdsp->updCDSPConfig($newMode, $currentMode, $cdsp);

phpSession('close');

echo "OK: Complete\n";
?>
ENDPHP

sudo -u www-data php /tmp/activate_fixed.php

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Activation complete!"
    echo ""
    echo "Verifying _audioout.conf was updated..."
    if grep -q "camilladsp" /etc/alsa/conf.d/_audioout.conf 2>/dev/null; then
        echo "  ✓ _audioout.conf points to camilladsp"
    else
        echo "  ✗ _audioout.conf was NOT updated correctly"
        echo "  Current contents:"
        cat /etc/alsa/conf.d/_audioout.conf | grep "slave.pcm"
    fi
    echo ""
    echo "Worker will process the job. Wait 5-10 seconds, then check:"
    echo "  pgrep camilladsp"
    echo "  systemctl status mpd2cdspvolume"
else
    echo "✗ Failed"
    exit 1
fi

sudo rm -f /tmp/activate_fixed.php
echo ""
echo "=== Complete ==="

