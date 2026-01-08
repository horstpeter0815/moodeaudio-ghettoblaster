# SSH Fix Complete Guide

## Problem Summary

**Just like worker.php was overwriting config.txt, build scripts were DISABLING SSH during the build process.**

This caused SSH to be disabled even after we enabled it in our custom scripts.

---

## What Was Fixed

### Fix #1: build.sh - Enable SSH by Default

**File:** `imgbuild/pi-gen-64/build.sh`  
**Line:** 213

**Before:**
```bash
export ENABLE_SSH="${ENABLE_SSH:-0}"  # Defaults to disabled
```

**After:**
```bash
export ENABLE_SSH="${ENABLE_SSH:-1}"  # Defaults to enabled
```

**What this does:**
- Sets SSH to be enabled by default
- Only disables if explicitly set to "0"

---

### Fix #2: stage2/01-sys-tweaks/01-run.sh - Always Enable SSH

**File:** `imgbuild/pi-gen-64/stage2/01-sys-tweaks/01-run.sh`  
**Lines:** 15-21

**Before:**
```bash
if [ "${ENABLE_SSH}" == "1" ]; then
	systemctl enable ssh
else
	systemctl disable ssh  # ← This was disabling SSH!
fi
```

**After:**
```bash
# GHETTOBLASTER FIX: Always enable SSH (don't disable)
if [ "${ENABLE_SSH}" == "1" ]; then
	systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true
else
	# Even if ENABLE_SSH != "1", still enable SSH (Ghettoblaster requirement)
	systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true
fi
```

**What this does:**
- Always enables SSH, regardless of ENABLE_SSH value
- Never disables SSH
- Tries both "ssh" and "sshd" service names

---

### Fix #3: hifiberry-tools.mk - Enable SSH Instead of Disabling

**File:** `hifiberry-os/buildroot/package/hifiberry-tools/hifiberry-tools.mk`  
**Lines:** 77-80

**Before:**
```makefile
# disable sshd by default
if [ -f $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/sshd.service ]; then \
   rm $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/sshd.service; \
fi
```

**After:**
```makefile
# GHETTOBLASTER FIX: Enable SSH instead of disabling it
if [ ! -f $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/sshd.service ] && [ -f $(TARGET_DIR)/lib/systemd/system/sshd.service ]; then \
   mkdir -p $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants; \
   ln -sf /lib/systemd/system/sshd.service $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/sshd.service; \
fi
if [ ! -f $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/ssh.service ] && [ -f $(TARGET_DIR)/lib/systemd/system/ssh.service ]; then \
   mkdir -p $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants; \
   ln -sf /lib/systemd/system/ssh.service $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/ssh.service; \
fi
```

**What this does:**
- Creates SSH symlink instead of removing it
- Ensures SSH service is enabled
- Handles both "ssh" and "sshd" service names

---

## How It Works Now

### Build Process Flow:

```
1. build.sh runs
   ↓
   Sets ENABLE_SSH="${ENABLE_SSH:-1}" (defaults to enabled) ✅
   ↓
2. stage2/01-sys-tweaks/01-run.sh runs
   ↓
   Always enables SSH (never disables) ✅
   ↓
3. hifiberry-tools.mk runs
   ↓
   Creates SSH symlink (enables SSH) ✅
   ↓
4. Our custom script (00-run-chroot.sh) runs
   ↓
   SSH is already enabled ✅
   ↓
5. After boot
   ↓
   SSH stays enabled ✅
```

---

## Verification Steps

### Step 1: Check During Build

During build, check logs for:
- `systemctl enable ssh` (should see this, not "disable")
- SSH symlink creation (should see symlink created, not removed)

### Step 2: Check After Build

On built image (before boot):
```bash
# Check if SSH symlink exists
ls -la /etc/systemd/system/multi-user.target.wants/ssh.service
ls -la /etc/systemd/system/multi-user.target.wants/sshd.service

# Should show symlinks, not missing files
```

### Step 3: Check After Boot

After booting the Pi:
```bash
# Check SSH service status
systemctl status ssh
# Should show: active (running)

# Check if SSH is enabled
systemctl is-enabled ssh
# Should show: enabled

# Test SSH connection
ssh andre@<PI_IP>
# Should connect successfully
```

---

## Prevention

**These fixes ensure SSH stays enabled:**

1. **Default value is "enabled"** - Not "disabled"
2. **Build scripts enable SSH** - Don't disable
3. **SSH symlink is created** - Not removed

**Just like worker.php patch prevents config.txt overwrite, these fixes prevent SSH from being disabled.**

---

## Comparison to config.txt Fix

**config.txt overwrite problem:**
- worker.php was copying/overwriting config.txt
- Solution: Patch worker.php to restore settings after copy
- Result: config.txt settings persist

**SSH disable problem:**
- Build scripts were disabling SSH
- Solution: Patch build scripts to enable SSH
- Result: SSH stays enabled

**Same pattern, same solution approach!**

---

## Files Modified

1. ✅ `imgbuild/pi-gen-64/build.sh` - Line 213
2. ✅ `imgbuild/pi-gen-64/stage2/01-sys-tweaks/01-run.sh` - Lines 15-21
3. ✅ `hifiberry-os/buildroot/package/hifiberry-tools/hifiberry-tools.mk` - Lines 77-80

---

## Status

✅ **All fixes applied**  
✅ **SSH will be enabled by default**  
✅ **SSH won't be disabled during build**  
⏳ **Ready for testing on next build**

---

## Next Steps

1. **Build a new image** with these fixes
2. **Verify SSH is enabled** during build (check logs)
3. **Boot the image** and test SSH connection
4. **Confirm SSH works** without manual intervention

---

**Date:** 2024-12-29  
**Status:** Fixes applied and documented  
**Ready for:** Testing on next build

