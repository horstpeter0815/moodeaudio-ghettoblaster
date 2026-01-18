# Boot Fixes Summary

## Total Fixes Implemented: **5 Critical Fixes**

### 1. **D-Bus Circular Dependency Fix**
**File:** `/Volumes/rootfs/etc/systemd/system/dbus.service.d/fix-circular-dependency.conf`

**Problem:** Circular dependency: `dbus.service` → `basic.target` → `sockets.target` → `dbus.socket` → `dbus.service`

**Solution:** 
- Make `dbus.service` start BEFORE `basic.target` (not after)
- Use `DefaultDependencies=no` to prevent auto-dependencies
- Clear all `After=` dependencies and set explicit ones

**Status:** ✅ Implemented

---

### 2. **Basic Target Override Fix**
**File:** `/Volumes/rootfs/etc/systemd/system/basic.target.d/fix-no-dbus-wait.conf`

**Problem:** `basic.target` was waiting for `paths.target`, `slices.target`, and `tmp.mount` which were blocking boot

**Solution:**
- Changed from `After=paths.target slices.target tmp.mount` to `Wants=paths.target slices.target tmp.mount`
- Only wait for `sysinit.target` and `sockets.target` in `After=`
- This allows `basic.target` to complete without waiting for optional targets

**Status:** ✅ Implemented

---

### 3. **SSH/Nginx Startup Service**
**File:** `/Volumes/rootfs/etc/systemd/system/start-ssh-nginx.service`

**Problem:** `ssh.service` and `nginx.service` are configured with `WantedBy=multi-user.target`, but we're booting to `basic.target`, so they never start

**Solution:**
- Created custom service that starts `ssh.service` and `nginx.service` after `basic.target`
- Service type: `oneshot` with `RemainAfterExit=yes`
- Configured with `WantedBy=basic.target`

**Status:** ✅ Implemented

---

### 4. **Service Symlink (Enable SSH/Nginx)**
**File:** `/Volumes/rootfs/etc/systemd/system/basic.target.wants/start-ssh-nginx.service`

**Problem:** `[Install]` sections in override files are ignored by systemd, so we need a symlink to enable the service

**Solution:**
- Created symlink: `basic.target.wants/start-ssh-nginx.service` → `/etc/systemd/system/start-ssh-nginx.service`
- This enables the service when `basic.target` is reached

**Status:** ✅ Implemented

---

### 5. **Default Target Configuration**
**File:** `/Volumes/rootfs/etc/systemd/system/default.target`

**Problem:** System was trying to boot to `multi-user.target` (full system) instead of minimal `basic.target`

**Solution:**
- Created symlink: `default.target` → `/lib/systemd/system/basic.target`
- This sets the default boot target to `basic.target` (minimal boot)

**Status:** ✅ Implemented

---

## Additional Fixes (Previously Implemented)

### 6. **Masked Services (Disabled)**
- `sound.target` → masked (audio disabled)
- `alsa-state.service` → masked
- `alsa-restore.service` → masked
- `avahi-daemon.service` → masked
- `avahi-daemon.socket` → masked
- `systemd-hostnamed.service` → masked
- `systemd-hostnamed.socket` → masked

**Status:** ✅ Implemented

---

## Boot Sequence (Expected)

1. **sysinit.target** → completes
2. **sockets.target** → completes (D-Bus socket listening)
3. **dbus.service** → starts (before basic.target, breaks cycle)
4. **network.target** → completes (network up)
5. **basic.target** → completes (no longer blocked)
6. **start-ssh-nginx.service** → starts (triggered by symlink)
7. **ssh.service** → starts
8. **nginx.service** → starts
9. **System accessible** ✅

---

## Files Created/Modified

### Created:
- `/Volumes/rootfs/etc/systemd/system/start-ssh-nginx.service`
- `/Volumes/rootfs/etc/systemd/system/dbus.service.d/fix-circular-dependency.conf`
- `/Volumes/rootfs/etc/systemd/system/basic.target.d/fix-no-dbus-wait.conf`
- `/Volumes/rootfs/etc/systemd/system/basic.target.wants/start-ssh-nginx.service` (symlink)
- `/Volumes/rootfs/etc/systemd/system/default.target` (symlink)

### Masked (symlinked to /dev/null):
- `/Volumes/rootfs/etc/systemd/system/sound.target`
- `/Volumes/rootfs/etc/systemd/system/alsa-state.service`
- `/Volumes/rootfs/etc/systemd/system/alsa-restore.service`
- `/Volumes/rootfs/etc/systemd/system/avahi-daemon.service`
- `/Volumes/rootfs/etc/systemd/system/avahi-daemon.socket`
- `/Volumes/rootfs/etc/systemd/system/systemd-hostnamed.service`
- `/Volumes/rootfs/etc/systemd/system/systemd-hostnamed.socket`

---

## Verification Commands

After boot, verify with:
```bash
# Check if basic.target was reached
systemctl status basic.target

# Check if SSH is running
systemctl status ssh.service

# Check if nginx is running
systemctl status nginx.service

# Check if start-ssh-nginx.service ran
systemctl status start-ssh-nginx.service
```

---

## Notes

- All fixes are applied to the SD card filesystem (`/Volumes/rootfs`)
- These fixes enable a minimal boot to `basic.target` with SSH and web interface accessible
- Audio services are completely disabled (masked)
- Multi-user functionality is disabled (booting to basic.target only)
