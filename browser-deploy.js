// Browser-based Deployment Script
// Copy and paste this entire script into the browser console on https://10.10.11.39:8443/
// Then press Enter to execute

(async function() {
    console.log('Starting deployment...');
    
    // Create deployment PHP script
    const deployScript = `<?php
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

header('Content-Type: application/json');
echo json_encode(['status' => 'ok', 'results' => $results]);
?>`;

    // Try to create deploy.php via fetch (won't work without server support)
    // Instead, show instructions
    alert('Deployment script ready!\n\nCopy the PHP code below and save it as deploy.php in /var/www/html/\n\nThen access: https://10.10.11.39:8443/deploy.php');
    
    console.log('Deployment PHP script:');
    console.log(deployScript);
    
    // Copy to clipboard if possible
    if (navigator.clipboard) {
        navigator.clipboard.writeText(deployScript).then(() => {
            console.log('✓ Script copied to clipboard!');
        });
    }
})();

