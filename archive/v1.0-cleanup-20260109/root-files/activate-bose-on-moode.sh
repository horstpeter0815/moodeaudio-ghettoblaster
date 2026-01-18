cat > /tmp/activate_bose.sh << 'ENDOFSCRIPT'
#!/bin/bash
CONFIG_NAME="bose_wave_filters.yml"
MOODE_DB="/var/local/www/db/moode-sqlite3.db"

if [ ! -f "/usr/share/camilladsp/configs/$CONFIG_NAME" ]; then
    echo "ERROR: Config file not found!"
    exit 1
fi

echo "Updating database..."
sudo sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value = '$CONFIG_NAME' WHERE param = 'camilladsp';"

sudo tee /tmp/activate_cdsp.php > /dev/null << 'ENDPHP'
<?php
require_once '/var/www/html/inc/common.php';
require_once '/var/www/html/inc/session.php';
require_once '/var/www/html/inc/cdsp.php';

$dbh = sqlConnect();
$result = sqlQuery("SELECT value FROM cfg_system WHERE param = 'camilladsp'", $dbh);
$config = $result[0]['value'] ?? 'off';

if ($config == 'off' || empty($config)) {
    echo "ERROR: Config not set\n";
    exit(1);
}

$cardnum_result = sqlQuery("SELECT value FROM cfg_system WHERE param = 'cardnum'", $dbh);
$cardnum = $cardnum_result[0]['value'] ?? 0;

$alsa_mode_result = sqlQuery("SELECT value FROM cfg_system WHERE param = 'alsa_output_mode'", $dbh);
$alsa_mode = $alsa_mode_result[0]['value'] ?? 'plughw';

$cdsp = new CamillaDsp($config, $cardnum, ',,,');
$cdsp->selectConfig($config);
$cdsp->setPlaybackDevice($cardnum, $alsa_mode);
$cdsp->updCDSPConfig($config, 'off', $cdsp);

echo "OK: Activated $config\n";
?>
ENDPHP

echo "Activating CamillaDSP..."
sudo -u www-data php /tmp/activate_cdsp.php && echo "✓ Success!" || echo "✗ Failed"
sleep 2
pgrep camilladsp > /dev/null && echo "✓ CamillaDSP is running" || echo "⚠ CamillaDSP not running yet"
sudo rm -f /tmp/activate_cdsp.php
ENDOFSCRIPT
chmod +x /tmp/activate_bose.sh
/tmp/activate_bose.sh

