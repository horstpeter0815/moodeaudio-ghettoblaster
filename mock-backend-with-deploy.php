<?php
// Mock backend for room correction wizard WITH DEPLOYMENT FUNCTIONALITY
header('Content-Type: application/json');

$cmd = $_POST['cmd'] ?? '';

// NEW: Deployment command
if ($cmd === 'deploy_files') {
    $deploy_dir = '/boot/moode_deploy';
    $web_root = '/var/www/html';
    $results = [];
    
    // 1. Delete index.html
    if (file_exists("$web_root/index.html")) {
        @unlink("$web_root/index.html") && $results[] = "✓ Deleted index.html";
    }
    
    // 2. Copy test-wizard files
    if (is_dir("$deploy_dir/test-wizard")) {
        $target = "$web_root/test-wizard";
        @mkdir($target, 0755, true);
        foreach (['index-simple.html', 'wizard-functions.js', 'snd-config.html'] as $file) {
            $src = "$deploy_dir/test-wizard/$file";
            $dst = "$target/$file";
            if (file_exists($src) && @copy($src, $dst)) {
                @chmod($dst, 0644);
                $results[] = "✓ Copied test-wizard/$file";
            }
        }
    }
    
    // 3. Copy room-correction-wizard.php
    if (file_exists("$deploy_dir/command/room-correction-wizard.php")) {
        $target = "$web_root/command";
        @mkdir($target, 0755, true);
        $src = "$deploy_dir/command/room-correction-wizard.php";
        $dst = "$target/room-correction-wizard.php";
        if (@copy($src, $dst)) {
            @chmod($dst, 0644);
            $results[] = "✓ Copied room-correction-wizard.php";
        }
    }
    
    echo json_encode(['status' => 'ok', 'results' => $results]);
    exit;
}

// Original mock backend functionality
$response = [
    'status' => 'ok',
    'message' => 'Mock response for ' . $cmd
];

switch ($cmd) {
    case 'start_pink_noise':
        $response['pid'] = 12345;
        $response['message'] = 'Pink noise started (simulated)';
        break;
    case 'stop_pink_noise':
        $response['message'] = 'Pink noise stopped (simulated)';
        break;
    case 'process_frequency_response':
        $response['frequency_response'] = [
            'frequencies' => array_map(function($i) {
                return 20 * pow(20000/20, $i/99);
            }, range(0, 99)),
            'magnitude' => array_map(function() {
                return rand(-40, -20);
            }, range(0, 99)),
            'corrected_magnitude' => array_map(function() {
                return rand(-40, -20);
            }, range(0, 99)),
            'target' => array_fill(0, 100, 0),
            'correction' => array_map(function() {
                return rand(-5, 5);
            }, range(0, 99))
        ];
        break;
    case 'generate_peq':
        $response['config_file'] = '/tmp/test_config.yml';
        $response['preset_name'] = $_POST['preset_name'] ?? 'test_preset';
        break;
    case 'apply_peq':
        $response['preset'] = $_POST['preset_name'] ?? 'test_preset';
        break;
}

echo json_encode($response);
?>

