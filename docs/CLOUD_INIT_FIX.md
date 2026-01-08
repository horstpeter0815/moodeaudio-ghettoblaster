# Cloud-Init Boot Delay Fix

## Problem
The Raspberry Pi stops at "Cloud Init Service" during boot, causing delays or boot failures. This happens because cloud-init is enabled by default in some Raspberry Pi OS images, but it's not needed for our custom moOde build.

## Root Cause
- Cloud-init runs on first boot to configure the system
- It waits for network configuration or other services
- It can block the boot process if it's waiting for something that never comes
- Our custom build doesn't need cloud-init

## Solution

### 1. Systemd Service
**File:** `moode-source/lib/systemd/system/06-disable-cloud-init.service`

This service:
- Runs early in boot (before cloud-init services)
- Stops all cloud-init services
- Disables cloud-init services
- Masks cloud-init services (prevents them from starting)
- Modifies cloud-init config if it exists

**Service Details:**
- Runs after `local-fs.target`
- Runs before `multi-user.target`
- Runs before all cloud-init services
- Type: `oneshot` with `RemainAfterExit=yes`

### 2. Build Script
**File:** `imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_00-run-chroot.sh`

The build script now:
- Disables cloud-init during image build
- Masks cloud-init services
- Ensures cloud-init won't run on first boot

### 3. Manual Fix (if needed)
If cloud-init is already blocking boot:

```bash
# On the Pi (via SSH or console)
sudo systemctl stop cloud-init
sudo systemctl disable cloud-init
sudo systemctl mask cloud-init
sudo systemctl mask cloud-init-local
sudo systemctl mask cloud-config
sudo systemctl mask cloud-final
```

## Files Modified

1. `moode-source/lib/systemd/system/06-disable-cloud-init.service` - New service
2. `imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_00-run-chroot.sh` - Added cloud-init disable

## Verification

After applying fix, verify:
1. ✅ Service exists: `ls /lib/systemd/system/06-disable-cloud-init.service`
2. ✅ Service enabled: `systemctl is-enabled 06-disable-cloud-init.service`
3. ✅ Cloud-init masked: `systemctl status cloud-init` (should show "masked")
4. ✅ Boot completes without delay

## Testing

1. Boot Pi with fix applied
2. Check boot time - should not stop at cloud-init
3. Verify services: `systemctl status cloud-init` (should be masked)
4. Check logs: `journalctl -u 06-disable-cloud-init.service`

## Status

✅ Fix implemented
✅ Service created
✅ Build script updated
✅ Ready for deployment

