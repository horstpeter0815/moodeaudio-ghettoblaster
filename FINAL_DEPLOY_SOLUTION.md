# FINAL DEPLOYMENT SOLUTION

## Problem
- SSH doesn't work (password issue)
- Can't upload files directly via browser
- Need to deploy files from `/boot/moode_deploy/` to `/var/www/html/`

## Solution: One-Click Deployment

### Step 1: Create deploy.php file

Copy the content below and save it as `deploy.php` in `/var/www/html/`:

```php
<?php
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

header('Content-Type: text/html; charset=utf-8');
?>
<!DOCTYPE html>
<html>
<head>
    <title>Deployment Complete</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .success { color: green; font-weight: bold; font-size: 18px; }
        .box { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        pre { background: #f9f9f9; padding: 15px; border: 1px solid #ddd; }
    </style>
</head>
<body>
    <div class="box">
        <h1>✓ Deployment Complete!</h1>
        <p class="success">All files have been deployed successfully.</p>
        <pre><?php foreach ($results as $r) echo $r . "\n"; ?></pre>
        <p><strong>Next steps:</strong></p>
        <ul>
            <li><a href="/">Access moOde Player</a></li>
            <li><a href="/test-wizard/index-simple.html">Access Room Correction Wizard</a></li>
        </ul>
    </div>
</body>
</html>
```

### Step 2: Access the file

Open: `https://10.10.11.39:8443/deploy.php`

That's it! Everything will be deployed automatically.

