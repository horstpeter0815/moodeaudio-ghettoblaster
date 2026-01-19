<?php
// Debug logging endpoint
$logFile = '/tmp/moode-debug.log';
$data = file_get_contents('php://input');
$entry = date('[Y-m-d H:i:s] ') . $data . "\n";
file_put_contents($logFile, $entry, FILE_APPEND | LOCK_EX);
echo json_encode(['status' => 'ok']);
?>
