# SSH Disable Fix - Applied

## Problem Summary

**Just like worker.php was overwriting config.txt, build scripts were DISABLING SSH during the build process.**

Even if we enabled SSH in our custom scripts, these build scripts ran AFTER and disabled it again.

---

## Fixes Applied

### Fix #1: build.sh - Enable SSH by Default

**File:** `imgbuild/pi-gen-64/build.sh`  
**Line:** 213  
**Changed from:**
```bash
export ENABLE_SSH="${ENABLE_SSH:-0}"  # Defaults to disabled
```

**Changed to:**
```bash
export ENABLE_SSH="${ENABLE_SSH:-1}"  # Defaults to enabled
```

**Result:** SSH is now enabled by default unless explicitly disabled.

---

### Fix #2: stage2/01-sys-tweaks/01-run.sh - Always Enable SSH

**File:** `imgbuild/pi-gen-64/stage2/01-sys-tweaks/01-run.sh`  
**Lines:** 15-21  
**Changed from:**
```bash
on_chroot << EOF
if [ "${ENABLE_SSH}" == "1" ]; then
	systemctl enable ssh
else
	systemctl disable ssh  # ← This was disabling SSH!
fi
EOF
```

**Changed to:**
```bash
on_chroot << EOF
# GHETTOBLASTER FIX: Always enable SSH (don't disable)
if [ "${ENABLE_SSH}" == "1" ]; then
	systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true
else
	# Even if ENABLE_SSH != "1", still enable SSH (Ghettoblaster requirement)
	systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true
fi
EOF
```

**Result:** SSH is always enabled, never disabled.

---

### Fix #3: hifiberry-tools.mk - Enable SSH Instead of Disabling

**File:** `hifiberry-os/buildroot/package/hifiberry-tools/hifiberry-tools.mk`  
**Lines:** 77-80  
**Changed from:**
```makefile
# disable sshd by default
if [ -f $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/sshd.service ]; then \
   rm $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/sshd.service; \
fi
```

**Changed to:**
```makefile
# GHETTOBLASTER FIX: Enable SSH instead of disabling it
# Original code removed SSH symlink, disabling SSH. Now we ensure SSH is enabled.
if [ ! -f $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/sshd.service ] && [ -f $(TARGET_DIR)/lib/systemd/system/sshd.service ]; then \
   mkdir -p $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants; \
   ln -sf /lib/systemd/system/sshd.service $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/sshd.service; \
fi
if [ ! -f $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/ssh.service ] && [ -f $(TARGET_DIR)/lib/systemd/system/ssh.service ]; then \
   mkdir -p $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants; \
   ln -sf /lib/systemd/system/ssh.service $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/ssh.service; \
fi
```

**Result:** SSH symlink is created instead of removed.

---

## How It Works Now

### New Build Process:

1. **build.sh sets:** `ENABLE_SSH="${ENABLE_SSH:-1}"` (defaults to 1 = enabled) ✅
2. **stage2/01-sys-tweaks/01-run.sh runs** → Always enables SSH ✅
3. **hifiberry-tools.mk runs** → Creates SSH symlink (enables SSH) ✅
4. **Our custom script runs** → SSH is already enabled ✅
5. **After boot** → SSH stays enabled ✅

---

## Verification

After these fixes, SSH should:
- ✅ Be enabled by default in builds
- ✅ Stay enabled during build process
- ✅ Not be disabled by build scripts
- ✅ Work after boot

---

## Testing

To verify the fix works:

1. **Build a new image** with these fixes
2. **Check during build:** SSH should be enabled at each step
3. **Boot the image:** SSH should be enabled and working
4. **Test SSH connection:** Should work without manual intervention

---

## Prevention

**These fixes ensure SSH stays enabled:**
- Default value is "enabled" (not "disabled")
- Build scripts enable SSH (don't disable)
- SSH symlink is created (not removed)

**Just like worker.php patch prevents config.txt overwrite, these fixes prevent SSH from being disabled.**

---

## Status

✅ **All three fixes applied**  
✅ **SSH will be enabled by default**  
✅ **SSH won't be disabled during build**  
⏳ **Needs testing on next build**

---

**Date:** 2024-12-29  
**Applied by:** AI Assistant  
**Status:** Fixes applied, ready for testing

