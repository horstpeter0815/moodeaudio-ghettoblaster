#!/usr/bin/env python3
"""
Deploy Display Fix via Web Interface
This script creates a PHP file that can be uploaded to moOde and executed via browser
to fix the display configuration files directly on the Pi.
"""

import os

# Read the corrected config.txt content
config_content = """# Ghettoblaster Display Settings
disable_overscan=1
# display_rotate=2 in [pi5] section above
hdmi_group=2
hdmi_mode=87
hdmi_cvt=400 1280 60 6 0 0 0
# Force landscape orientation
hdmi_force_mode=1
"""

# Read the corrected cmdline.txt content
cmdline_content = """console=serial0,115200 console=tty1 root=PARTUUID=CHANGE_ME rootfstype=ext4 fsck.repair=yes rootwait cfg80211.ieee80211_regdom=DE video=HDMI-A-1:400x1280M@60,rotate=90
"""

# Create PHP script that will fix the display config
php_script = f"""<?php
// Display Fix Script - Execute via browser: https://10.10.11.39:8443/fix-display.php
header('Content-Type: text/html; charset=utf-8');
?>
<!DOCTYPE html>
<html>
<head>
    <title>Display Fix</title>
    <style>
        body {{ font-family: monospace; padding: 20px; background: #1e1e1e; color: #d4d4d4; }}
        .success {{ color: #4ec9b0; }}
        .error {{ color: #f48771; }}
        .info {{ color: #dcdcaa; }}
        pre {{ background: #2d2d2d; padding: 10px; border-radius: 4px; }}
    </style>
</head>
<body>
    <h1>Display Configuration Fix</h1>
    <?php
    $results = [];
    $errors = [];
    
    // 1. Fix config.txt
    $config_path = '/boot/firmware/config.txt';
    if (file_exists($config_path)) {{
        // Read current config
        $config = file_get_contents($config_path);
        
        // Replace hdmi_cvt line
        $config = preg_replace('/hdmi_cvt=\\d+ \\d+ \\d+ \\d+ \\d+ \\d+ \\d+/', 'hdmi_cvt=400 1280 60 6 0 0 0', $config);
        
        // Ensure disable_overscan=1 is present
        if (strpos($config, 'disable_overscan=1') === false) {{
            // Add after [all] section
            $config = preg_replace('/(\\[all\\][^\\n]*\\n)/', '$1disable_overscan=1\\n', $config, 1);
        }}
        
        // Backup original
        $backup_path = $config_path . '.backup_' . date('Ymd_His');
        if (copy($config_path, $backup_path)) {{
            $results[] = "Backed up config.txt to " . basename($backup_path);
        }}
        
        // Write fixed config
        if (file_put_contents($config_path, $config)) {{
            $results[] = "✓ Fixed config.txt (hdmi_cvt=400 1280 60 6 0 0 0)";
        }} else {{
            $errors[] = "Failed to write config.txt";
        }}
    }} else {{
        $errors[] = "config.txt not found at $config_path";
    }}
    
    // 2. Fix cmdline.txt
    $cmdline_path = '/boot/firmware/cmdline.txt';
    if (file_exists($cmdline_path)) {{
        // Read current cmdline
        $cmdline = file_get_contents($cmdline_path);
        $cmdline = trim($cmdline);
        
        // Check if video parameter exists
        if (strpos($cmdline, 'video=') === false) {{
            // Add video parameter
            $cmdline .= ' video=HDMI-A-1:400x1280M@60,rotate=90';
        }} else {{
            // Replace existing video parameter
            $cmdline = preg_replace('/video=[^ ]+/', 'video=HDMI-A-1:400x1280M@60,rotate=90', $cmdline);
        }}
        
        // Backup original
        $backup_path = $cmdline_path . '.backup_' . date('Ymd_His');
        if (copy($cmdline_path, $backup_path)) {{
            $results[] = "Backed up cmdline.txt to " . basename($backup_path);
        }}
        
        // Write fixed cmdline
        if (file_put_contents($cmdline_path, $cmdline)) {{
            $results[] = "✓ Fixed cmdline.txt (added video=HDMI-A-1:400x1280M@60,rotate=90)";
        }} else {{
            $errors[] = "Failed to write cmdline.txt";
        }}
    }} else {{
        $errors[] = "cmdline.txt not found at $cmdline_path";
    }}
    
    // Display results
    echo "<h2>Results:</h2>";
    if (!empty($results)) {{
        echo "<div class='success'><ul>";
        foreach ($results as $result) {{
            echo "<li>$result</li>";
        }}
        echo "</ul></div>";
    }}
    
    if (!empty($errors)) {{
        echo "<div class='error'><h3>Errors:</h3><ul>";
        foreach ($errors as $error) {{
            echo "<li>$error</li>";
        }}
        echo "</ul></div>";
    }}
    
    if (empty($errors)) {{
        echo "<div class='info'><h3>Next Steps:</h3>";
        echo "<ol>";
        echo "<li>Reboot the Raspberry Pi</li>";
        echo "<li>The display should now show correctly without white edges</li>";
        echo "</ol></div>";
    }}
    
    // Show current config for verification
    echo "<h2>Current config.txt (hdmi_cvt line):</h2>";
    if (file_exists($config_path)) {{
        $config = file_get_contents($config_path);
        preg_match('/hdmi_cvt=[^\\n]+/', $config, $matches);
        if (!empty($matches)) {{
            echo "<pre>" . htmlspecialchars($matches[0]) . "</pre>";
        }}
    }}
    
    echo "<h2>Current cmdline.txt (video parameter):</h2>";
    if (file_exists($cmdline_path)) {{
        $cmdline = file_get_contents($cmdline_path);
        preg_match('/video=[^ ]+/', $cmdline, $matches);
        if (!empty($matches)) {{
            echo "<pre>" . htmlspecialchars($matches[0]) . "</pre>";
        }} else {{
            echo "<pre class='error'>No video parameter found</pre>";
        }}
    }}
    ?>
</body>
</html>
"""

# Write PHP script
with open('fix-display.php', 'w') as f:
    f.write(php_script)

print("✓ Created fix-display.php")
print("\nNext steps:")
print("1. Copy fix-display.php to /var/www/html/ on the moOde system")
print("2. Open https://10.10.11.39:8443/fix-display.php in browser")
print("3. The script will fix config.txt and cmdline.txt automatically")
print("4. Reboot the Pi")






