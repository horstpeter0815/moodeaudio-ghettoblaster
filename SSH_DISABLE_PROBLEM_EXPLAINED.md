# SSH Disable Problem - Complete Explanation

## The Problem

**Just like worker.php was overwriting config.txt, build scripts are DISABLING SSH during the build process.**

Even if we enable SSH in our custom scripts, these build scripts run AFTER and disable it again.

---

## What's Happening

### Step-by-Step Process:

1. **Build starts** → `build.sh` runs
2. **build.sh sets:** `ENABLE_SSH="${ENABLE_SSH:-0}"` (defaults to 0 = disabled)
3. **stage2/01-sys-tweaks/01-run.sh runs** → Checks `ENABLE_SSH`
4. **Since ENABLE_SSH = "0"** → Runs `systemctl disable ssh`
5. **SSH gets disabled**
6. **hifiberry-tools.mk runs** → Removes SSH symlink (double disable)
7. **Our custom script runs** → Tries to enable SSH
8. **But SSH is already disabled** → Our enable might not work
9. **After boot** → SSH stays disabled

---

## The Three Culprits

### Culprit #1: build.sh (Sets Default to Disabled)

**File:** `imgbuild/pi-gen-64/build.sh`  
**Line:** 213  
**Code:**
```bash
export ENABLE_SSH="${ENABLE_SSH:-0}"
```

**Problem:** Defaults to "0" (disabled) if not set

**Fix:** Change default to "1" (enabled)

---

### Culprit #2: stage2/01-sys-tweaks/01-run.sh (Disables SSH)

**File:** `imgbuild/pi-gen-64/stage2/01-sys-tweaks/01-run.sh`  
**Lines:** 15-21  
**Code:**
```bash
on_chroot << EOF
if [ "${ENABLE_SSH}" == "1" ]; then
	systemctl enable ssh
else
	systemctl disable ssh  # ← THIS DISABLES SSH!
fi
EOF
```

**Problem:** If `ENABLE_SSH != "1"`, it disables SSH

**Fix:** Always enable SSH, or check if it's already enabled

---

### Culprit #3: hifiberry-tools.mk (Removes SSH Symlink)

**File:** `hifiberry-os/buildroot/package/hifiberry-tools/hifiberry-tools.mk`  
**Lines:** 77-80  
**Code:**
```makefile
# disable sshd by default
if [ -f $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/sshd.service ]; then \
   rm $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/sshd.service; \
fi
```

**Problem:** Removes SSH service symlink, disabling SSH

**Fix:** Don't remove it, or enable it instead

---

## The Fix

We need to patch all three files to ensure SSH stays enabled.

---

## Why This Happens

**Standard Raspberry Pi OS behavior:**
- SSH is disabled by default for security
- Users enable it manually via `/boot/ssh` flag
- Build scripts follow this pattern

**Our custom build needs:**
- SSH enabled by default
- SSH stays enabled
- No manual intervention needed

**Conflict:** Build scripts disable SSH, we need it enabled.

---

## Solution Strategy

1. **Set ENABLE_SSH=1** in build.sh (default to enabled)
2. **Always enable SSH** in stage2/01-sys-tweaks/01-run.sh (don't disable)
3. **Don't remove SSH symlink** in hifiberry-tools.mk (or enable it)

This ensures SSH is enabled at every step and can't be disabled.

