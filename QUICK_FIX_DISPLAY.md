# Quick Fix: Black Screen on Bose Radio Display

## Problem
Display shows only backlight (black screen) but no content from Chromium.

## Quick Fix (One Command)

```bash
./deploy-display-fixes.sh moode
```

Or if your moOde host has a different name/IP:

```bash
./deploy-display-fixes.sh 192.168.1.100
```

## Manual Quick Fix

If you prefer to do it manually:

```bash
# 1. Deploy and run the fix
scp custom-components/scripts/fix-display-black.sh moode:/tmp/
ssh moode 'sudo mv /tmp/fix-display-black.sh /usr/local/bin/ && sudo chmod +x /usr/local/bin/fix-display-black.sh'
ssh moode 'sudo /usr/local/bin/fix-display-black.sh'

# 2. Check results
ssh moode 'sudo cat /var/log/fix-display-black.log'
ssh moode 'systemctl status localdisplay.service'
```

## What the Fix Does

1. **Stops** the localdisplay service
2. **Kills** all Chromium processes (cleans up hung processes)
3. **Verifies** all required scripts exist
4. **Restarts** the service
5. **Verifies** Chromium is running

## If That Doesn't Work

Try the force restart:

```bash
scp custom-components/scripts/force-restart-chromium.sh moode:/tmp/
ssh moode 'sudo mv /tmp/force-restart-chromium.sh /usr/local/bin/ && sudo chmod +x /usr/local/bin/force-restart-chromium.sh'
ssh moode 'sudo /usr/local/bin/force-restart-chromium.sh'
```

## Diagnostic Scripts Available

- `diagnose-display-black.sh` - Full diagnosis
- `fix-display-black.sh` - Standard fix
- `force-restart-chromium.sh` - Aggressive restart
- `fix-display-toggle.sh` - Fix display toggle issue

All scripts log to `/var/log/` with descriptive names.

