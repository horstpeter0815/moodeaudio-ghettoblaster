# Display Black Screen Fix

## Problem

The display shows only a black screen with backlight, but no content from Chromium. The display service may be running, but Chromium is not displaying the web interface.

## Symptoms

- Display backlight is ON
- Screen is completely black
- `localdisplay.service` may be active
- Chromium process may or may not be running
- No error messages visible

## Diagnosis

First, run the diagnostic script to identify the issue:

```bash
# Deploy diagnostic script
scp custom-components/scripts/diagnose-display-black.sh moode:/tmp/
ssh moode 'sudo mv /tmp/diagnose-display-black.sh /usr/local/bin/ && sudo chmod +x /usr/local/bin/diagnose-display-black.sh'

# Run diagnosis
ssh moode 'sudo /usr/local/bin/diagnose-display-black.sh'

# View diagnostic log
ssh moode 'sudo cat /var/log/diagnose-display-black.log'
```

This will check:
1. Service status
2. Chromium processes
3. X server status
4. `.xinitrc` configuration
5. Service file configuration
6. Display URL setting
7. Recent error logs

## Fix

Run the fix script to restart Chromium properly:

```bash
# Deploy fix script
scp custom-components/scripts/fix-display-black.sh moode:/tmp/
ssh moode 'sudo mv /tmp/fix-display-black.sh /usr/local/bin/ && sudo chmod +x /usr/local/bin/fix-display-black.sh'

# Run fix
ssh moode 'sudo /usr/local/bin/fix-display-black.sh'

# View fix log
ssh moode 'sudo cat /var/log/fix-display-black.log'
```

The fix script will:
1. Stop the localdisplay service
2. Kill any hanging Chromium processes
3. Verify/repair `.xinitrc` configuration
4. Ensure service file exists and is enabled
5. Restart the service
6. Verify Chromium starts correctly

## Manual Fix Steps

If scripts don't work, try manual steps:

```bash
# 1. Stop service and kill Chromium
ssh moode 'sudo systemctl stop localdisplay.service'
ssh moode 'sudo pkill -9 chromium chromium-browser'

# 2. Check .xinitrc
ssh moode 'cat ~/.xinitrc'
# Should contain: --app="http://localhost" (or your configured URL)

# 3. Check service status
ssh moode 'systemctl status localdisplay.service'

# 4. Restart service
ssh moode 'sudo systemctl daemon-reload'
ssh moode 'sudo systemctl start localdisplay.service'

# 5. Check Chromium is running
ssh moode 'ps aux | grep chromium'

# 6. Check service logs
ssh moode 'sudo journalctl -u localdisplay.service -n 50'
```

## Common Causes

1. **Chromium crashed** - Process died but service still reports active
2. **Wrong URL in .xinitrc** - URL changed but .xinitrc not updated
3. **X server not ready** - X server didn't start before Chromium
4. **Permissions issue** - User can't access display
5. **Service file missing** - Service file was deleted or corrupted

## Prevention

The enhanced `startLocalDisplay()` function in `peripheral.php` now:
- Ensures service file exists before starting
- Enables service if needed
- Runs `daemon-reload` before starting

This should prevent most issues, but if Chromium crashes, the fix script can recover.

