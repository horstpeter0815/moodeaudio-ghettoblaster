# PeppyMeter "Mixed Up" Fix - Boot-Level Rotation

**Date:** 2025-12-25  
**Issue:** PeppyMeter is "completely mixed up" when landscape mode is set  
**Root Cause:** xrandr rotation changes coordinate system, PeppyMeter coordinates become wrong

---

## Problem Analysis

### Current State (BROKEN):
1. **Framebuffer:** Reports `400x1280` (portrait - hardware EDID)
2. **X11:** Rotated to `1280x400` via `xrandr --rotate left`
3. **PeppyMeter:** Uses coordinates `(50, 150)` and `(680, 150)` assuming normal orientation
4. **Result:** Coordinates are wrong because xrandr rotation changes coordinate system

### Why It's Mixed Up:
- `xrandr --rotate left` rotates the **coordinate system**, not just the image
- Original `(0,0)` = top-left of `400x1280`
- After rotation: Coordinate system is rotated 90° counter-clockwise
- PeppyMeter's `(50, 150)` and `(680, 150)` are now in the wrong place

---

## Solution Applied

### Fix 1: Boot-Level Rotation (config.txt)
**File:** `/boot/firmware/config.txt`

**Added:**
```ini
[pi5]
display_rotate=1  # Rotate framebuffer 90° at boot level

[all]
hdmi_group=2
hdmi_mode=87
hdmi_cvt=1280 400 60 6 0 0 0  # Custom 1280x400 mode
```

**Effect:**
- Framebuffer will be `1280x400` from boot (not `400x1280`)
- No X11 rotation needed
- Coordinate system stays normal
- PeppyMeter coordinates will be correct

### Fix 2: Updated fix-display-orientation Script
**File:** `/usr/local/bin/fix-display-orientation-before-peppy.sh`

**Changes:**
- Checks framebuffer dimensions first
- If framebuffer is already `1280x400`, skips X11 rotation
- Only applies X11 rotation if framebuffer is still `400x1280`

### Fix 3: PeppyMeter Configuration
**File:** `/opt/peppymeter/1280x400/meters.txt`

**Current Config:**
```ini
[linear-left-right]
meter.type = linear
channels = 2
left.x = 50
left.y = 150
right.x = 680
right.y = 150
position.regular = 10
position.overload = 3
step.width.regular = 45
step.width.overload = 50
```

**Coordinates are correct for landscape 1280x400:**
- Left meter: X=50, width=600px (ends at 650px)
- Right meter: X=680, width=600px (ends at 1280px)
- Both at Y=150 (vertical center of 400px height)

---

## Verification After Reboot

After rebooting the Pi, verify:

1. **Framebuffer:**
   ```bash
   fbset -s | grep geometry
   # Should show: 1280x400 (not 400x1280)
   ```

2. **X11 Display:**
   ```bash
   DISPLAY=:0 xdpyinfo | grep dimensions
   # Should show: 1280x400
   ```

3. **xrandr:**
   ```bash
   DISPLAY=:0 xrandr | grep HDMI-1
   # Should show: rotation: normal (not left/right)
   ```

4. **PeppyMeter:**
   - Meters should be correctly positioned
   - Left meter on left, right meter on right
   - Both at correct vertical position

---

## Expected Results

**Before Fix:**
- ❌ Framebuffer: `400x1280` (portrait)
- ❌ X11: `1280x400` (rotated via xrandr)
- ❌ Coordinate system: Rotated
- ❌ PeppyMeter: Mixed up (wrong coordinates)

**After Fix:**
- ✅ Framebuffer: `1280x400` (landscape, rotated at boot)
- ✅ X11: `1280x400` (no xrandr rotation needed)
- ✅ Coordinate system: Normal
- ✅ PeppyMeter: Correct (coordinates match display)

---

## Files Modified

1. `/boot/firmware/config.txt` - Added `display_rotate=1` and `hdmi_mode=87`
2. `/usr/local/bin/fix-display-orientation-before-peppy.sh` - Updated to detect boot-level rotation
3. `/opt/peppymeter/1280x400/meters.txt` - Already correct (using bar images)

---

## Next Steps

1. **REBOOT the Pi** to apply boot-level rotation
2. **Verify** framebuffer is `1280x400` after reboot
3. **Check** PeppyMeter displays correctly
4. **Test** that meters are in correct positions

---

**Status:** ✅ Fix applied - REBOOT REQUIRED to test










