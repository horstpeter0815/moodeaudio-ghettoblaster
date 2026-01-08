# Display Toggle Fix

## Problem

When toggling the local display OFF in the moOde web UI, the display may not turn back ON when toggled ON again. This is caused by:

1. The `localdisplay.service` file may be missing
2. The service may not be enabled
3. The service may fail to start due to dependency issues
4. The database state (`local_display=1`) and service state may be out of sync

## Solution

### Script: `fix-display-toggle.sh`

This script diagnoses and fixes display toggle issues by:

1. **Checking database state** - Verifies `local_display` setting in `cfg_system`
2. **Checking service status** - Verifies if `localdisplay.service` is active/enabled
3. **Ensuring service file exists** - Creates it via `auto-fix-display.sh` if missing
4. **Synchronizing state** - Starts/stops service to match database setting
5. **Logging** - All actions logged to `/var/log/fix-display-toggle.log`

### Enhanced `startLocalDisplay()` Function

The `peripheral.php` file now includes improved logic in `startLocalDisplay()`:

- Checks if service file exists before starting
- Automatically enables the service if needed
- Runs `daemon-reload` to ensure systemd recognizes changes
- Falls back to `fix-display-toggle.sh` if start fails

## Usage

### Deploy to Running System

```bash
# Copy script to moOde system
scp custom-components/scripts/fix-display-toggle.sh moode:/tmp/

# Install script
ssh moode 'sudo mv /tmp/fix-display-toggle.sh /usr/local/bin/ && sudo chmod +x /usr/local/bin/fix-display-toggle.sh'

# Run fix script
ssh moode 'sudo /usr/local/bin/fix-display-toggle.sh'

# Check logs
ssh moode 'sudo tail -50 /var/log/fix-display-toggle.log'
```

### Manual Fix (Quick)

If you just need to start the display:

```bash
ssh moode 'sudo systemctl enable localdisplay.service && sudo systemctl daemon-reload && sudo systemctl start localdisplay.service'
```

Or check the database and service state:

```bash
# Check database setting
ssh moode 'moodeutl -q "SELECT value FROM cfg_system WHERE param=\"local_display\""'

# Check service status
ssh moode 'systemctl status localdisplay.service'

# Check if service file exists
ssh moode 'ls -la /lib/systemd/system/localdisplay.service'
```

## Integration

The enhanced `startLocalDisplay()` function in `moode-source/www/inc/peripheral.php` will automatically use the fix script if the service fails to start, providing better reliability.

For new builds, the script is automatically included in `custom-components/scripts/` and will be copied to `/usr/local/bin/` during the build process.

