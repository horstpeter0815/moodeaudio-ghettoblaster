# DEPLOYMENT VIA BROWSER - FINAL SOLUTION

## The Problem
- SSH doesn't work (password issue)
- Can't upload files directly via browser
- Need to deploy files from `/boot/moode_deploy/` to `/var/www/html/`

## The Solution: One Simple Step

Since I can't create files directly on the server, here's what needs to happen:

### Option 1: Modify Existing mock-backend.php (EASIEST)

1. Open: https://10.10.11.39:8443/mock-backend.php
2. If there's an "Edit" button or file manager, click it
3. Add this code at the beginning (after `$cmd = $_POST['cmd'] ?? '';`):

```php
// ADD THIS CODE:
if ($cmd === 'deploy_files') {
    $deploy_dir = '/boot/moode_deploy';
    $web_root = '/var/www/html';
    $results = [];
    
    if (file_exists("$web_root/index.html")) {
        @unlink("$web_root/index.html") && $results[] = "✓ Deleted index.html";
    }
    
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
// END OF CODE TO ADD
```

4. Save the file
5. Open browser console (F12) and run:
```javascript
fetch('/mock-backend.php', {
    method: 'POST',
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: 'cmd=deploy_files'
})
.then(r => r.json())
.then(data => {
    console.log('Deployment results:', data);
    alert('Deployment complete!\\n\\n' + data.results.join('\\n'));
    window.location.href = '/';
});
```

### Option 2: Create New File (if file manager available)

1. Create new file: `deploy.php` in `/var/www/html/`
2. Copy content from `deploy-execute.php` (on SD card: `/boot/moode_deploy/deploy-execute.php`)
3. Access: https://10.10.11.39:8443/deploy.php

### Option 3: Terminal Command (if terminal available)

```bash
sudo cp /boot/moode_deploy/deploy-now.php /var/www/html/ && sudo chmod 644 /var/www/html/deploy-now.php
```

Then access: https://10.10.11.39:8443/deploy-now.php

