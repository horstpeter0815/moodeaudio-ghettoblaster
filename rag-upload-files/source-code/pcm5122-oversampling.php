<?php
/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * PCM5122 Oversampling Filter Control API
 * (C) 2025 Ghettoblaster Custom Build
 */

require_once __DIR__ . '/../inc/common.php';
require_once __DIR__ . '/../inc/session.php';
require_once __DIR__ . '/../inc/sql.php';

phpSession('open');
$dbh = sqlConnect();

header('Content-Type: application/json');

$action = $_GET['action'] ?? $_POST['action'] ?? 'get';
$cardNum = $_SESSION['cardnum'] ?? 0;

switch ($action) {
    case 'list':
        // Get available filter options
        $result = sysCmd("/usr/local/bin/pcm5122-oversampling.sh $cardNum list");
        if (!empty($result) && strpos($result[0], 'ERROR') === false) {
            $filters = explode(' ', $result[0]);
            echo json_encode([
                'status' => 'ok',
                'filters' => $filters
            ]);
        } else {
            echo json_encode([
                'status' => 'error',
                'message' => 'No oversampling controls found or not a PCM5122 device'
            ]);
        }
        break;
        
    case 'get':
        // Get current filter setting
        $result = sysCmd("/usr/local/bin/pcm5122-oversampling.sh $cardNum get");
        if (!empty($result) && strpos($result[0], 'ERROR') === false) {
            $current = trim($result[0]);
            // Read from database if available
            $dbValue = sqlRead('cfg_system', $dbh, 'pcm5122_oversampling');
            $saved = !empty($dbValue) ? $dbValue[0]['value'] : '';
            
            echo json_encode([
                'status' => 'ok',
                'current' => $current,
                'saved' => $saved
            ]);
        } else {
            echo json_encode([
                'status' => 'error',
                'message' => 'Could not read current filter setting'
            ]);
        }
        break;
        
    case 'set':
        // Set filter
        $filter = $_POST['filter'] ?? $_GET['filter'] ?? '';
        if (empty($filter)) {
            echo json_encode([
                'status' => 'error',
                'message' => 'No filter value specified'
            ]);
            break;
        }
        
        // Set via ALSA
        $result = sysCmd("/usr/local/bin/pcm5122-oversampling.sh $cardNum set \"$filter\"");
        
        if (!empty($result) && strpos($result[0], 'OK') !== false) {
            // Save to database
            sqlUpdate('cfg_system', $dbh, 'pcm5122_oversampling', $filter);
            phpSession('write', 'pcm5122_oversampling', $filter);
            
            echo json_encode([
                'status' => 'ok',
                'message' => 'Filter set successfully',
                'filter' => $filter
            ]);
        } else {
            echo json_encode([
                'status' => 'error',
                'message' => !empty($result) ? $result[0] : 'Failed to set filter'
            ]);
        }
        break;
        
    default:
        echo json_encode([
            'status' => 'error',
            'message' => 'Invalid action'
        ]);
        break;
}

