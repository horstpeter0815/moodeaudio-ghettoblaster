<?php
/*
 * Web-based Deployment Script
 * Upload this file to /var/www/html/ and access via browser
 * Usage: https://10.10.11.39:8443/deploy-via-web.php
 */

// Security check - only allow from local network
$allowed_ips = ['10.10.11.39', '127.0.0.1', '::1'];
$client_ip = $_SERVER['REMOTE_ADDR'] ?? '';
if (!in_array($client_ip, $allowed_ips) && !str_starts_with($client_ip, '10.10.11.')) {
    die('Access denied');
}

$deploy_dir = '/boot/moode_deploy';
$web_root = '/var/www/html';

echo "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Deploy Files</title>";
echo "<style>body{font-family:Arial,sans-serif;margin:20px;background:#f5f5f5;}";
echo ".success{color:green;}.error{color:red;}.warning{color:orange;}";
echo "pre{background:#fff;padding:10px;border:1px solid #ddd;border-radius:4px;}</style></head><body>";
echo "<h1>moOde Deployment</h1>";

if (isset($_POST['deploy'])) {
    $errors = [];
    $success = [];
    
    // Check if deploy directory exists
    if (!is_dir($deploy_dir)) {
        $errors[] = "Deployment directory not found: $deploy_dir";
    } else {
        $success[] = "✓ Deployment directory found: $deploy_dir";
        
        // 1. Fix index.html redirect
        if (file_exists("$deploy_dir/fix-index-redirect.php")) {
            if (copy("$deploy_dir/fix-index-redirect.php", "$web_root/fix-index-redirect.php")) {
                chmod("$web_root/fix-index-redirect.php", 0644);
                chown("$web_root/fix-index-redirect.php", "www-data");
                $success[] = "✓ fix-index-redirect.php copied";
            } else {
                $errors[] = "✗ Failed to copy fix-index-redirect.php";
            }
        }
        
        // Delete index.html if exists
        if (file_exists("$web_root/index.html")) {
            if (unlink("$web_root/index.html")) {
                $success[] = "✓ index.html deleted (redirect fixed)";
            } else {
                $errors[] = "✗ Failed to delete index.html (may need sudo)";
            }
        }
        
        // 2. Copy test-wizard files
        if (is_dir("$deploy_dir/test-wizard")) {
            $target_dir = "$web_root/test-wizard";
            if (!is_dir($target_dir)) {
                mkdir($target_dir, 0755, true);
            }
            
            $files = glob("$deploy_dir/test-wizard/*");
            foreach ($files as $file) {
                $filename = basename($file);
                $target = "$target_dir/$filename";
                if (copy($file, $target)) {
                    chmod($target, 0644);
                    chown($target, "www-data");
                    $success[] = "✓ test-wizard/$filename copied";
                } else {
                    $errors[] = "✗ Failed to copy test-wizard/$filename";
                }
            }
        }
        
        // 3. Copy room-correction-wizard.php
        if (file_exists("$deploy_dir/command/room-correction-wizard.php")) {
            $target_dir = "$web_root/command";
            if (!is_dir($target_dir)) {
                mkdir($target_dir, 0755, true);
            }
            
            $target = "$target_dir/room-correction-wizard.php";
            if (copy("$deploy_dir/command/room-correction-wizard.php", $target)) {
                chmod($target, 0644);
                chown($target, "www-data");
                $success[] = "✓ room-correction-wizard.php copied";
            } else {
                $errors[] = "✗ Failed to copy room-correction-wizard.php";
            }
        }
    }
    
    // Display results
    if (!empty($success)) {
        echo "<h2 class='success'>Success:</h2><ul>";
        foreach ($success as $msg) {
            echo "<li class='success'>$msg</li>";
        }
        echo "</ul>";
    }
    
    if (!empty($errors)) {
        echo "<h2 class='error'>Errors:</h2><ul>";
        foreach ($errors as $msg) {
            echo "<li class='error'>$msg</li>";
        }
        echo "</ul>";
        echo "<p class='warning'>Some operations may require sudo. Try running via SSH or use the deploy-on-moode.sh script.</p>";
    }
    
    if (empty($errors)) {
        echo "<h2 class='success'>✓ Deployment Complete!</h2>";
        echo "<p><a href='/'>Access Player</a> | <a href='/test-wizard/index-simple.html'>Access Wizard</a></p>";
    }
} else {
    // Show current status
    echo "<h2>Current Status</h2>";
    echo "<pre>";
    echo "Deploy directory: $deploy_dir\n";
    echo "Exists: " . (is_dir($deploy_dir) ? "YES" : "NO") . "\n\n";
    
    if (is_dir($deploy_dir)) {
        echo "Files in deploy directory:\n";
        $files = glob("$deploy_dir/**/*", GLOB_BRACE);
        foreach ($files as $file) {
            if (is_file($file)) {
                echo "  " . str_replace($deploy_dir, '', $file) . "\n";
            }
        }
    }
    
    echo "\nWeb root: $web_root\n";
    echo "index.html exists: " . (file_exists("$web_root/index.html") ? "YES (will be deleted)" : "NO") . "\n";
    echo "</pre>";
    
    echo "<form method='POST'>";
    echo "<button type='submit' name='deploy' style='padding:10px 20px;background:#d32f2f;color:white;border:none;cursor:pointer;font-size:16px;'>Deploy Files</button>";
    echo "</form>";
    echo "<p class='warning'>Note: Some operations may require sudo permissions. If deployment fails, use SSH or the deploy-on-moode.sh script.</p>";
}

echo "</body></html>";
?>

