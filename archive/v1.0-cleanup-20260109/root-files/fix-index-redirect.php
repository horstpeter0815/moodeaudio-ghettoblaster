<?php
/*
 * Fix index.html redirect issue
 * Upload this file to moOde and access it via browser
 * Usage: https://10.10.11.39:8443/fix-index-redirect.php
 */

// Security check - only allow from local network
$allowed_ips = ['10.10.11.39', '127.0.0.1', '::1'];
$client_ip = $_SERVER['REMOTE_ADDR'] ?? '';
if (!in_array($client_ip, $allowed_ips) && !str_starts_with($client_ip, '10.10.11.')) {
    die('Access denied');
}

$index_file = '/var/www/html/index.html';
$backup_file = '/var/www/html/index.html.backup';

echo "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Fix Index Redirect</title></head><body>";
echo "<h1>Fix Index.html Redirect</h1>";

if (isset($_POST['fix'])) {
    if (file_exists($index_file)) {
        // Backup existing file
        if (copy($index_file, $backup_file)) {
            echo "<p style='color: green;'>✓ Backup created: $backup_file</p>";
        }
        
        // Delete or rename index.html
        if (unlink($index_file)) {
            echo "<p style='color: green;'>✓ index.html deleted successfully!</p>";
            echo "<p>You can now access the player at: <a href='/index.php'>https://10.10.11.39:8443/index.php</a></p>";
        } else {
            echo "<p style='color: red;'>✗ Failed to delete index.html. Check permissions.</p>";
        }
    } else {
        echo "<p style='color: orange;'>index.html does not exist. Nothing to fix.</p>";
    }
} else {
    // Show current status
    if (file_exists($index_file)) {
        $content = file_get_contents($index_file);
        echo "<h2>Current index.html content:</h2>";
        echo "<pre style='background: #f0f0f0; padding: 10px;'>" . htmlspecialchars($content) . "</pre>";
        echo "<form method='POST'>";
        echo "<button type='submit' name='fix' style='padding: 10px 20px; background: #d32f2f; color: white; border: none; cursor: pointer;'>Delete index.html (Fix Redirect)</button>";
        echo "</form>";
    } else {
        echo "<p style='color: green;'>✓ index.html does not exist. No redirect issue.</p>";
    }
}

echo "</body></html>";
?>

