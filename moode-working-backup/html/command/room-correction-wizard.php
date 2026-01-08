<?php
/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Copyright 2025 Ghettoblaster Custom Build
 * Room Correction Wizard - Roon-inspiriert
 */

require_once __DIR__ . '/../inc/common.php';
require_once __DIR__ . '/../inc/session.php';
require_once __DIR__ . '/../inc/sql.php';

phpSession('open');
$dbh = sqlConnect();

// Logging for debugging
function logWizard($msg) {
    workerLog("Room Correction Wizard: " . $msg);
}

// Security: Validate command
$allowed_commands = ['start_wizard', 'upload_measurement', 'analyze_measurement', 
                     'generate_filter', 'apply_filter', 'generate_peq', 'apply_peq',
                     'list_presets', 'toggle_ab_test',
                     'start_pink_noise', 'stop_pink_noise', 'get_pink_noise_status',
                     'process_frequency_response', 'import_roon_eq', 'deploy_files'];
$cmd = $_POST['cmd'] ?? '';
if (!in_array($cmd, $allowed_commands)) {
    header('Content-Type: application/json');
    echo json_encode(['status' => 'error', 'message' => 'Invalid command']);
    phpSession('close');
    exit;
}

$response = ['status' => 'error', 'message' => 'Invalid command'];

switch ($cmd) {
    case 'start_wizard':
        // Initialize wizard session
        $_SESSION['room_correction_wizard'] = true;
        $_SESSION['wizard_step'] = 1;
        $response = ['status' => 'ok', 'step' => 1, 'message' => 'Wizard started'];
        break;
    
    case 'upload_measurement':
        // Handle measurement file upload with security checks
        $measurement_file = $_FILES['measurement'] ?? null;
        if ($measurement_file && $measurement_file['error'] === UPLOAD_ERR_OK) {
            // Security: Validate file type
            $allowed_types = ['audio/wav', 'audio/wave', 'audio/x-wav'];
            $finfo = finfo_open(FILEINFO_MIME_TYPE);
            $mime_type = finfo_file($finfo, $measurement_file['tmp_name']);
            finfo_close($finfo);
            
            // Security: Check file extension
            $file_ext = strtolower(pathinfo($measurement_file['name'], PATHINFO_EXTENSION));
            if (!in_array($file_ext, ['wav', 'wave']) || !in_array($mime_type, $allowed_types)) {
                $response = ['status' => 'error', 'message' => 'Invalid file type. Only WAV files are allowed.'];
                break;
            }
            
            // Security: Check file size (max 50MB)
            $max_size = 50 * 1024 * 1024; // 50MB
            if ($measurement_file['size'] > $max_size) {
                $response = ['status' => 'error', 'message' => 'File too large. Maximum size is 50MB.'];
                break;
            }
            
            $upload_dir = '/var/lib/camilladsp/measurements/';
            if (!is_dir($upload_dir)) {
                mkdir($upload_dir, 0755, true);
            }
            
            // Security: Sanitize filename
            $filename = 'measurement_' . time() . '_' . preg_replace('/[^a-zA-Z0-9_-]/', '', pathinfo($measurement_file['name'], PATHINFO_FILENAME)) . '.wav';
            $target_path = $upload_dir . $filename;
            
            if (move_uploaded_file($measurement_file['tmp_name'], $target_path)) {
                chmod($target_path, 0644);
                $_SESSION['measurement_file'] = $target_path;
                $response = ['status' => 'ok', 'file' => $target_path, 'message' => 'Measurement uploaded'];
            } else {
                $response = ['status' => 'error', 'message' => 'Failed to save measurement'];
            }
        } else {
            $error_msg = 'No measurement file received';
            if ($measurement_file && $measurement_file['error'] !== UPLOAD_ERR_OK) {
                $error_msg = 'Upload error: ' . $measurement_file['error'];
            }
            $response = ['status' => 'error', 'message' => $error_msg];
        }
        break;
    
    case 'analyze_measurement':
        $measurement_file = $_SESSION['measurement_file'] ?? '';
        if (empty($measurement_file) || !file_exists($measurement_file)) {
            $response = ['status' => 'error', 'message' => 'No measurement file found'];
            break;
        }
        
        // Analyze frequency response using sox or python script
        $analysis_script = '/usr/local/bin/analyze-measurement.py';
        if (file_exists($analysis_script)) {
            $result = sysCmd("python3 $analysis_script " . escapeshellarg($measurement_file));
            if (!empty($result)) {
                $frequency_response = json_decode($result[0], true);
                $_SESSION['frequency_response'] = $frequency_response;
                $response = ['status' => 'ok', 'frequency_response' => $frequency_response];
            } else {
                $response = ['status' => 'error', 'message' => 'Analysis failed'];
            }
        } else {
            $response = ['status' => 'error', 'message' => 'Analysis script not found'];
        }
        break;
    
    case 'generate_filter':
        $target_curve = $_POST['target_curve'] ?? 'flat';
        $frequency_response = $_SESSION['frequency_response'] ?? null;
        
        if (!$frequency_response) {
            $response = ['status' => 'error', 'message' => 'No frequency response data'];
            break;
        }
        
        // Generate FIR filter using python script
        $generate_script = '/usr/local/bin/generate-fir-filter.py';
        if (file_exists($generate_script)) {
            $filter_name = 'room_correction_' . date('Y-m-d_H-i-s');
            $filter_file = '/var/lib/camilladsp/convolution/' . $filter_name . '.wav';
            $filter_dir = dirname($filter_file);
            if (!is_dir($filter_dir)) {
                mkdir($filter_dir, 0755, true);
            }
            
            $freq_json = json_encode($frequency_response);
            $result = sysCmd("python3 $generate_script " . 
                           escapeshellarg($freq_json) . " " . 
                           escapeshellarg($target_curve) . " " . 
                           escapeshellarg($filter_file));
            
            if (file_exists($filter_file)) {
                // Save preset to database
                sqlUpdate('cfg_system', $dbh, 'room_correction_preset', $filter_name);
                $_SESSION['room_correction_preset'] = $filter_name;
                $response = ['status' => 'ok', 'filter_file' => $filter_file, 'preset_name' => $filter_name];
            } else {
                $response = ['status' => 'error', 'message' => 'Filter generation failed'];
            }
        } else {
            $response = ['status' => 'error', 'message' => 'Filter generation script not found'];
        }
        break;
    
    case 'generate_peq':
        // Generate PEQ config from frequency response data
        $frequency_response = $_SESSION['frequency_response'] ?? null;
        $preset_name = $_POST['preset_name'] ?? 'room_correction_peq_' . date('Y-m-d_H-i-s');
        $num_bands = intval($_POST['num_bands'] ?? 12);
        
        if (!$frequency_response || !isset($frequency_response['correction'])) {
            $response = ['status' => 'error', 'message' => 'No frequency response data available'];
            break;
        }
        
        // Security: Validate preset name
        if (preg_match('/[\/\.\.]/', $preset_name)) {
            $response = ['status' => 'error', 'message' => 'Invalid preset name'];
            break;
        }
        
        // Save frequency response to temporary JSON file for Python script
        $temp_json = '/tmp/freq_response_' . time() . '_' . rand(1000, 9999) . '.json';
        file_put_contents($temp_json, json_encode($frequency_response));
        
        // Generate CamillaDSP config (Biquad filters) using Python script
        // Note: PEQ is used to FIND the settings, but output is CamillaDSP Biquad filters
        $config_file = '/usr/share/camilladsp/configs/' . $preset_name . '.yml';
        $samplerate = $_SESSION['samplerate'] ?? 44100;
        $cardnum = $_SESSION['cardnum'] ?? 0;
        
        $generate_script = '/usr/local/bin/generate-camilladsp-eq.py';
        if (!file_exists($generate_script)) {
            $response = ['status' => 'error', 'message' => 'CamillaDSP generation script not found'];
            if (file_exists($temp_json)) {
                unlink($temp_json);
            }
            break;
        }
        
        $result = sysCmd("python3 $generate_script " . 
                        escapeshellarg($temp_json) . " " . 
                        escapeshellarg($config_file) . " " . 
                        $num_bands . " " . 
                        $samplerate . " " .
                        $cardnum);
        
        // Clean up temp file
        if (file_exists($temp_json)) {
            unlink($temp_json);
        }
        
        if (file_exists($config_file)) {
            sysCmd("sudo chmod a+rw \"$config_file\"");
            $_SESSION['room_correction_peq_preset'] = $preset_name;
            logWizard("Generated PEQ config: $preset_name with $num_bands bands");
            $response = ['status' => 'ok', 'config_file' => $config_file, 'preset_name' => $preset_name];
        } else {
            $response = ['status' => 'error', 'message' => 'PEQ generation failed', 'output' => implode("\n", $result)];
        }
        break;
    
    case 'apply_peq':
        // Apply PEQ config via CamillaDSP
        $preset_name = $_POST['preset_name'] ?? '';
        if (empty($preset_name)) {
            $preset_name = $_SESSION['room_correction_peq_preset'] ?? '';
        }
        
        if (empty($preset_name)) {
            $response = ['status' => 'error', 'message' => 'No PEQ preset specified'];
            break;
        }
        
        // Security: Validate preset name
        if (preg_match('/[\/\.\.]/', $preset_name)) {
            $response = ['status' => 'error', 'message' => 'Invalid preset name'];
            break;
        }
        
        $config_file = '/usr/share/camilladsp/configs/' . $preset_name . '.yml';
        if (!file_exists($config_file)) {
            $response = ['status' => 'error', 'message' => 'PEQ config file not found: ' . $preset_name];
            break;
        }
        
        // Apply PEQ config via CamillaDSP
        require_once __DIR__ . '/../inc/cdsp.php';
        $camilladsp_mode = $_SESSION['camilladsp'] ?? 'off';
        $cdsp = new CamillaDsp($camilladsp_mode, $_SESSION['cardnum'] ?? 0, $_SESSION['camilladsp_quickconv'] ?? ',,,');
        
        // Select the PEQ config
        $cdsp->selectConfig($preset_name . '.yml');
        phpSession('write', 'camilladsp', $preset_name . '.yml');
        
        // Set playback device
        $cdsp->setPlaybackDevice($_SESSION['cardnum'] ?? 0, $_SESSION['alsa_output_mode'] ?? 'plughw');
        
        // Reload CamillaDSP config
        $cdsp->reloadConfig();
        
        sqlUpdate('cfg_system', $dbh, 'room_correction_active', '1');
        sqlUpdate('cfg_system', $dbh, 'room_correction_preset', $preset_name);
        sqlUpdate('cfg_system', $dbh, 'camilladsp', $preset_name . '.yml');
        phpSession('write', 'room_correction_active', '1');
        phpSession('write', 'room_correction_preset', $preset_name);
        
        logWizard("Applied PEQ config: $preset_name");
        $response = ['status' => 'ok', 'preset' => $preset_name, 'message' => 'PEQ filter applied successfully'];
        break;
    
    case 'apply_filter':
        // Legacy: Apply FIR convolution filter (keep for backward compatibility)
        $preset_name = $_POST['preset_name'] ?? '';
        if (empty($preset_name)) {
            $preset_name = $_SESSION['room_correction_preset'] ?? '';
        }
        
        if (empty($preset_name)) {
            $response = ['status' => 'error', 'message' => 'No preset specified'];
            break;
        }
        
        // Security: Validate preset name (prevent path traversal)
        if (preg_match('/[\/\.\.]/', $preset_name)) {
            $response = ['status' => 'error', 'message' => 'Invalid preset name'];
            break;
        }
        
        // Apply filter via CamillaDSP
        $filter_file = '/var/lib/camilladsp/convolution/' . $preset_name . '.wav';
        if (!file_exists($filter_file)) {
            $response = ['status' => 'error', 'message' => 'Filter file not found: ' . $preset_name];
            break;
        }
        
        // Copy filter to CamillaDSP coeffs directory
        $coeff_file = '/usr/share/camilladsp/coeffs/room_correction_' . $preset_name . '.wav';
        if (!copy($filter_file, $coeff_file)) {
            $response = ['status' => 'error', 'message' => 'Failed to copy filter to CamillaDSP coeffs'];
            break;
        }
        sysCmd("sudo chmod a+r \"$coeff_file\"");
        
        // Setup Quick Convolution Config
        require_once __DIR__ . '/../inc/cdsp.php';
        $camilladsp_mode = $_SESSION['camilladsp'] ?? 'off';
        $cdsp = new CamillaDsp($camilladsp_mode, $_SESSION['cardnum'] ?? 0, $_SESSION['camilladsp_quickconv'] ?? ',,,');
        
        // Set Quick Convolution parameters (format: "gain,irl,irr,irtype")
        $quick_conv_config = '0,room_correction_' . $preset_name . '.wav,room_correction_' . $preset_name . '.wav,WAVE';
        $cdsp->setQuickConvolutionConfig($quick_conv_config);
        phpSession('write', 'camilladsp_quickconv', $quick_conv_config);
        
        // Write Quick Convolution config file
        $cdsp->writeQuickConvolutionConfig();
        
        // Switch to Quick Convolution mode
        $cdsp->selectConfig('__quick_convolution__.yml');
        phpSession('write', 'camilladsp', '__quick_convolution__.yml');
        
        // Set playback device
        $cdsp->setPlaybackDevice($_SESSION['cardnum'] ?? 0, $_SESSION['alsa_output_mode'] ?? 'plughw');
        
        // Reload CamillaDSP config
        $cdsp->reloadConfig();
        
        sqlUpdate('cfg_system', $dbh, 'room_correction_active', '1');
        sqlUpdate('cfg_system', $dbh, 'room_correction_preset', $preset_name);
        sqlUpdate('cfg_system', $dbh, 'camilladsp', '__quick_convolution__.yml');
        phpSession('write', 'room_correction_active', '1');
        phpSession('write', 'room_correction_preset', $preset_name);
        
        $response = ['status' => 'ok', 'preset' => $preset_name, 'message' => 'Filter applied successfully'];
        break;
    
    case 'list_presets':
        $presets_dir = '/var/lib/camilladsp/convolution/';
        $presets = [];
        if (is_dir($presets_dir)) {
            $files = glob($presets_dir . '*.wav');
            foreach ($files as $file) {
                $presets[] = [
                    'name' => basename($file, '.wav'),
                    'file' => $file,
                    'size' => filesize($file),
                    'modified' => filemtime($file)
                ];
            }
        }
        $response = ['status' => 'ok', 'presets' => $presets];
        break;
    
    case 'toggle_ab_test':
        $enabled = $_POST['enabled'] ?? 'false';
        sqlUpdate('cfg_system', $dbh, 'room_correction_ab_test', $enabled);
        $response = ['status' => 'ok', 'enabled' => $enabled === 'true'];
        break;
    
    case 'start_pink_noise':
        // Check if already running
        $pid_file = '/var/run/pink_noise.pid';
        if (file_exists($pid_file)) {
            $pid = trim(file_get_contents($pid_file));
            if ($pid && posix_kill($pid, 0)) {
                // Process still running
                $response = ['status' => 'ok', 'message' => 'Pink noise already playing', 'pid' => $pid];
                break;
            }
        }
        
        // Get current volume and warn if too loud (optional check)
        // Note: Pink noise uses ALSA directly, not MPD volume, so it plays at hardware/system volume
        // User should set volume to comfortable level BEFORE starting wizard
        
        // Start pink noise playback (continuous, infinite loop)
        // Use speaker-test for pink noise generation
        // -l 0 means infinite loop (continuous playback)
        // Note: Volume level is controlled by system/ALSA volume, not MPD
        // IMPORTANT: User should set volume to comfortable level before starting measurement
        $cardnum = $_SESSION['cardnum'] ?? 0;
        $cmd = "speaker-test -t pink -c 2 -r 44100 -l 0 -D plughw:$cardnum,0 > /dev/null 2>&1 & echo $!";
        $pid = trim(shell_exec($cmd));
        
        if ($pid && is_numeric($pid)) {
            file_put_contents($pid_file, $pid);
            logWizard("Started pink noise playback, PID: $pid (Note: Volume should be set to comfortable level before starting)");
            $response = ['status' => 'ok', 'message' => 'Pink noise started', 'pid' => $pid];
        } else {
            $response = ['status' => 'error', 'message' => 'Failed to start pink noise'];
        }
        break;
    
    case 'stop_pink_noise':
        $pid_file = '/var/run/pink_noise.pid';
        if (file_exists($pid_file)) {
            $pid = trim(file_get_contents($pid_file));
            if ($pid && is_numeric($pid)) {
                // Kill the process
                posix_kill($pid, SIGTERM);
                // Also kill any remaining speaker-test processes
                sysCmd("pkill -f 'speaker-test.*pink'");
                unlink($pid_file);
                logWizard("Stopped pink noise playback, PID: $pid");
                $response = ['status' => 'ok', 'message' => 'Pink noise stopped'];
            } else {
                $response = ['status' => 'error', 'message' => 'Invalid PID'];
            }
        } else {
            // Try to kill any running pink noise anyway
            sysCmd("pkill -f 'speaker-test.*pink'");
            $response = ['status' => 'ok', 'message' => 'Pink noise stopped (was not running)'];
        }
        break;
    
    case 'get_pink_noise_status':
        $pid_file = '/var/run/pink_noise.pid';
        $is_playing = false;
        $pid = null;
        
        if (file_exists($pid_file)) {
            $pid = trim(file_get_contents($pid_file));
            if ($pid && is_numeric($pid) && posix_kill($pid, 0)) {
                $is_playing = true;
            } else {
                // PID file exists but process is dead, clean up
                if (file_exists($pid_file)) {
                    unlink($pid_file);
                }
            }
        }
        
        $response = ['status' => 'ok', 'playing' => $is_playing, 'pid' => $pid];
        break;
    
    case 'process_frequency_response':
        // Receive frequency response data from frontend (sent when user clicks Apply)
        $freq_data = $_POST['frequency_response'] ?? null;
        
        if (!$freq_data) {
            $response = ['status' => 'error', 'message' => 'No frequency response data received'];
            break;
        }
        
        // Validate and decode JSON
        if (is_string($freq_data)) {
            $freq_data = json_decode($freq_data, true);
        }
        
        if (!is_array($freq_data) || !isset($freq_data['frequencies']) || !isset($freq_data['magnitude'])) {
            $response = ['status' => 'error', 'message' => 'Invalid frequency response format'];
            break;
        }
        
        // Ambient noise has already been subtracted in the frontend, but we store it for reference
        $ambient_noise = $freq_data['ambient_noise'] ?? null;
        if ($ambient_noise) {
            $_SESSION['ambient_noise'] = $ambient_noise;
            logWizard("Ambient noise measurement stored: " . count($ambient_noise) . " points");
        }
        
        // Store in session for EQ generation
        $_SESSION['frequency_response'] = $freq_data;
        
        // Calculate target curve (flat by default)
        $target_curve = $_POST['target_curve'] ?? 'flat';
        $target_response = [];
        
        // For flat target, create flat line at 0 dB
        if ($target_curve === 'flat') {
            foreach ($freq_data['frequencies'] as $freq) {
                $target_response[] = 0.0; // 0 dB target
            }
        } else {
            // For other curves, calculate target values
            // This could be extended later for house curves, etc.
            foreach ($freq_data['frequencies'] as $freq) {
                $target_response[] = 0.0;
            }
        }
        
        // Calculate correction values (target - measured)
        // Note: magnitude already has ambient noise subtracted by frontend
        $correction = [];
        for ($i = 0; $i < count($freq_data['frequencies']); $i++) {
            $freq = $freq_data['frequencies'][$i];
            $corr_value = $target_response[$i] - $freq_data['magnitude'][$i];
            
            // Apply correction limits:
            // - Maximum 15 dB for bass range (20-35 Hz)
            // - Maximum 10 dB for all other frequencies
            if ($freq >= 20 && $freq <= 35) {
                // Bass range: limit to ±15 dB
                $corr_value = max(-15.0, min(15.0, $corr_value));
            } else {
                // All other frequencies: limit to ±10 dB
                $corr_value = max(-10.0, min(10.0, $corr_value));
            }
            
            $correction[] = $corr_value;
        }
        
        $freq_response = [
            'frequencies' => $freq_data['frequencies'],
            'magnitude' => $freq_data['magnitude'],
            'target' => $target_response,
            'correction' => $correction,
            'ambient_noise' => $ambient_noise
        ];
        
        $_SESSION['frequency_response'] = $freq_response;
        $_SESSION['target_curve'] = $target_curve;
        
        logWizard("Processed frequency response: " . count($freq_data['frequencies']) . " points");
        $response = ['status' => 'ok', 'message' => 'Frequency response processed', 
                     'frequency_response' => $freq_response];
        break;
    
    case 'import_roon_eq':
        // Import Room EQ filter file and apply it
        $filter_file = $_POST['filter_file'] ?? '';
        $preset_name = $_POST['preset_name'] ?? '';
        
        if (empty($filter_file)) {
            $response = ['status' => 'error', 'message' => 'No filter file specified'];
            break;
        }
        
        // Security: Validate file path (must be in allowed directory)
        $allowed_dir = '/var/lib/camilladsp/filters/';
        $full_path = realpath($allowed_dir . basename($filter_file));
        if (!$full_path || strpos($full_path, $allowed_dir) !== 0) {
            // Also check if it's an absolute path to the filters directory
            if (!file_exists($filter_file)) {
                $response = ['status' => 'error', 'message' => 'Filter file not found'];
                break;
            }
        } else {
            $filter_file = $full_path;
        }
        
        if (empty($preset_name)) {
            $preset_name = 'bose_wave_filters_' . date('Y-m-d_H-i-s');
        }
        
        // Security: Validate preset name
        if (preg_match('/[\/\.\.]/', $preset_name)) {
            $response = ['status' => 'error', 'message' => 'Invalid preset name'];
            break;
        }
        
        // Generate CamillaDSP config from Room EQ file
        $config_file = '/usr/share/camilladsp/configs/' . $preset_name . '.yml';
        $samplerate = $_SESSION['samplerate'] ?? 44100;
        $cardnum = $_SESSION['cardnum'] ?? 0;
        
        $import_script = '/usr/local/bin/import-roon-eq-filter.py';
        if (!file_exists($import_script)) {
            $response = ['status' => 'error', 'message' => 'Import script not found'];
            break;
        }
        
        $result = sysCmd("python3 $import_script " . 
                        escapeshellarg($filter_file) . " " . 
                        escapeshellarg($config_file) . " " . 
                        $samplerate . " " . 
                        $cardnum);
        
        if (file_exists($config_file)) {
            sysCmd("sudo chmod a+rw \"$config_file\"");
            
            // Apply the config via CamillaDSP
            require_once __DIR__ . '/../inc/cdsp.php';
            $camilladsp_mode = $_SESSION['camilladsp'] ?? 'off';
            $cdsp = new CamillaDsp($camilladsp_mode, $cardnum, $_SESSION['camilladsp_quickconv'] ?? ',,,');
            
            // Select the config
            $cdsp->selectConfig($preset_name . '.yml');
            phpSession('write', 'camilladsp', $preset_name . '.yml');
            
            // Set playback device
            $cdsp->setPlaybackDevice($cardnum, $_SESSION['alsa_output_mode'] ?? 'plughw');
            
            // Reload CamillaDSP config
            $cdsp->reloadConfig();
            
            sqlUpdate('cfg_system', $dbh, 'camilladsp', $preset_name . '.yml');
            phpSession('write', 'camilladsp', $preset_name . '.yml');
            
            logWizard("Imported and applied Room EQ filter: $preset_name from $filter_file");
            $response = ['status' => 'ok', 'preset' => $preset_name, 'config_file' => $config_file, 
                        'message' => 'Room EQ filter imported and applied successfully'];
        } else {
            $response = ['status' => 'error', 'message' => 'Failed to generate config file', 'output' => implode("\n", $result)];
        }
        break;
    
    case 'deploy_files':
        // Deploy files from /boot/moode_deploy/ to /var/www/html/
        $deploy_dir = '/boot/moode_deploy';
        $web_root = '/var/www/html';
        $results = [];
        $errors = [];
        
        // 1. Delete index.html
        if (file_exists("$web_root/index.html")) {
            if (@unlink("$web_root/index.html")) {
                $results[] = "Deleted index.html";
            } else {
                $errors[] = "Failed to delete index.html";
            }
        }
        
        // 2. Copy test-wizard files
        if (is_dir("$deploy_dir/test-wizard")) {
            $target = "$web_root/test-wizard";
            if (!is_dir($target)) @mkdir($target, 0755, true);
            foreach (['index-simple.html', 'wizard-functions.js', 'snd-config.html'] as $file) {
                $src = "$deploy_dir/test-wizard/$file";
                $dst = "$target/$file";
                if (file_exists($src)) {
                    if (@copy($src, $dst)) {
                        @chmod($dst, 0644);
                        $results[] = "Copied test-wizard/$file";
                    } else {
                        $errors[] = "Failed to copy test-wizard/$file";
                    }
                } else {
                    $errors[] = "Source not found: test-wizard/$file";
                }
            }
        } else {
            $errors[] = "Directory not found: $deploy_dir/test-wizard";
        }
        
        // 3. Copy room-correction-wizard.php
        if (file_exists("$deploy_dir/command/room-correction-wizard.php")) {
            $target = "$web_root/command";
            if (!is_dir($target)) @mkdir($target, 0755, true);
            $src = "$deploy_dir/command/room-correction-wizard.php";
            $dst = "$target/room-correction-wizard.php";
            if (@copy($src, $dst)) {
                @chmod($dst, 0644);
                $results[] = "Copied room-correction-wizard.php";
            } else {
                $errors[] = "Failed to copy room-correction-wizard.php";
            }
        } else {
            $errors[] = "Source not found: command/room-correction-wizard.php";
        }
        
        if (empty($errors)) {
            $response = ['status' => 'ok', 'message' => 'Deployment complete', 'results' => $results];
        } else {
            $response = ['status' => 'error', 'message' => 'Deployment completed with errors', 'results' => $results, 'errors' => $errors];
        }
        break;
}

header('Content-Type: application/json');
echo json_encode($response);
phpSession('close');
?>

