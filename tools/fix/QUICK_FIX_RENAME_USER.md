# Quick Fix: Boot Hangs on "Rename User" Screen

## Problem
Pi boot hangs on "change user" / "rename user" screen.

## Solution
Disable the services causing the hang.

## Method 1: Fix on SD Card (Recommended)

1. **Power off the Pi** (if it's hung)
2. **Remove SD card** and insert into Mac
3. **Run fix script:**
   ```bash
   cd ~/moodeaudio-cursor
   ./tools/fix/disable-rename-user-on-sd.sh
   ```
4. **Eject SD card** and boot Pi

## Method 2: Fix via SSH (if Pi eventually boots)

If the Pi eventually times out and boots:

```bash
# Copy fix script
scp tools/fix/fix-boot-rename-user-and-peppy.sh andre@192.168.2.3:/tmp/

# SSH and run
ssh andre@192.168.2.3
sudo /tmp/fix-boot-rename-user-and-peppy.sh
sudo reboot
```

## What Gets Fixed

1. **05-remove-pi-user.service** - Disabled (causes rename user screen)
2. **fix-user-id.service** - Disabled (already masked, but ensures it stays off)
3. **arm_boost=1** - Enabled in config.txt
4. **PeppyMeter** - Configured to start AFTER boot completes

## Services That Cause the Hang

- `05-remove-pi-user.service` - Tries to remove/rename pi user during boot
- `fix-user-id.service` - Tries to fix user UID during boot

Both services are now disabled with overrides that make them no-ops.
