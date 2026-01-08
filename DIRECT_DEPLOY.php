<?php
// DIRECT DEPLOY - Simple deployment script
// Copy this file to /var/www/html/direct-deploy.php and access it via browser
// Or execute directly if already on server

$deploy_dir = '/boot/moode_deploy';
$web_root = '/var/www/html';

header('Content-Type: text/html; charset=utf-8');
?>
<!DOCTYPE html>
<html>
<head>
    <title>Direct Deploy</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .success { color: green; font-weight: bold; }
        .error { color: red; font-weight: bold; }
        pre { background: #fff; padding: 10px; border: 1px solid #ddd; }
    </style>
</head>
<body>
    <h1>Direct Deployment</h1>
    <?php
    $results = [];
    $errors = [];
    
    // 1. Delete index.html
    if (file_exists("$web_root/index.html")) {
        if (@unlink("$web_root/index.html")) {
            $results[] = "✓ Deleted index.html";
        } else {
            $errors[] = "✗ Failed to delete index.html";
        }
    } else {
        $results[] = "✓ index.html does not exist";
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
                    $results[] = "✓ Copied test-wizard/$file";
                } else {
                    $errors[] = "✗ Failed to copy test-wizard/$file";
                }
            } else {
                $errors[] = "✗ Source not found: test-wizard/$file";
            }
        }
    } else {
        $errors[] = "✗ Directory not found: $deploy_dir/test-wizard";
    }
    
    // 3. Copy room-correction-wizard.php
    if (file_exists("$deploy_dir/command/room-correction-wizard.php")) {
        $target = "$web_root/command";
        if (!is_dir($target)) @mkdir($target, 0755, true);
        $src = "$deploy_dir/command/room-correction-wizard.php";
        $dst = "$target/room-correction-wizard.php";
        if (@copy($src, $dst)) {
            @chmod($dst, 0644);
            $results[] = "✓ Copied room-correction-wizard.php";
        } else {
            $errors[] = "✗ Failed to copy room-correction-wizard.php";
        }
    } else {
        $errors[] = "✗ Source not found: command/room-correction-wizard.php";
    }
    
    echo "<h2>Deployment Results:</h2>";
    echo "<pre>";
    foreach ($results as $r) echo $r . "\n";
    foreach ($errors as $e) echo $e . "\n";
    echo "</pre>";
    
    if (empty($errors)) {
        echo "<p class='success'>✓ Deployment Complete!</p>";
        echo "<p><a href='/'>Access Player</a> | <a href='/test-wizard/index-simple.html'>Access Wizard</a></p>";
    } else {
        echo "<p class='error'>⚠ Some errors occurred. Files may need sudo permissions.</p>";
        echo "<p>Try: <code>sudo cp -r /boot/moode_deploy/test-wizard /var/www/html/ && sudo cp /boot/moode_deploy/command/room-correction-wizard.php /var/www/html/command/</code></p>";
    }
    ?>
</body>
</html>

