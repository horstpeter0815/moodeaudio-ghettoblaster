<?php
// DEPLOY VIA BROWSER - Copy this entire file content
// Save as: /var/www/html/deploy.php
// Access: https://10.10.11.39:8443/deploy.php

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
        pre { background: #fff; padding: 10px; border: 1px solid #ddd; overflow-x: auto; }
        button { padding: 10px 20px; background: #d32f2f; color: white; border: none; cursor: pointer; font-size: 16px; margin: 10px 0; }
        button:hover { background: #b71c1c; }
        .code { background: #f0f0f0; padding: 15px; border-left: 4px solid #d32f2f; margin: 10px 0; font-family: monospace; white-space: pre-wrap; }
    </style>
</head>
<body>
    <h1>moOde Deployment Tool</h1>
    <?php
    if (isset($_POST['deploy'])) {
        $results = [];
        $errors = [];
        
        // 1. Delete index.html (fix redirect)
        if (file_exists("$web_root/index.html")) {
            if (@unlink("$web_root/index.html")) {
                $results[] = "✓ Deleted index.html (redirect fix)";
            } else {
                $errors[] = "✗ Failed to delete index.html (may need sudo)";
            }
        } else {
            $results[] = "✓ index.html does not exist (already fixed)";
        }
        
        // 2. Copy test-wizard files
        if (is_dir("$deploy_dir/test-wizard")) {
            $target = "$web_root/test-wizard";
            if (!is_dir($target)) {
                @mkdir($target, 0755, true);
            }
            
            $files = ['index-simple.html', 'wizard-functions.js', 'snd-config.html'];
            foreach ($files as $file) {
                $src = "$deploy_dir/test-wizard/$file";
                $dst = "$target/$file";
                if (file_exists($src)) {
                    if (@copy($src, $dst)) {
                        @chmod($dst, 0644);
                        $results[] = "✓ Copied test-wizard/$file";
                    } else {
                        $errors[] = "✗ Failed to copy test-wizard/$file";
                    }
                } else {
                    $errors[] = "✗ Source file not found: test-wizard/$file";
                }
            }
        } else {
            $errors[] = "✗ Deployment directory not found: $deploy_dir/test-wizard";
        }
        
        // 3. Copy room-correction-wizard.php
        if (file_exists("$deploy_dir/command/room-correction-wizard.php")) {
            $target = "$web_root/command";
            if (!is_dir($target)) {
                @mkdir($target, 0755, true);
            }
            
            $src = "$deploy_dir/command/room-correction-wizard.php";
            $dst = "$target/room-correction-wizard.php";
            if (@copy($src, $dst)) {
                @chmod($dst, 0644);
                $results[] = "✓ Copied room-correction-wizard.php";
            } else {
                $errors[] = "✗ Failed to copy room-correction-wizard.php";
            }
        } else {
            $errors[] = "✗ Source file not found: command/room-correction-wizard.php";
        }
        
        // Show results
        echo "<h2>Deployment Results:</h2>";
        echo "<pre>";
        foreach ($results as $r) echo $r . "\n";
        foreach ($errors as $e) echo $e . "\n";
        echo "</pre>";
        
        if (empty($errors)) {
            echo "<p class='success'>✓ Deployment Complete!</p>";
            echo "<p><strong>Next steps:</strong></p>";
            echo "<ul>";
            echo "<li><a href='/'>Access moOde Player</a></li>";
            echo "<li><a href='/test-wizard/index-simple.html'>Access Room Correction Wizard</a></li>";
            echo "</ul>";
        } else {
            echo "<p class='error'>⚠ Some errors occurred. You may need to run with sudo privileges.</p>";
            echo "<p>Try accessing via SSH and run:</p>";
            echo "<div class='code'>sudo cp -r /boot/moode_deploy/test-wizard /var/www/html/<br>sudo cp /boot/moode_deploy/command/room-correction-wizard.php /var/www/html/command/<br>sudo rm /var/www/html/index.html</div>";
        }
    } else {
        // Show instructions
        echo "<p>This tool will deploy files from <code>$deploy_dir</code> to <code>$web_root</code></p>";
        echo "<p><strong>What will be deployed:</strong></p>";
        echo "<ul>";
        echo "<li>Delete <code>index.html</code> (fix redirect issue)</li>";
        echo "<li>Copy <code>test-wizard/</code> files</li>";
        echo "<li>Copy <code>room-correction-wizard.php</code></li>";
        echo "</ul>";
        echo "<form method='POST'>";
        echo "<button type='submit' name='deploy'>Deploy Now</button>";
        echo "</form>";
        
        // Show current status
        echo "<h2>Current Status:</h2>";
        echo "<pre>";
        echo "Deploy directory exists: " . (is_dir($deploy_dir) ? "✓ Yes" : "✗ No") . "\n";
        echo "Web root exists: " . (is_dir($web_root) ? "✓ Yes" : "✗ No") . "\n";
        echo "index.html exists: " . (file_exists("$web_root/index.html") ? "⚠ Yes (will be deleted)" : "✓ No (already fixed)") . "\n";
        echo "test-wizard exists: " . (is_dir("$web_root/test-wizard") ? "✓ Yes" : "✗ No") . "\n";
        echo "room-correction-wizard.php exists: " . (file_exists("$web_root/command/room-correction-wizard.php") ? "✓ Yes" : "✗ No") . "\n";
        echo "</pre>";
    }
    ?>
</body>
</html>

