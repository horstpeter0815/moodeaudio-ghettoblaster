<?php
// Quick Deployment Script - Copy this entire file content
// Save as: /var/www/html/deploy-now.php
// Access: https://10.10.11.39:8443/deploy-now.php

$deploy_dir = '/boot/moode_deploy';
$web_root = '/var/www/html';

header('Content-Type: text/html; charset=utf-8');
?>
<!DOCTYPE html>
<html>
<head>
    <title>Deploy Files</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .success { color: green; font-weight: bold; }
        .error { color: red; font-weight: bold; }
        pre { background: #fff; padding: 10px; border: 1px solid #ddd; }
        button { padding: 10px 20px; background: #d32f2f; color: white; border: none; cursor: pointer; font-size: 16px; }
    </style>
</head>
<body>
    <h1>moOde Deployment</h1>
    <?php
    if (isset($_POST['deploy'])) {
        $results = [];
        
        // 1. Delete index.html
        if (file_exists("$web_root/index.html")) {
            if (unlink("$web_root/index.html")) {
                $results[] = "✓ Deleted index.html";
            } else {
                $results[] = "✗ Failed to delete index.html (try: sudo rm /var/www/html/index.html)";
            }
        }
        
        // 2. Copy test-wizard files
        if (is_dir("$deploy_dir/test-wizard")) {
            $target = "$web_root/test-wizard";
            if (!is_dir($target)) mkdir($target, 0755, true);
            
            $files = ['index-simple.html', 'wizard-functions.js', 'snd-config.html'];
            foreach ($files as $file) {
                $src = "$deploy_dir/test-wizard/$file";
                $dst = "$target/$file";
                if (file_exists($src)) {
                    if (copy($src, $dst)) {
                        chmod($dst, 0644);
                        $results[] = "✓ Copied test-wizard/$file";
                    } else {
                        $results[] = "✗ Failed to copy test-wizard/$file";
                    }
                }
            }
        }
        
        // 3. Copy room-correction-wizard.php
        if (file_exists("$deploy_dir/command/room-correction-wizard.php")) {
            $target = "$web_root/command";
            if (!is_dir($target)) mkdir($target, 0755, true);
            
            $src = "$deploy_dir/command/room-correction-wizard.php";
            $dst = "$target/room-correction-wizard.php";
            if (copy($src, $dst)) {
                chmod($dst, 0644);
                $results[] = "✓ Copied room-correction-wizard.php";
            } else {
                $results[] = "✗ Failed to copy room-correction-wizard.php";
            }
        }
        
        echo "<h2>Results:</h2><pre>";
        foreach ($results as $r) echo $r . "\n";
        echo "</pre>";
        
        if (strpos(implode('', $results), '✗') === false) {
            echo "<p class='success'>✓ Deployment Complete!</p>";
            echo "<p><a href='/'>Access Player</a> | <a href='/test-wizard/index-simple.html'>Access Wizard</a></p>";
        }
    } else {
        echo "<p>This script will copy files from <code>$deploy_dir</code> to <code>$web_root</code></p>";
        echo "<form method='POST'><button type='submit' name='deploy'>Deploy Now</button></form>";
    }
    ?>
</body>
</html>

