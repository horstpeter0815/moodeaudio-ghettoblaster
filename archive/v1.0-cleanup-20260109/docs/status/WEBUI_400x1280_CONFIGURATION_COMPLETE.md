# WebUI 400x1280 Configuration - Complete

**Date:** 2025-12-25  
**Status:** ✅ Configuration applied, needs verification after X11 fix

---

## Changes Applied

### 1. WebUI Window Size Updated
**File:** `/home/andre/.xinitrc`

**Change:**
```bash
# Before:
--window-size="$SCREEN_RES" \

# After:
--window-size="400,1280" \
```

**Effect:** Chromium WebUI will start with window size **400x1280** (portrait orientation)

### 2. LocalDisplay Service User Fixed
**File:** `/usr/lib/systemd/system/localdisplay.service`

**Change:**
```ini
# Before:
User=pi

# After:
User=andre
```

**Effect:** Service now runs as correct user

---

## Current Status

### ✅ Completed:
- WebUI window size set to 400x1280 in `.xinitrc`
- LocalDisplay service user changed from `pi` to `andre`
- Framebuffer is 400x1280 (matches WebUI requirement)

### ⚠️ Issue:
- X11 fails to start with error: `drmSetMaster failed: Device or resource busy`
- This prevents Chromium from starting
- Need to resolve DRM device conflict

---

## Next Steps

### To Verify WebUI 400x1280:

1. **Fix X11 DRM conflict:**
   ```bash
   # Find what's using DRM
   lsof /dev/dri/card0
   # Kill conflicting processes
   sudo pkill -9 Xorg
   # Restart service
   sudo systemctl restart localdisplay.service
   ```

2. **After X11 starts, verify:**
   - Chromium window size should be 400x1280
   - WebUI should display in portrait mode

---

## Configuration Summary

- **WebUI Window:** 400x1280 (portrait)
- **Framebuffer:** 400x1280 (portrait)
- **Display Hardware:** 1280x400 (landscape, but rotated at boot)

---

**Status:** Configuration applied - Waiting for X11 to start to verify










