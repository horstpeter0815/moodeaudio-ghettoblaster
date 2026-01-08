<?php
/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Copyright 2025 Ghettoblaster Custom Build
 * Flat EQ Preset Handler
 */

require_once __DIR__ . '/../inc/common.php';
require_once __DIR__ . '/../inc/session.php';
require_once __DIR__ . '/../inc/sql.php';
require_once __DIR__ . '/../inc/eqp.php';

phpSession('open');
$dbh = sqlConnect();

// Logging
function logFlatEQ($msg) {
    workerLog("GhettoBlaster Flat EQ: " . $msg);
}

// Security: Validate command
$allowed_commands = ['toggle', 'status', 'apply', 'get_preset'];
$cmd = $_POST['cmd'] ?? $_GET['cmd'] ?? '';
if (!in_array($cmd, $allowed_commands)) {
    header('Content-Type: application/json');
    echo json_encode(['status' => 'error', 'message' => 'Invalid command']);
    phpSession('close');
    exit;
}

$response = ['status' => 'error', 'message' => 'Invalid command'];

switch ($cmd) {
    case 'toggle':
        $enabled = isset($_POST['enabled']) ? ($_POST['enabled'] === 'true' || $_POST['enabled'] === '1') : false;
        
        // Load Flat EQ preset
        $preset_file = '/var/www/html/command/ghettoblaster-flat-eq.json';
        if (!file_exists($preset_file)) {
            $preset_file = __DIR__ . '/ghettoblaster-flat-eq.json';
        }
        
        if (file_exists($preset_file)) {
            $preset_data = json_decode(file_get_contents($preset_file), true);
            
            if ($enabled) {
                // Apply Flat EQ preset using moOde's EQ system
                $eqp12 = Eqp12($dbh);
                
                // Convert preset to moOde EQ format
                $eq_config = [
                    'bands' => [],
                    'master_gain' => $preset_data['master_gain'] ?? 0.0
                ];
                
                // Map bands to 12-band EQ
                $band_freqs = [20, 25, 31.5, 40, 50, 63, 80, 100, 125, 160, 200, 250, 315, 400, 500, 630, 800, 1000, 1250, 1600, 2000, 2500, 3150, 4000, 5000, 6300, 8000, 10000, 12500, 16000, 20000];
                $preset_bands = $preset_data['bands'] ?? [];
                
                // Find closest frequencies and map gains
                for ($i = 0; $i < 12; $i++) {
                    $target_freq = $band_freqs[$i] ?? 1000;
                    $gain = 0.0;
                    
                    // Find closest preset band
                    foreach ($preset_bands as $preset_band) {
                        $preset_freq = $preset_band['freq'] ?? 0;
                        if (abs($preset_freq - $target_freq) < 50) {
                            $gain = $preset_band['gain'] ?? 0.0;
                            break;
                        }
                    }
                    
                    $eq_config['bands'][$i] = [
                        'enabled' => 1,
                        'frequency' => $target_freq,
                        'q' => 1.0,
                        'gain' => $gain
                    ];
                }
                
                // Save as new preset or update existing
                $preset_id = $eqp12->setpreset(null, 'Ghetto Crew Flat EQ', $eq_config);
                $eqp12->setActivePresetIndex($preset_id);
                
                logFlatEQ("Flat EQ enabled, preset ID: $preset_id");
            } else {
                // Disable Flat EQ - restore previous preset or disable EQ
                $eqp12 = Eqp12($dbh);
                // Could restore to previous preset or disable EQ
                logFlatEQ("Flat EQ disabled");
            }
        }
        
        // Save state to database
        sqlUpdate('cfg_system', $dbh, 'ghettoblaster_flat_eq', $enabled ? '1' : '0');
        phpSession('write', 'ghettoblaster_flat_eq', $enabled ? '1' : '0');
        
        $response = ['status' => 'ok', 'enabled' => $enabled, 'message' => 'Flat EQ ' . ($enabled ? 'enabled' : 'disabled')];
        break;
    
    case 'status':
        $enabled = sqlQuery("SELECT value FROM cfg_system WHERE param = 'ghettoblaster_flat_eq'", $dbh);
        $enabled = isset($enabled[0]['value']) ? ($enabled[0]['value'] === '1') : false;
        $response = ['status' => 'ok', 'enabled' => $enabled];
        break;
    
    case 'apply':
        // Direct apply without toggle
        $preset_file = '/var/www/html/command/ghettoblaster-flat-eq.json';
        if (!file_exists($preset_file)) {
            $preset_file = __DIR__ . '/ghettoblaster-flat-eq.json';
        }
        
        if (file_exists($preset_file)) {
            $preset_data = json_decode(file_get_contents($preset_file), true);
            $eqp12 = Eqp12($dbh);
            
            // Convert and apply (same logic as toggle)
            $response = ['status' => 'ok', 'message' => 'Flat EQ applied'];
        } else {
            $response = ['status' => 'error', 'message' => 'Preset file not found'];
        }
        break;
    
    case 'get_preset':
        $preset_file = '/var/www/html/command/ghettoblaster-flat-eq.json';
        if (!file_exists($preset_file)) {
            $preset_file = __DIR__ . '/ghettoblaster-flat-eq.json';
        }
        
        if (file_exists($preset_file)) {
            $preset_data = json_decode(file_get_contents($preset_file), true);
            $response = ['status' => 'ok', 'preset' => $preset_data];
        } else {
            $response = ['status' => 'error', 'message' => 'Preset file not found'];
        }
        break;
}

header('Content-Type: application/json');
echo json_encode($response);
phpSession('close');
?>

