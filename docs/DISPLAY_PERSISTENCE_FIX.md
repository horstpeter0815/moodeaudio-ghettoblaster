# Display Persistence Fix

## Problem

Display configuration changes are not persistent across reboots. Settings in `config.txt` and `cmdline.txt` get reset or overwritten by moOde's `worker.php` daemon, which runs early in the boot process and can modify boot configuration files.

## Root Cause

1. **moOde's `worker.php`** runs early in boot and checks/modifies `config.txt` using the `updBootConfigTxt()` function
2. **`config.txt.overwrite`** template in `/usr/share/moode-player/boot/firmware/` can be used to restore default config
3. **Display settings** (hdmi_cvt, hdmi_mode, etc.) are NOT managed by `updBootConfigTxt()`, so they can be lost
4. **cmdline.txt** can be modified by moOde for DSI displays, but HDMI settings may not persist

## Solution

Created a **persistent display configuration service** that:

1. **Runs AFTER moOde's worker.php** finishes (waits for worker.pid to complete)
2. **Restores display settings** in `config.txt`:
   - `hdmi_cvt=400 1280 60 6 0 0 0` (Waveshare 7.9" HDMI display)
   - `hdmi_mode=87`
   - `hdmi_group=2`
   - `hdmi_force_mode=1`
   - `disable_overscan=1`
3. **Restores cmdline.txt** settings:
   - `video=HDMI-A-1:400x1280M@60,rotate=90`
   - Fixes any `HDMI-A-2` → `HDMI-A-1` mistakes
4. **Ensures config.txt.overwrite** has correct settings for future restores

## Files Created

### Script
- **`scripts/display/persist-display-config.sh`**
  - Main script that restores display settings
  - Waits for moOde worker.php to finish
  - Verifies and fixes both `config.txt` and `cmdline.txt`
  - Logs to `/var/log/persist-display-config.log`

### Service
- **`moode-source/lib/systemd/system/persist-display-config.service`**
  - Systemd service that runs the script on boot
  - Runs AFTER `moode-player.service` (which starts worker.php)
  - Runs BEFORE `graphical.target` (display system)

### Template
- **`moode-source/boot/firmware/config.txt.overwrite`**
  - Template file with correct display settings
  - Copied to `/usr/share/moode-player/boot/firmware/` during installation
  - Used by moOde if it needs to restore config.txt

## Installation

### For New SD Card (After Flash)

The fix is automatically installed by `INSTALL_FIXES_AFTER_FLASH.sh`:

```bash
cd ~/moodeaudio-cursor
sudo ./INSTALL_FIXES_AFTER_FLASH.sh
```

This will:
1. Copy `persist-display-config.sh` to `/usr/local/bin/`
2. Copy `persist-display-config.service` to `/lib/systemd/system/`
3. Enable the service
4. Update `config.txt.overwrite` with correct settings
5. Fix `cmdline.txt` with correct HDMI settings

### For Running System

Run the script manually to apply the fix immediately:

```bash
# On the Pi (via SSH)
sudo /usr/local/bin/persist-display-config.sh

# Or if not installed yet, copy from project:
cd ~/moodeaudio-cursor
scp scripts/display/persist-display-config.sh andre@192.168.10.2:/tmp/
ssh andre@192.168.10.2
sudo cp /tmp/persist-display-config.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/persist-display-config.sh
sudo /usr/local/bin/persist-display-config.sh

# Install service
sudo cp moode-source/lib/systemd/system/persist-display-config.service /lib/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable persist-display-config.service
sudo systemctl start persist-display-config.service
```

## How It Works

1. **Service starts** after `moode-player.service` (which runs worker.php)
2. **Script waits** for worker.php to finish (checks `/run/worker.pid`)
3. **Script restores** display settings in `config.txt`:
   - Ensures `[pi5]` section has correct display settings
   - Adds settings to `[all]` section if needed
   - Fixes any incorrect values
4. **Script restores** `cmdline.txt`:
   - Ensures `video=HDMI-A-1:400x1280M@60,rotate=90` is present
   - Removes any conflicting video parameters
   - Fixes `HDMI-A-2` → `HDMI-A-1` mistakes
5. **Script verifies** settings and logs results

## Verification

Check the log to see what was fixed:

```bash
sudo journalctl -u persist-display-config.service
# or
cat /var/log/persist-display-config.log
```

Verify settings manually:

```bash
# Check config.txt
grep "hdmi_cvt=400 1280 60 6 0 0 0" /boot/firmware/config.txt

# Check cmdline.txt
grep "video=HDMI-A-1:400x1280M@60,rotate=90" /boot/firmware/cmdline.txt
```

## Troubleshooting

### Display still not working after reboot

1. Check if service ran:
   ```bash
   sudo systemctl status persist-display-config.service
   ```

2. Check logs:
   ```bash
   sudo journalctl -u persist-display-config.service -n 50
   ```

3. Run script manually:
   ```bash
   sudo /usr/local/bin/persist-display-config.sh
   ```

4. Verify settings:
   ```bash
   cat /boot/firmware/config.txt | grep hdmi_cvt
   cat /boot/firmware/cmdline.txt | grep video=
   ```

### Service not starting

1. Check if service file exists:
   ```bash
   ls -l /lib/systemd/system/persist-display-config.service
   ```

2. Check if script exists and is executable:
   ```bash
   ls -l /usr/local/bin/persist-display-config.sh
   ```

3. Reload systemd:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable persist-display-config.service
   ```

## Related Files

- `moode-source/www/daemon/worker.php` - moOde worker that can modify config.txt
- `moode-source/www/inc/common.php` - Contains `updBootConfigTxt()` function
- `moode-source/boot/firmware/config.txt.overwrite` - Template for config.txt restore
- `scripts/display/persist-display-config.sh` - Main fix script
- `moode-source/lib/systemd/system/persist-display-config.service` - Systemd service

## Notes

- The service runs **AFTER** moOde's modifications, ensuring our settings persist
- The script is **idempotent** - safe to run multiple times
- Settings are **verified** after restoration
- All changes are **logged** for debugging
